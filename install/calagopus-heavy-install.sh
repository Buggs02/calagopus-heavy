#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Robby (based on the Calagopus script by Jelcoo)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://calagopus.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

setup_docker

msg_info "Configuring Calagopus Heavy"
APP_DIR="/opt/calagopus-heavy"
mkdir -p "$APP_DIR" /etc/calagopus-wings /var/lib/calagopus-wings /var/log/calagopus-wings
mkdir -p "$APP_DIR"/build/binaries "$APP_DIR"/build/translations "$APP_DIR"/build/extensions "$APP_DIR"/build/extension-migrations
cd "$APP_DIR" || exit

curl -fsSL -o compose.yml https://raw.githubusercontent.com/calagopus/panel/refs/heads/main/compose.heavy.aio.yml

APP_ENCRYPTION_KEY=$(openssl rand -hex 16)
DB_PASS=$(openssl rand -hex 12)
TZ_VALUE=$(cat /etc/timezone 2>/dev/null || echo "UTC")

sed -i \
  -e "s|APP_ENCRYPTION_KEY=CHANGEME|APP_ENCRYPTION_KEY=${APP_ENCRYPTION_KEY}|" \
  -e "s|postgresql://panel:panel@db/panel|postgresql://panel:${DB_PASS}@db/panel|" \
  -e "s|POSTGRES_PASSWORD=panel|POSTGRES_PASSWORD=${DB_PASS}|" \
  -e "s|TZ=Europe/Berlin|TZ=${TZ_VALUE}|g" \
  compose.yml

cat <<EOF >wings-config.yml
app_name: Calagopus
EOF

{
  echo "Calagopus Heavy Credentials"
  echo "DB Password: ${DB_PASS}"
  echo "Encryption Key: ${APP_ENCRYPTION_KEY}"
} >~/calagopus-heavy.creds
chmod 600 ~/calagopus-heavy.creds
msg_ok "Configured Calagopus Heavy"

msg_info "Starting Calagopus Heavy (first start builds, this takes a while)"
$STD docker compose pull
$STD docker compose up -d
msg_ok "Started Calagopus Heavy"

motd_ssh
customize
cleanup_lxc
