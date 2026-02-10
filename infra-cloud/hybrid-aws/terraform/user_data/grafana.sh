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

dnf install -y grafana

mkdir -p /etc/grafana/provisioning/datasources

cat <<'DATASOURCE' >/etc/grafana/provisioning/datasources/amp.yaml
__AMP_DATASOURCE__
DATASOURCE

systemctl daemon-reload
systemctl enable grafana-server
systemctl start grafana-server