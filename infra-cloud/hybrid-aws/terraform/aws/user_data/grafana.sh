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

# Enable + Start Grafana
systemctl daemon-reload
systemctl enable grafana-server
systemctl start grafana-server