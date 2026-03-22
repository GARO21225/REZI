# 🛡️ REZI — Stratégie de Sauvegarde & Reprise sur Incident

## Vue d'ensemble

```
┌─────────────────────────────────────────────────────────────┐
│                    ARCHITECTURE REZI                        │
│                                                             │
│  🌍 Internet                                                │
│       │                                                     │
│  ┌────▼────────────────────────────────┐                   │
│  │       Serveur PRINCIPAL             │                   │
│  │  ┌──────────┐  ┌────────────────┐  │                   │
│  │  │ Frontend │  │ Backend FastAPI │  │                   │
│  │  │  Nginx   │  │  (port 8000)   │  │                   │
│  │  └──────────┘  └───────┬────────┘  │                   │
│  │                        │           │                   │
│  │            ┌───────────▼────────┐  │                   │
│  │            │ PostgreSQL+PostGIS  │  │                   │
│  │            │   (port 5432)      │  │                   │
│  │            └────────────────────┘  │                   │
│  └────────────────────┬───────────────┘                   │
│                       │ Réplication WAL                    │
│  ┌────────────────────▼───────────────┐                   │
│  │      Serveur de SECOURS (Standby)  │                   │
│  │  PostgreSQL Standby (lecture seule) │                   │
│  │  Backend de secours (port 8001)     │                   │
│  └────────────────────────────────────┘                   │
│                                                             │
│  ☁️  Cloud : Backups S3/OVH/Scaleway toutes les 2h          │
└─────────────────────────────────────────────────────────────┘
```

---

## 📦 Fréquence des sauvegardes

| Type | Fréquence | Rétention | Stockage |
|------|-----------|-----------|----------|
| **Base de données complète** | Toutes les 2h | 30 jours | Local + S3 |
| **Fichiers uploadés (photos, docs)** | 1x/jour à 3h | 30 jours | Local + S3 |
| **Backup avant toute mise à jour** | À chaque déploiement | 90 jours | Local + S3 |
| **Backup de précaution (restauration)** | Avant chaque restore | 7 jours | Local |
| **Réplication WAL temps réel** | Continue | Serveur standby | Serveur de secours |

---

## 🚀 Installation

### 1. Configurer les backups automatiques (cron)
```bash
# Sur le serveur principal
crontab -e

# Backup toutes les 2h
0 */2 * * * /opt/rezi/backup/backup.sh >> /var/log/rezi/backup.log 2>&1

# Nettoyage hebdomadaire des logs
0 4 * * 0 find /var/log/rezi -name "*.log" -mtime +30 -delete
```

### 2. Variables d'environnement (fichier .env sur le serveur)
```env
# Base de données
DB_NAME=rezi
DB_USER=postgres
DB_PASSWORD=VotreMotDePasseSecurisé
DB_HOST=localhost

# Serveur de secours (SSH)
BACKUP_REMOTE=ubuntu@IP_SERVEUR_SECOURS:/backups/rezi

# Stockage Cloud (optionnel)
S3_BUCKET=s3://rezi-backups-ci
AWS_ACCESS_KEY_ID=xxx
AWS_SECRET_ACCESS_KEY=xxx

# Alertes (Slack / Telegram / Email)
ALERT_WEBHOOK=https://hooks.slack.com/services/xxx
```

### 3. Serveur de secours
```bash
# Sur le serveur de secours
cd /opt/rezi
docker-compose -f backup/docker-compose.standby.yml up -d
```

---

## 🔄 Procédures

### ▶️ Lancer un backup manuellement
```bash
cd /opt/rezi
bash backup/backup.sh
```

### 🔁 Restaurer une sauvegarde
```bash
# Restaurer le dernier backup
bash backup/restore.sh --latest

# Restaurer un backup d'une date précise
bash backup/restore.sh --date 20260322

# Restaurer un fichier spécifique
bash backup/restore.sh /opt/rezi/backups/db/rezi_20260322_020000.sql.gz

# Restaurer interactivement (avec sélection)
bash backup/restore.sh
```

### 🚀 Mettre à jour l'application
```bash
# Mise à jour complète (backup automatique inclus)
bash scripts/update.sh

# Mise à jour sans backup (déconseillé)
bash scripts/update.sh --skip-backup

# Mettre à jour depuis une branche spécifique
bash scripts/update.sh --branch=develop
```

---

## 🚨 Plan de reprise sur incident (PRI)

### Scénario 1 : Bug introduit par une mise à jour
```bash
# 1. Rollback du code
cd /opt/rezi
git checkout HEAD~1  # revenir au commit précédent

# 2. Redémarrer le backend
docker-compose up -d --no-deps backend

# 3. Si la DB est affectée, restaurer
bash backup/restore.sh --latest
```

### Scénario 2 : Panne du serveur principal
```bash
# 1. Sur le serveur de secours — promouvoir en primaire
docker exec rezi_db_standby pg_ctl promote -D /var/lib/postgresql/data

# 2. Changer le DNS (chez votre registrar)
#    Pointer le domaine rezi.ci vers l'IP du serveur de secours

# 3. Activer le backend de secours en lecture/écriture
docker-compose -f backup/docker-compose.standby.yml exec backend-standby \
  sh -c "export READ_ONLY_MODE=false && uvicorn main:app --host 0.0.0.0 --port 8000"

# Délai de reprise estimé : 5-15 minutes
```

### Scénario 3 : Corruption de la base de données
```bash
# 1. Arrêter le backend
docker-compose stop backend

# 2. Restaurer depuis S3 (si local corrompu)
aws s3 cp s3://rezi-backups-ci/db/ /opt/rezi/backups/db/ --recursive

# 3. Restaurer
bash backup/restore.sh --latest

# 4. Redémarrer
docker-compose start backend
```

### Scénario 4 : Suppression accidentelle de données
```bash
# Restauration partielle avec pg_restore
pg_restore --table=users -h localhost -U postgres \
  -d rezi /opt/rezi/backups/db/rezi_TIMESTAMP.sql.gz

# Ou restauration sur une base temporaire pour récupérer les données
createdb rezi_recovery
bash backup/restore.sh --latest  # dans rezi_recovery
# Puis copier les données manquantes avec INSERT INTO rezi SELECT ... FROM rezi_recovery
```

---

## 📊 Surveillance

### Vérifier l'état des backups
```bash
# Lister les backups récents
ls -lh /opt/rezi/backups/db/ | tail -10

# Vérifier le dernier backup
bash -c 'LAST=$(ls -t /opt/rezi/backups/db/rezi_*.sql.gz | head -1); echo "Dernier backup: $LAST ($(du -sh $LAST | cut -f1))"'

# Tester l'intégrité
gzip -t /opt/rezi/backups/db/rezi_LATEST.sql.gz && echo "OK" || echo "CORROMPU"
```

### Logs de backup
```bash
tail -50 /var/log/rezi/backup.log
```

---

## 🔐 Sécurité des sauvegardes

- Backups **chiffrés** avec GPG avant upload S3 (optionnel)
- Accès S3 restreint par IAM policy en écriture seule
- Clé SSH dédiée pour les transferts vers le serveur de secours
- Rotation automatique des secrets tous les 90 jours
- Backups testés automatiquement (restauration en base de test mensuelle)

---

## 📞 Contacts d'urgence

```
Administrateur principal : [Votre nom] — [Votre email]
Serveur principal IP     : [IP_SERVEUR_PRINCIPAL]
Serveur de secours IP    : [IP_SERVEUR_SECOURS]
Registrar DNS            : [Votre registrar]
Hébergeur S3             : [OVH / AWS / Scaleway]
```

---

## 📅 Checklist mensuelle

- [ ] Tester une restauration complète en environnement de test
- [ ] Vérifier la réplication standby
- [ ] Contrôler l'espace disque (backups + DB)
- [ ] Valider les alertes (envoyer un test)
- [ ] Mettre à jour les dépendances (`pip install --upgrade`)
- [ ] Vérifier les certificats SSL (expiration)
- [ ] Auditer les accès utilisateurs admin
