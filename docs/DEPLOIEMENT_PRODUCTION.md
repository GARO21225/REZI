# 🚀 REZI — Déploiement Production (VPS Ubuntu 22.04)

## Prérequis
- VPS Ubuntu 22.04 (min 2 vCPU / 4 GB RAM)
- Domaine : `rezi.ci` (ou sous-domaine)
- Accès SSH root

---

## Étape 1 — Préparer le serveur

```bash
ssh root@IP_SERVEUR

# Mise à jour
apt update && apt upgrade -y

# Docker + Docker Compose
curl -fsSL https://get.docker.com | sh
apt install -y docker-compose-plugin git nginx certbot python3-certbot-nginx ufw

# Pare-feu
ufw allow 22 && ufw allow 80 && ufw allow 443 && ufw enable

# Créer l'utilisateur app
adduser rezi --disabled-password --gecos ""
usermod -aG docker rezi
su - rezi
```

---

## Étape 2 — Cloner le projet

```bash
# En tant qu'utilisateur rezi
git clone https://github.com/VOTRE_USERNAME/rezi.git ~/app
cd ~/app

# Configurer les variables d'environnement
cp backend/.env.example backend/.env
nano backend/.env
```

Remplir `.env` :
```env
DATABASE_URL=postgresql://rezi:MOT_DE_PASSE_DB@db:5432/rezi
SECRET_KEY=$(openssl rand -hex 32)
ENV=production
FIREBASE_CREDENTIALS_PATH=/app/serviceAccountKey.json
ORANGE_MONEY_TOKEN=votre_token
MTN_MOMO_SUBSCRIPTION_KEY=votre_clé
WAVE_API_KEY=votre_clé
CALLBACK_BASE_URL=https://rezi.ci
BACKUP_REMOTE=user@backup-server:/backups/rezi
```

---

## Étape 3 — SSL Let's Encrypt

```bash
# En tant que root
certbot --nginx -d rezi.ci -d www.rezi.ci \
  --non-interactive --agree-tos -m contact@rezi.ci

# Vérifier le renouvellement auto
systemctl status certbot.timer
```

---

## Étape 4 — Nginx final

```bash
cat > /etc/nginx/sites-available/rezi << 'NGINX'
server {
    listen 80;
    server_name rezi.ci www.rezi.ci;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    server_name rezi.ci www.rezi.ci;

    ssl_certificate     /etc/letsencrypt/live/rezi.ci/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/rezi.ci/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512;
    ssl_prefer_server_ciphers on;

    # Sécurité
    add_header Strict-Transport-Security "max-age=31536000" always;
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;

    # Frontend
    location / {
        root /home/rezi/app/frontend;
        index index.html;
        try_files $uri $uri/ /index.html;
        gzip on;
        gzip_types text/html text/css application/javascript application/json;
        expires 1h;
        add_header Cache-Control "public, must-revalidate";
    }

    # Service Worker — pas de cache
    location = /sw.js {
        root /home/rezi/app/frontend;
        add_header Cache-Control "no-store, no-cache, must-revalidate";
    }

    # API Backend
    location /api/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 60s;
        client_max_body_size 20M;
    }

    # WebSocket messagerie
    location /api/messages/ws/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_read_timeout 86400s;
    }
}
NGINX

ln -s /etc/nginx/sites-available/rezi /etc/nginx/sites-enabled/
nginx -t && systemctl reload nginx
```

---

## Étape 5 — Lancer l'application

```bash
# En tant qu'utilisateur rezi
cd ~/app
docker compose up -d --build

# Vérifier les logs
docker compose logs -f backend
docker compose logs -f db

# Vérifier que l'API répond
curl https://rezi.ci/api/health
```

---

## Étape 6 — Configurer le backup automatique

```bash
chmod +x backup/backup.sh
# Ajouter au cron (backup quotidien à 3h du matin)
crontab -e
# Ajouter :
0 3 * * * /home/rezi/app/backup/backup.sh >> /home/rezi/backup.log 2>&1
```

---

## Étape 7 — Monitoring

```bash
# Surveiller l'état des containers
docker compose ps

# Voir les ressources
docker stats

# Redémarrage auto si le serveur redémarre
docker compose down && docker compose up -d
# Activer le restart automatique (déjà dans docker-compose.yml : restart: unless-stopped)
```

---

## Mise à jour sans downtime

```bash
cd ~/app
git pull origin main
docker compose build backend
docker compose up -d --no-deps backend
# Les connexions actives migrent automatiquement
```

---

## Variables GitHub Actions (CI/CD automatique)

Dans GitHub → Settings → Secrets → Actions :

| Secret | Valeur |
|--------|--------|
| `VPS_HOST` | IP de votre serveur |
| `VPS_USER` | `rezi` |
| `VPS_KEY` | Clé SSH privée |
| `VPS_PORT` | `22` |
| `DOCKER_USERNAME` | Votre username Docker Hub |
| `DOCKER_PASSWORD` | Token Docker Hub |

Après ça, chaque `git push main` déclenche automatiquement le déploiement via `.github/workflows/deploy.yml`.

