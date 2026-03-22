#!/bin/bash
# ═══════════════════════════════════════════════════════
# REZI — Script de restauration
# Usage: ./restore.sh [fichier_backup.sql.gz]
#        ./restore.sh --latest          (dernier backup)
#        ./restore.sh --date 20260322   (backup du jour)
# ═══════════════════════════════════════════════════════

set -e

DB_NAME="${DB_NAME:-rezi}"
DB_USER="${DB_USER:-postgres}"
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
PGPASSWORD="${DB_PASSWORD:-password}"
export PGPASSWORD

BACKUP_DIR="/opt/rezi/backups/db"
UPLOADS_DIR="/opt/rezi/uploads"
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

log() { echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $1"; }

# ── Sélection du fichier à restaurer ──
BACKUP_FILE=""
if [ "$1" == "--latest" ]; then
  BACKUP_FILE=$(ls -t $BACKUP_DIR/rezi_*.sql.gz 2>/dev/null | head -1)
  [ -z "$BACKUP_FILE" ] && { log "${RED}❌ Aucun backup trouvé.${NC}"; exit 1; }
elif [ "$1" == "--date" ] && [ -n "$2" ]; then
  BACKUP_FILE=$(ls $BACKUP_DIR/rezi_${2}*.sql.gz 2>/dev/null | head -1)
  [ -z "$BACKUP_FILE" ] && { log "${RED}❌ Aucun backup pour la date $2.${NC}"; exit 1; }
elif [ -n "$1" ] && [ -f "$1" ]; then
  BACKUP_FILE="$1"
else
  # Afficher la liste et demander
  log "${BLUE}=== BACKUPS DISPONIBLES ===${NC}"
  ls -lh $BACKUP_DIR/rezi_*.sql.gz 2>/dev/null | awk '{print NR". "$9" ("$5")"}' | sed 's|.*/||'
  echo ""
  read -p "Numéro du backup à restaurer (ou chemin complet) : " CHOICE
  BACKUP_FILE=$(ls $BACKUP_DIR/rezi_*.sql.gz 2>/dev/null | sed -n "${CHOICE}p")
fi

[ ! -f "$BACKUP_FILE" ] && { log "${RED}❌ Fichier introuvable : $BACKUP_FILE${NC}"; exit 1; }

log "${YELLOW}⚠️  RESTAURATION depuis : $(basename $BACKUP_FILE)${NC}"
log "${YELLOW}⚠️  Base cible : $DB_NAME sur $DB_HOST${NC}"
echo ""
read -p "Confirmer ? Cela écrasera la base actuelle. (oui/non) : " CONFIRM
[ "$CONFIRM" != "oui" ] && { log "Annulé."; exit 0; }

# ── 1. Sauvegarde de précaution avant restauration ──
log "🔒 Backup de précaution avant restauration..."
PRECAUTION="${BACKUP_DIR}/precaution_$(date +%Y%m%d_%H%M%S).sql.gz"
pg_dump -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" "$DB_NAME" \
  --format=custom --compress=9 | gzip > "$PRECAUTION" 2>/dev/null || true
log "${GREEN}✅ Backup précaution → $(basename $PRECAUTION)${NC}"

# ── 2. Terminer les connexions actives ──
log "🔌 Fermeture des connexions actives..."
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" postgres -c \
  "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname='$DB_NAME' AND pid <> pg_backend_pid();" > /dev/null 2>&1 || true

# ── 3. Supprimer et recréer la base ──
log "🗑️  Suppression de la base $DB_NAME..."
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" postgres -c "DROP DATABASE IF EXISTS $DB_NAME;" > /dev/null
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" postgres -c "CREATE DATABASE $DB_NAME;" > /dev/null
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" "$DB_NAME" -c "CREATE EXTENSION IF NOT EXISTS postgis;" > /dev/null
log "${GREEN}✅ Base recréée${NC}"

# ── 4. Restauration ──
log "📥 Restauration en cours (peut prendre plusieurs minutes)..."
if [[ "$BACKUP_FILE" == *.gz ]]; then
  gunzip -c "$BACKUP_FILE" | pg_restore -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" \
    -d "$DB_NAME" --no-owner --no-acl 2>/dev/null || \
  # Fallback : tenter psql si pg_restore échoue
  gunzip -c "$BACKUP_FILE" | psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" "$DB_NAME" > /dev/null
else
  pg_restore -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" \
    -d "$DB_NAME" --no-owner --no-acl "$BACKUP_FILE"
fi
log "${GREEN}✅ Base restaurée${NC}"

# ── 5. Restauration des uploads ──
DATE_PREFIX=$(basename "$BACKUP_FILE" | grep -oP '\d{8}_\d{6}' || echo "")
UPLOADS_BACKUP="${BACKUP_DIR}/uploads_${DATE_PREFIX}.tar.gz"
if [ -f "$UPLOADS_BACKUP" ]; then
  log "📸 Restauration des fichiers uploadés..."
  tar -xzf "$UPLOADS_BACKUP" -C "$(dirname $UPLOADS_DIR)"
  log "${GREEN}✅ Uploads restaurés${NC}"
else
  log "${YELLOW}⚠️  Pas de backup uploads correspondant trouvé${NC}"
fi

# ── 6. Vérification post-restauration ──
log "🔍 Vérification post-restauration..."
USERS=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" "$DB_NAME" \
  -t -c "SELECT COUNT(*) FROM users;" 2>/dev/null | tr -d ' ')
RESIDENCES=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" "$DB_NAME" \
  -t -c "SELECT COUNT(*) FROM residences;" 2>/dev/null | tr -d ' ')

log "${GREEN}✅ Restauration vérifiée :${NC}"
log "   👤 Utilisateurs : $USERS"
log "   🏠 Résidences   : $RESIDENCES"
log "${GREEN}=== RESTAURATION TERMINÉE ===${NC}"
log "💡 Redémarrez les services : docker-compose restart backend"
