#!/bin/bash
# ═══════════════════════════════════════════════════════
# REZI — Script de mise à jour sans interruption
# Usage: ./update.sh [--branch main] [--skip-backup]
# ═══════════════════════════════════════════════════════

set -e

BRANCH="${BRANCH:-main}"
SKIP_BACKUP=false
DEPLOY_DIR="/opt/rezi"
BACKUP_BEFORE_UPDATE=true
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; RED='\033[0;31m'; NC='\033[0m'

for arg in "$@"; do
  case $arg in
    --branch=*) BRANCH="${arg#*=}" ;;
    --skip-backup) SKIP_BACKUP=true ;;
  esac
done

log() { echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $1"; }
step() { echo -e "\n${BLUE}━━━ $1 ━━━${NC}"; }

step "🚀 REZI UPDATE — branche : $BRANCH"
log "Répertoire : $DEPLOY_DIR"

# ── 1. Backup automatique avant toute mise à jour ──
if [ "$SKIP_BACKUP" = false ]; then
  step "💾 Sauvegarde préventive"
  bash "$DEPLOY_DIR/backup/backup.sh" && \
    log "${GREEN}✅ Backup OK${NC}" || \
    { log "${RED}❌ Backup échoué. Annulation.${NC}"; exit 1; }
fi

# ── 2. Récupérer les dernières modifications ──
step "📥 Récupération des sources"
cd "$DEPLOY_DIR"
git fetch origin "$BRANCH"
CURRENT=$(git rev-parse HEAD)
LATEST=$(git rev-parse "origin/$BRANCH")

if [ "$CURRENT" = "$LATEST" ]; then
  log "${YELLOW}⚠️  Déjà à jour. Rien à faire.${NC}"
  exit 0
fi

log "Version actuelle : ${CURRENT:0:8}"
log "Nouvelle version : ${LATEST:0:8}"
git log --oneline "$CURRENT..$LATEST"

read -p "Confirmer la mise à jour ? (oui/non) : " CONFIRM
[ "$CONFIRM" != "oui" ] && { log "Annulé."; exit 0; }

git pull origin "$BRANCH"
log "${GREEN}✅ Sources mises à jour${NC}"

# ── 3. Vérifier les nouvelles migrations ──
step "🗄️  Migrations base de données"
if [ -f "backend/alembic.ini" ]; then
  cd backend
  source .env 2>/dev/null || true
  alembic upgrade head && log "${GREEN}✅ Migrations OK${NC}" || \
    { log "${RED}❌ Migration échouée. Restauration...${NC}"; bash "$DEPLOY_DIR/backup/restore.sh" --latest; exit 1; }
  cd "$DEPLOY_DIR"
else
  log "${YELLOW}⚠️  Pas de migrations Alembic détectées${NC}"
fi

# ── 4. Rebuild Docker images ──
step "🐳 Rebuild des images Docker"
docker-compose build --no-cache backend && \
  log "${GREEN}✅ Image backend reconstruite${NC}"

# ── 5. Déploiement sans interruption (rolling update) ──
step "🔄 Déploiement rolling (zéro downtime)"

# Démarrer le nouveau backend en parallèle
log "Démarrage du nouveau backend..."
docker-compose up -d --no-deps backend

# Attendre que le nouveau backend réponde
MAX_WAIT=60
WAIT=0
log "Attente du nouveau backend (max ${MAX_WAIT}s)..."
until curl -sf http://localhost:8000/health > /dev/null 2>&1; do
  sleep 2; WAIT=$((WAIT+2))
  [ $WAIT -ge $MAX_WAIT ] && { log "${RED}❌ Timeout. Rollback...${NC}"; bash "$0" --rollback; exit 1; }
done
log "${GREEN}✅ Nouveau backend opérationnel (${WAIT}s)${NC}"

# Frontend (copie statique — aucune interruption)
log "Déploiement frontend..."
cp -r frontend/* /var/www/rezi/ 2>/dev/null || true
log "${GREEN}✅ Frontend déployé${NC}"

# Recharger nginx sans couper les connexions
nginx -s reload 2>/dev/null || docker-compose exec frontend nginx -s reload 2>/dev/null || true
log "${GREEN}✅ Nginx rechargé${NC}"

# ── 6. Tests post-déploiement ──
step "🧪 Tests post-déploiement"
HEALTH=$(curl -sf http://localhost:8000/health | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('status','?'))" 2>/dev/null)
if [ "$HEALTH" = "ok" ]; then
  log "${GREEN}✅ Health check OK${NC}"
else
  log "${RED}❌ Health check échoué. Rollback automatique...${NC}"
  git checkout "$CURRENT"
  docker-compose up -d --no-deps backend
  log "${YELLOW}Revenu à la version ${CURRENT:0:8}${NC}"
  exit 1
fi

# ── 7. Résumé ──
step "✅ MISE À JOUR TERMINÉE"
log "Ancienne version : ${CURRENT:0:8}"
log "Nouvelle version : ${LATEST:0:8}"
log "Date             : $(date '+%d/%m/%Y %H:%M')"

# Tag Git
git tag -a "deploy-$(date +%Y%m%d-%H%M)" -m "Déploiement $(date)" 2>/dev/null || true

# Notification
[ -n "$ALERT_WEBHOOK" ] && curl -s -X POST "$ALERT_WEBHOOK" \
  -H 'Content-type: application/json' \
  -d "{\"text\":\"🚀 REZI mis à jour : ${CURRENT:0:8} → ${LATEST:0:8}\"}"

log "💡 Logs : docker-compose logs -f backend"
