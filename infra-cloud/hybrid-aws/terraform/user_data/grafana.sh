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
cat <<'DATASOURCE' >/etc/grafana/provisioning/datasources/amp.yaml
${amp_datasource}
DATASOURCE

# Write datasource config
cat <<'DASHBOARD' >/etc/grafana/provisioning/dashboards/riddlebuddy.yaml
${amp_dashboard}
DASHBOARD

# Enable + Start Grafana
systemctl daemon-reload
systemctl enable grafana-server
systemctl start grafana-server