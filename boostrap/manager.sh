#!/usr/bin/env bash
set -e

# ===== CONFIG =====
CS_VERSION="4.22"
MYSQL_ROOT_PASSWORD="cloudstack"
CS_DB_PASSWORD="cloudstack"
MGMT_IP="$(hostname -I | awk '{print $1}')"

# ===== PREP =====
export DEBIAN_FRONTEND=noninteractive
apt update && apt -y upgrade

apt install -y \
  openjdk-11-jdk \
  mysql-server \
  wget \
  gnupg \
  chrony

# ===== TIME SYNC =====
systemctl enable chrony
systemctl restart chrony

# ===== MYSQL CONFIG =====
sed -i 's/^bind-address.*/bind-address = 0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf
systemctl restart mysql

mysql <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${MYSQL_ROOT_PASSWORD}';
CREATE DATABASE cloud;
CREATE USER 'cloud'@'%' IDENTIFIED BY '${CS_DB_PASSWORD}';
GRANT ALL PRIVILEGES ON cloud.* TO 'cloud'@'%';
FLUSH PRIVILEGES;
EOF

# ===== CLOUDSTACK REPO =====
wget -O - https://download.cloudstack.org/release.asc | gpg --dearmor > /usr/share/keyrings/cloudstack.gpg

echo "deb [signed-by=/usr/share/keyrings/cloudstack.gpg] \
https://download.cloudstack.org/ubuntu jammy ${CS_VERSION}" \
> /etc/apt/sources.list.d/cloudstack.list

apt update

# ===== INSTALL MANAGEMENT =====
apt install -y cloudstack-management

# ===== DB INIT =====
cloudstack-setup-databases \
  cloud:${CS_DB_PASSWORD}@localhost \
  --deploy-as=root:${MYSQL_ROOT_PASSWORD}

# ===== MANAGEMENT INIT =====
cloudstack-setup-management

systemctl status cloudstack-management --no-pager

echo "========================================"
echo "CloudStack ${CS_VERSION} Management READY"
echo "UI: http://${MGMT_IP}:8080/client"
echo "Default login: admin / password"
echo "========================================"
