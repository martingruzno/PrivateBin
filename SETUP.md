# 🚀 DigitalOcean Droplet Setup Guide for PrivateBin

This guide walks through setting up a secure, production-ready PrivateBin instance on a DigitalOcean Droplet using Docker, Nginx, SSL, Basic Auth, and firewall hardening.

---

## 🏗️ 1. Provision the Droplet

- Create an Ubuntu 24.04 Droplet on DigitalOcean
- Choose a basic plan (1 vCPU / 1 GB RAM / 25GB Disk is sufficient).
- Set up SSH access or use the root password provided.
- Buy and point a domain (e.g., `privatelinkshare.com`) and configure A records for www. version of the domain to the Droplet’s IP.

---

## 👤 2. Initial Server Setup

SSH into the server:

```bash
ssh root@your_droplet_ip
```

Create a non-root user:

```bash
adduser deployuser
usermod -aG sudo deployuser
```

Switch the logged in user to `deployuser`

---

## 🌐 3. Connect Droplet to GitHub

Generate SSH Key:

```bash
ssh-keygen -t ed25519
```

Add SSH Key to GitHub:

```bash
cat ~/.ssh/id_ed25519.pub
```

Go to GitHub:
- Navigate to Settings → SSH and GPG keys → New SSH key
- Paste the key and save

---

## 📥 4. Create deployment script

Create a script on the server for easier deploys:

```bash
vim ~/redeploy
```

The script:
```bash
#!/bin/bash

cd ~/PrivateBin || exit 1
echo "🌀  Pulling latest changes..."
git pull origin main || exit 1

echo "🧼  Stopping existing containers..."
docker compose down

echo "🚀  Starting updated containers..."
docker compose up -d

echo "✅  PrivateBin redeployed!"
```

Make it executable:

```bash
chmod +x /usr/local/bin/redeploy
```

---

## 🐳 5. Install Dependencies

Install Docker:

```bash
curl -fsSL https://get.docker.com | sudo bash
sudo usermod -aG docker deployuser
```

Install Docker Compose plugin:

```bash
sudo apt install docker-compose-plugin
```

Install Nginx and Certbot:

```bash
sudo apt update
sudo apt install nginx certbot python3-certbot-nginx apache2-utils -y
```

---

## 🔥 6. Configure Firewall

Configure firewall rules:

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow OpenSSH
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
sudo ufw status verbose
```

---

## 📥 7. Clone the Repository

```bash
git clone git@github.com:NeedResolved/PrivateBin.git
```

---

## 🌐 8. Nginx Reverse Proxy

Create Nginx config for your domain:

```bash
sudo vim /etc/nginx/sites-available/privatelinkshare.com
```

Paste the configuration: 

```bash
server {
    server_name privatelinkshare.com www.privatelinkshare.com;

    location / {
        proxy_pass http://localhost:8082;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    listen 443 ssl; # managed by Certbot
    ssl_certificate /etc/letsencrypt/live/privatelinkshare.com/fullchain.pem; # managed by Certbot
    ssl_certificate_key /etc/letsencrypt/live/privatelinkshare.com/privkey.pem; # managed by Certbot
    include /etc/letsencrypt/options-ssl-nginx.conf; # managed by Certbot
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem; # managed by Certbot
}

server {
    if ($host = www.privatelinkshare.com) {
        return 301 https://$host$request_uri;
    } # managed by Certbot


    if ($host = privatelinkshare.com) {
        return 301 https://$host$request_uri;
    } # managed by Certbot


    listen 80;
    server_name privatelinkshare.com www.privatelinkshare.com;
    return 404; # managed by Certbot
}
```

Reload Nginx:

```bash
sudo nginx -t && sudo systemctl reload nginx
```

---

## 🔐 9. Set Up SSL with Certbot

Run:

```bash
sudo certbot --nginx -d privatelinkshare.com -d www.privatelinkshare.com
```

---

## 🔑 10. Enable Basic Auth

Create login credentials:

```bash
sudo htpasswd -c /etc/nginx/.htpasswd admin
```

Reload Nginx:

```bash
sudo nginx -t && sudo systemctl reload nginx
```

Update Nginx config -> Add these lines inside `location /` part of the config file:

```bash
# Basic Auth
auth_basic "PrivateLinkShare Login";
auth_basic_user_file /etc/nginx/.htpasswd;
```

Reload Nginx:

```bash
sudo nginx -t && sudo systemctl reload nginx
```

---

## 🔄 11. Redeploying Updates

Run:

```bash
./redeploy
```
