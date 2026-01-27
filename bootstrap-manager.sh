#!/bin/bash
set -euo pipefail
exec > >(tee /var/log/bootstrap-manager.log) 2>&1

### CONFIG ###
CS_VERSION="4.18"
DB_ROOT_PASS="cloudstack"
CS_DB_PASS="cloud"
TIMEZONE="Asia/Ho_Chi_Minh"
################

# Guard: do not run on worker
if systemctl is-active --quiet cloudstack-agent; then
  echo "❌ This node looks like a worker"
  exit 1
fi

MANAGER_IP="$(hostname -I | awk '{print $1}')"

echo "[1] System preparation"
swapoff -a || true
sed -i '/ swap / s/^/#/' /etc/fstab
timedatectl set-timezone "$TIMEZONE"

apt update && apt upgrade -y
apt install -y chrony curl gnupg lsb-release mysql-server nfs-kernel-server
systemctl enable --now chrony

echo "[2] Add CloudStack repository"
curl -fsSL https://download.cloudstack.org/release.asc | gpg --dearmor \
  > /usr/share/keyrings/cloudstack.gpg

echo "deb [signed-by=/usr/share/keyrings/cloudstack.gpg] \
https://download.cloudstack.org/ubuntu jammy ${CS_VERSION}" \
> /etc/apt/sources.list.d/cloudstack.list

apt update
apt install -y cloudstack-management

echo "[3] MySQL tuning for CloudStack"
cat <<EOF >/etc/mysql/mysql.conf.d/cloudstack.cnf
[mysqld]
innodb_rollback_on_timeout=1
innodb_lock_wait_timeout=600
max_connections=1000
log-bin=mysql-bin
binlog-format=ROW
EOF

systemctl restart mysql

echo "[4] Setup CloudStack databases"
cloudstack-setup-databases cloud:${CS_DB_PASS}@localhost \
  --deploy-as=root:${DB_ROOT_PASS}

echo "[5] Setup CloudStack management server"
cloudstack-setup-management

echo "[6] Setup NFS storage (demo)"
mkdir -p /export/{primary,secondary}
chmod -R 777 /export

cat <<EOF >/etc/exports
/export *(rw,async,no_root_squash,no_subtree_check)
EOF

exportfs -a
systemctl restart nfs-kernel-server

echo "[DONE] CloudStack Management is ready"
echo "UI: http://${MANAGER_IP}:8080/client"
