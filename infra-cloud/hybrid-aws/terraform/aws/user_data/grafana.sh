#!/bin/bash
set -ex
exec > /var/log/user-data.log 2>&1

dnf install -y dnf-plugins-core

cat <<'REPO' >/etc/yum.repos.d/grafana.repo
[grafana]
name=Grafana OSS
baseurl=https://rpm.grafana.com
repo_gpgcheck=1
enabled=1
gpgcheck=1
gpgkey=https://rpm.grafana.com/gpg.key
REPO

# Install Grafana
dnf install -y grafana

# Install AMP plugin BEFORE starting service
grafana-cli plugins install grafana-amazonprometheus-datasource

# Create provisioning directory
mkdir -p /etc/grafana/provisioning/datasources

# Write datasource config
cat <<DATASOURCE >/etc/grafana/provisioning/datasources/amp.yaml
${amp_datasource}
DATASOURCE

# Create dashboard directory
mkdir -p /var/lib/grafana/dashboards

# Download from S3
aws s3 cp \
  s3://${dashboard_bucket}/riddlebuddy_amp.json \
  /var/lib/grafana/dashboards/riddlebuddy_amp.json

chown -R grafana:grafana /var/lib/grafana/dashboards

cat <<EOF >/etc/grafana/provisioning/dashboards/dashboard.yaml
apiVersion: 1

providers:
  - name: 'default'
    orgId: 1
    folder: ''
    type: file
    disableDeletion: false
    updateIntervalSeconds: 30
    options:
      path: /var/lib/grafana/dashboards
EOF

# Set Grafana public URL
sed -i 's|;domain = localhost|domain = grafana.nguyentu.online|' /etc/grafana/grafana.ini
sed -i 's|;admin_password = admin|admin_password = ${grafana_admin_password}|' /etc/grafana/grafana.ini
sed -i 's|;root_url = %(protocol)s://%(domain)s:%(http_port)s/|root_url = https://grafana.nguyentu.online/|' /etc/grafana/grafana.ini

# Enable + Start Grafana
systemctl daemon-reload
systemctl enable grafana-server
systemctl start grafana-server

# ─── Nginx reverse proxy + TLS ───────────────────────────────────────────────

dnf install -y nginx python3-pip

# Pull TLS cert and key from SSM Parameter Store
mkdir -p /etc/nginx/tls

aws ssm get-parameter \
  --name "/grafana/tls/cert" \
  --with-decryption \
  --query Parameter.Value \
  --output text > /etc/nginx/tls/cert.pem

aws ssm get-parameter \
  --name "/grafana/tls/key" \
  --with-decryption \
  --query Parameter.Value \
  --output text > /etc/nginx/tls/key.pem

chmod 600 /etc/nginx/tls/key.pem

# Write Nginx config with SSL
cat <<'NGINX_SSL' >/etc/nginx/conf.d/grafana.conf
server {
    listen 80;
    server_name grafana.nguyentu.online;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    server_name grafana.nguyentu.online;

    ssl_certificate     /etc/nginx/tls/cert.pem;
    ssl_certificate_key /etc/nginx/tls/key.pem;
    ssl_protocols       TLSv1.2 TLSv1.3;
    ssl_ciphers         HIGH:!aNULL:!MD5;

    location / {
        proxy_pass         http://localhost:3000;
        proxy_set_header   Host $host;
        proxy_set_header   X-Real-IP $remote_addr;
        proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto $scheme;
    }
}
NGINX_SSL

# Enable + start Nginx
systemctl enable nginx
systemctl start nginx

# ─── Auto-update Route 53 A record with this instance's public IP ────────────
# Amazon Linux 2023 uses IMDSv2 by default which requires a token
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
PUBLIC_IP=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/public-ipv4)
HOSTED_ZONE_ID="${hosted_zone_id}"

aws route53 change-resource-record-sets \
  --hosted-zone-id "$HOSTED_ZONE_ID" \
  --change-batch "{
    \"Changes\": [{
      \"Action\": \"UPSERT\",
      \"ResourceRecordSet\": {
        \"Name\": \"grafana.nguyentu.online\",
        \"Type\": \"A\",
        \"TTL\": 60,
        \"ResourceRecords\": [{\"Value\": \"$PUBLIC_IP\"}]
      }
    }]
  }"
