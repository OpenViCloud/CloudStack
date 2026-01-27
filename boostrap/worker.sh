#!/usr/bin/env bash
set -e

# ===== CONFIG =====
MGMT_IP="CHANGE_ME_MANAGER_IP"

# ===== PREP =====
export DEBIAN_FRONTEND=noninteractive
apt update && apt -y upgrade

apt install -y \
  qemu-kvm \
  libvirt-daemon-system \
  libvirt-clients \
  bridge-utils \
  openvswitch-switch \
  chrony \
  wget \
  gnupg

# ===== KVM CHECK =====
kvm-ok || true

# ===== TIME SYNC =====
systemctl enable chrony
systemctl restart chrony

# ===== CLOUDSTACK REPO =====
wget -O - https://download.cloudstack.org/release.asc | gpg --dearmor > /usr/share/keyrings/cloudstack.gpg

echo "deb [signed-by=/usr/share/keyrings/cloudstack.gpg] \
https://download.cloudstack.org/ubuntu jammy 4.22" \
> /etc/apt/sources.list.d/cloudstack.list

apt update

# ===== INSTALL AGENT =====
apt install -y cloudstack-agent

# ===== LIBVIRT CONFIG =====
sed -i 's/#listen_tls = 0/listen_tls = 0/' /etc/libvirt/libvirtd.conf
sed -i 's/#listen_tcp = 1/listen_tcp = 1/' /etc/libvirt/libvirtd.conf
sed -i 's/#auth_tcp = "sasl"/auth_tcp = "none"/' /etc/libvirt/libvirtd.conf

sed -i 's/^LIBVIRTD_ARGS=.*/LIBVIRTD_ARGS="--listen"/' \
  /etc/default/libvirtd

systemctl restart libvirtd
systemctl restart cloudstack-agent

echo "========================================"
echo "CloudStack ${CS_VERSION} KVM Host READY"
echo "Add this host via UI:"
echo "Hypervisor: KVM"
echo "Hostname/IP: $(hostname -I | awk '{print $1}')"
echo "========================================"
