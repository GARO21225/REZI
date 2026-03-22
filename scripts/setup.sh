#!/bin/bash
# ═══════════════════════════════════════════════════════
# REZI — Script d'installation complète sur un nouveau serveur
# Ubuntu 22.04 / Debian 12
# Usage: curl -sSL https://raw.githubusercontent.com/VOTRE/rezi/main/scripts/setup.sh | bash
# ═══════════════════════════════════════════════════════

set -e
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

log()  { echo -e "[$(date '+%H:%M:%S')] $1"; }
step() { echo -e "\n${BLUE}━━━ $1 ━━━${NC}"; }

step "🚀 Installation REZI"

# ── Prérequis ──
step "📦 Installation des dépendances système"
apt-get update -qq
apt-get install -y -qq \
  docker.io docker-compose git curl wget \
  postgresql-client awscli \
  cron logrotate

systemctl enable docker && systemctl start docker
log "${GREEN}✅ Dépendances installées${NC}"

# ── Dossiers ──
step "📁 Création de l'arborescence"
mkdir -p /opt/rezi/{backups/db,logs}
mkdir -p /var/log/rezi
chmod 755 /opt/rezi/backups
log "${GREEN}✅ Dossiers créés${NC}"

# ── Clone du dépôt ──
step "📥 Clonage du dépôt"
if [ ! -d /opt/rezi/.git ]; then
  git clone https://github.com/VOTRE_USERNAME/rezi.git /opt/rezi
else
  cd /opt/rezi && git pull origin main
fi
log "${GREEN}✅ Sources récupérées${NC}"

# ── Permissions scripts ──
chmod +x /opt/rezi/backup/backup.sh
chmod +x /opt/rezi/backup/restore.sh
chmod +x /opt/rezi/scripts/update.sh

# ── Configuration cron ──
step "⏰ Configuration des tâches cron"
cat > /etc/cron.d/rezi << 'CRON'
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

# Backup toutes les 2 heures
0 */2 * * * root /opt/rezi/backup/backup.sh >> /var/log/rezi/backup.log 2>&1

# Backup quotidien complet à 3h du matin
0 3 * * * root DB_NAME=rezi /opt/rezi/backup/backup.sh >> /var/log/rezi/backup_daily.log 2>&1

# Vérification santé du service toutes les 5 minutes
*/5 * * * * root curl -sf http://localhost:8000/health > /dev/null || systemctl restart rezi 2>/dev/null || true

# Nettoyage logs mensuels
0 5 1 * * root find /var/log/rezi -name "*.log" -mtime +30 -delete
CRON

systemctl restart cron
log "${GREEN}✅ Cron configuré${NC}"

# ── Rotation des logs ──
cat > /etc/logrotate.d/rezi << 'LOGROTATE'
/var/log/rezi/*.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 644 root root
}
LOGROTATE
log "${GREEN}✅ Logrotate configuré${NC}"

# ── Variables d'environnement ──
step "⚙️  Configuration"
if [ ! -f /opt/rezi/backend/.env ]; then
  cp /opt/rezi/backend/.env.example /opt/rezi/backend/.env
  log "${YELLOW}⚠️  Editez /opt/rezi/backend/.env avec vos valeurs${NC}"
fi

# ── Démarrage ──
step "🐳 Démarrage de l'application"
cd /opt/rezi
docker-compose up -d
sleep 10

if curl -sf http://localhost:8000/health > /dev/null; then
  log "${GREEN}✅ REZI démarré avec succès !${NC}"
else
  log "${YELLOW}⚠️  Backend pas encore prêt. Vérifiez : docker-compose logs backend${NC}"
fi

step "✅ INSTALLATION TERMINÉE"
echo ""
echo "  🌍 Frontend  : http://$(hostname -I | awk '{print $1}'):3000"
echo "  ⚙️  Backend   : http://$(hostname -I | awk '{print $1}'):8000"
echo "  📚 API Docs  : http://$(hostname -I | awk '{print $1}'):8000/docs"
echo ""
echo "  📝 Configurer : nano /opt/rezi/backend/.env"
echo "  💾 Backup     : bash /opt/rezi/backup/backup.sh"
echo "  🔄 Mise à jour: bash /opt/rezi/scripts/update.sh"
echo "  📊 Logs       : docker-compose -f /opt/rezi/docker-compose.yml logs -f"
