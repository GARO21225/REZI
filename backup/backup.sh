#!/bin/bash
# ═══════════════════════════════════════════════════════
# REZI — Script de sauvegarde automatique PostgreSQL
# Exécuter via cron : 0 2 * * * /opt/rezi/backup/backup.sh
# ═══════════════════════════════════════════════════════

set -e

# ── Configuration ──
DB_NAME="${DB_NAME:-rezi}"
DB_USER="${DB_USER:-postgres}"
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
PGPASSWORD="${DB_PASSWORD:-password}"
export PGPASSWORD

BACKUP_DIR="/opt/rezi/backups/db"
UPLOADS_DIR="/opt/rezi/uploads"
BACKUP_REMOTE="${BACKUP_REMOTE:-}"          # ex: user@backup-server:/backups/rezi
S3_BUCKET="${S3_BUCKET:-}"                  # ex: s3://rezi-backups
RETENTION_DAYS=30                            # Garder 30 jours
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="${BACKUP_DIR}/rezi_${TIMESTAMP}.sql.gz"
LOG_FILE="/var/log/rezi/backup.log"

# ── Couleurs ──
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

log() { echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"; }

# ── Préparation ──
mkdir -p "$BACKUP_DIR" "$(dirname $LOG_FILE)"
log "${GREEN}=== REZI BACKUP START === ${NC}"

# ── 1. Dump PostgreSQL ──
log "📦 Dump base de données ${DB_NAME}..."
pg_dump -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" "$DB_NAME" \
  --format=custom \
  --compress=9 \
  --no-password \
  | gzip > "$BACKUP_FILE"

SIZE=$(du -sh "$BACKUP_FILE" | cut -f1)
log "${GREEN}✅ Dump OK → ${BACKUP_FILE} (${SIZE})${NC}"

# ── 2. Sauvegarde des uploads (photos, documents) ──
UPLOADS_BACKUP="${BACKUP_DIR}/uploads_${TIMESTAMP}.tar.gz"
if [ -d "$UPLOADS_DIR" ]; then
  log "📸 Compression des fichiers uploadés..."
  tar -czf "$UPLOADS_BACKUP" -C "$(dirname $UPLOADS_DIR)" "$(basename $UPLOADS_DIR)"
  log "${GREEN}✅ Uploads → ${UPLOADS_BACKUP} ($(du -sh $UPLOADS_BACKUP | cut -f1))${NC}"
fi

# ── 3. Envoi vers serveur de secours (SSH/SCP) ──
if [ -n "$BACKUP_REMOTE" ]; then
  log "🔄 Envoi vers serveur de secours ${BACKUP_REMOTE}..."
  scp -q "$BACKUP_FILE" "$BACKUP_REMOTE/" && \
    log "${GREEN}✅ Envoi DB OK${NC}" || \
    log "${RED}❌ Erreur envoi DB${NC}"
  if [ -f "$UPLOADS_BACKUP" ]; then
    scp -q "$UPLOADS_BACKUP" "$BACKUP_REMOTE/" && \
      log "${GREEN}✅ Envoi uploads OK${NC}" || \
      log "${RED}❌ Erreur envoi uploads${NC}"
  fi
fi

# ── 4. Envoi vers S3 / Objet Storage ──
if [ -n "$S3_BUCKET" ]; then
  log "☁️  Upload S3 → ${S3_BUCKET}..."
  aws s3 cp "$BACKUP_FILE" "${S3_BUCKET}/db/" --storage-class STANDARD_IA && \
    log "${GREEN}✅ S3 DB OK${NC}" || log "${RED}❌ Erreur S3 DB${NC}"
  [ -f "$UPLOADS_BACKUP" ] && \
    aws s3 cp "$UPLOADS_BACKUP" "${S3_BUCKET}/uploads/" --storage-class STANDARD_IA
fi

# ── 5. Nettoyage anciens backups (> RETENTION_DAYS) ──
log "🗑️  Nettoyage backups > ${RETENTION_DAYS} jours..."
find "$BACKUP_DIR" -name "rezi_*.sql.gz" -mtime +$RETENTION_DAYS -delete
find "$BACKUP_DIR" -name "uploads_*.tar.gz" -mtime +$RETENTION_DAYS -delete
log "${GREEN}✅ Nettoyage OK${NC}"

# ── 6. Vérification intégrité du backup ──
log "🔍 Vérification intégrité..."
if gzip -t "$BACKUP_FILE" 2>/dev/null; then
  log "${GREEN}✅ Backup intègre${NC}"
else
  log "${RED}❌ Backup corrompu ! Alerte envoyée.${NC}"
  # Envoyer alerte email / Slack
  [ -n "$ALERT_WEBHOOK" ] && curl -s -X POST "$ALERT_WEBHOOK" \
    -H 'Content-type: application/json' \
    -d "{\"text\":\"🚨 REZI BACKUP CORROMPU : ${BACKUP_FILE}\"}"
  exit 1
fi

# ── 7. Rapport de backup ──
TOTAL_BACKUPS=$(ls $BACKUP_DIR/rezi_*.sql.gz 2>/dev/null | wc -l)
TOTAL_SIZE=$(du -sh $BACKUP_DIR 2>/dev/null | cut -f1)
log "📊 Total backups : ${TOTAL_BACKUPS} | Espace utilisé : ${TOTAL_SIZE}"

# Notification succès vers Slack/Webhook
if [ -n "$ALERT_WEBHOOK" ]; then
  curl -s -X POST "$ALERT_WEBHOOK" \
    -H 'Content-type: application/json' \
    -d "{\"text\":\"✅ REZI backup OK — ${TIMESTAMP} — ${SIZE} — ${TOTAL_BACKUPS} backups conservés\"}"
fi

log "${GREEN}=== BACKUP TERMINÉ === ${NC}"
