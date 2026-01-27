#!/bin/bash
set -euo pipefail
exec > >(tee /var/log/bootstrap-worker.log) 2>&1

### CONFIG ###
MANAGER_IP="${MANAGER_IP:-192.168.1.10}"
CS_VERSION="4.18"
PHY_IF="${PHY_IF:-eth0}"
BRIDGE_IF="${BRIDGE_IF:-br0}"
TIMEZONE="Asia/Ho_Chi_Minh"
################

if systemctl is-active --quiet cloudstack-management; then
  echo "❌ This node looks like a manager"
  exit 1
fi

echo "[1] System prepare"
swapoff -a || true
sed -i '/ swap / s/^/#/' /etc/fstab
timedatectl set-timezone $TIMEZONE

apt update && apt upgrade -y
apt install -y chrony curl gnupg lsb-release bridge-utils
systemctl enable --now chrony

echo "[2] Install KVM"
apt install -y qemu-kvm libvirt-daemon-system libvirt-clients cpu-checker
systemctl enable --now libvirtd
kvm-ok || echo "⚠ CPU may not support KVM"

echo "[3] Network bridge"
cat <<EOF >/etc/netplan/01-${BRIDGE_IF}.yaml
network:
  version: 2
  ethernets:
    ${PHY_IF}:
      dhcp4: no
  bridges:
    ${BRIDGE_IF}:
      interfaces: [${PHY_IF}]
      dhcp4: yes
EOF

netplan apply

echo "[4] Add CloudStack repo"
curl -fsSL https://download.cloudstack.org/release.asc | gpg --dearmor \
  > /usr/share/keyrings/cloudstack.gpg

echo "deb [signed-by=/usr/share/keyrings/cloudstack.gpg] \
https://download.cloudstack.org/ubuntu jammy ${CS_VERSION}" \
> /etc/apt/sources.list.d/cloudstack.list

apt update
apt install -y cloudstack-agent

echo "[5] Configure agent"
sed -i "s/^#\?host=.*/host=${MANAGER_IP}/" \
  /etc/cloudstack/agent/agent.properties

systemctl restart cloudstack-agent

echo "[DONE] Worker ready"
