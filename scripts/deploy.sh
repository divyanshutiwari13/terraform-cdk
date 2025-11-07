#!/bin/bash
exec > /home/ubuntu/deploy.log 2>&1
set -e

DOMAIN="${domain}"
GITHUB_REPO="${github_repo}"
GITHUB_PAT="${github_pat}"
EMAIL="${email}"
APP_DIR="/home/ubuntu/app"

echo "===== Starting deployment for $DOMAIN ====="

# === System updates and installs ===
sudo apt update -y
sudo apt install -y git curl nginx python3-certbot-nginx dnsutils

# === NodeJS install via NVM ===
sudo -u ubuntu bash <<'EOF'
set -e
export NVM_DIR="$HOME/.nvm"
mkdir -p "$NVM_DIR"
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
source "$NVM_DIR/nvm.sh"
nvm install 22
nvm alias default 22
npm install -g pm2
EOF

# === Clone or update GitHub repo ===
if [ ! -d "$APP_DIR" ]; then
  echo "📦 Cloning repository..."
  sudo -u ubuntu git clone https://$${GITHUB_PAT}@github.com/$${GITHUB_REPO}.git $APP_DIR
else
  echo "🔄 Updating repository..."
  cd $APP_DIR && sudo -u ubuntu git pull
fi

cd $APP_DIR
sudo -u ubuntu bash -c "source /home/ubuntu/.nvm/nvm.sh && npm install && npm run build"
sudo -u ubuntu bash -c "source /home/ubuntu/.nvm/nvm.sh && pm2 start npm --name 'app' -- run start"
sudo -u ubuntu bash -c "source /home/ubuntu/.nvm/nvm.sh && pm2 save"

# === Configure Nginx reverse proxy ===
sudo tee /etc/nginx/sites-available/default > /dev/null <<EON
server {
    listen 80;
    server_name $${DOMAIN};

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EON

sudo nginx -t
sudo systemctl restart nginx

# === Wait until domain resolves before SSL ===
INSTANCE_IP=$(curl -s ifconfig.me)
echo "Instance public IP: $INSTANCE_IP"

echo "⏳ Checking DNS for $DOMAIN every 20s (max 10min)..."
MAX_ATTEMPTS=30
for ((i=1; i<=MAX_ATTEMPTS; i++)); do
    DOMAIN_IP=$(dig +short $DOMAIN @8.8.8.8 | tail -n1)
    if [ "$DOMAIN_IP" = "$INSTANCE_IP" ]; then
        echo "✅ Domain $DOMAIN points to instance ($INSTANCE_IP)"
        break
    else
        echo "Attempt $i/$MAX_ATTEMPTS → DNS not ready (current: $DOMAIN_IP)"
        sleep 20
    fi
done

# === Setup SSL with certbot once DNS is ready ===
if [ "$DOMAIN_IP" = "$INSTANCE_IP" ]; then
    echo "🔒 Installing SSL certificate..."
    sudo certbot --nginx --non-interactive --agree-tos -m $${EMAIL} -d $${DOMAIN} || true
    (crontab -l 2>/dev/null; echo "0 3 * * * /usr/bin/certbot renew --quiet") | crontab -
    echo "✅ SSL setup complete for $DOMAIN"
else
    echo "⚠️ Skipping SSL setup — domain did not resolve within 10 minutes."
fi

echo "===== Deployment complete for $DOMAIN ====="
