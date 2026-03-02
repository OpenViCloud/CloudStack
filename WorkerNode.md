# CloudStack Worker Node Bootstrap (Rocky Linux)

This document provides a professional, script-ready guide to bootstrap a KVM Worker Node for Apache CloudStack 4.20.

---

## 1. Target Topology & Requirements
- **Role**: KVM Compute Node (Data Plane)
- **OS**: Rocky Linux 8 or 9
- **Hypervisor**: QEMU/KVM with Libvirt
- **Network**: Dual Bridge Setup (cloudbr0, cloudbr1)

---

## 2. OS Preparation

### 2.1 Basic Updates & Tools
```bash
sudo dnf -y update
sudo dnf -y install epel-release
sudo dnf -y install bridge-utils network-scripts dnf-plugins-core chrony
sudo systemctl enable --now chronyd
```

### 2.2 Security Configuration (Lab/PoC Mode)
```bash
# Disable Firewalld to prevent blocking VM traffic
sudo systemctl disable --now firewalld

# Set SELinux to Permissive
sudo setenforce 0
sudo sed -i 's/^SELINUX=.*/SELINUX=permissive/' /etc/selinux/config
```

---

# 3. Network Configuration (Single NIC Bridge Setup)

## IMPORTANT

- The Management Server must be reachable from this host.
- The host IP MUST be assigned to a Linux bridge.
- The physical NIC must NOT keep its own IP.

---

## 3.1 Identify your NIC and clear

```bash
ip a
sudo nmcli connection delete cloudbr0
nmcli connection show
```

Example NIC: `enp4s0`

---

## 3.2 Create Linux Bridge

```bash
sudo nmcli connection add type bridge ifname cloudbr0 con-name cloudbr0
```

---

## 3.3 Assign Static IP to Bridge

Example:

```bash
sudo nmcli connection modify cloudbr0 \
  ipv4.method manual \
  ipv4.addresses 192.168.0.140/24 \
  ipv4.gateway 192.168.0.1 \
  ipv4.dns 8.8.8.8 \
  connection.autoconnect yes
```

---

## 3.4 Attach NIC to Bridge

```bash
sudo nmcli connection add type bridge-slave ifname enp4s0 master cloudbr0
```

---

## 3.5 Disable IP on Physical NIC

```bash
sudo nmcli connection modify enp4s0 ipv4.method disabled
```

---

## 3.6 Restart Network

⚠ This may temporarily disconnect SSH.

```bash
sudo systemctl restart NetworkManager
```

---

## 3.7 Verify

```bash
ip a
ip route
```

Expected:

- cloudbr0 has IP
- enp4s0 is slave of cloudbr0
- Default route via cloudbr0

Example:

```
default via 192.168.0.1 dev cloudbr0
```

---

## 3.8 Disable Default libvirt NAT Network

CloudStack does not use virbr0.

```bash
sudo virsh net-destroy default
sudo virsh net-autostart --disable default
```

---

## 4. Install CloudStack Agent & KVM

### 4.1 Configure Repositories
```bash
sudo tee /etc/yum.repos.d/cloudstack.repo > /dev/null <<EOF
[cloudstack]
name=Apache CloudStack
baseurl=http://download.cloudstack.org/centos/8/4.20/
enabled=1
gpgcheck=0
EOF
```


### 4.2 Install Packages
```bash
sudo dnf -y install cloudstack-agent qemu-kvm libvirt
```

---
## 5. Hypervisor Configuration (Libvirt)

On EL8/EL9 (Rocky Linux 8/9), libvirt uses systemd socket activation and modular daemons.

CloudStack 4.20 communicates with libvirt via local UNIX socket (`qemu:///system`).
TCP listening is NOT required.

---

### 5.1 Enable and Start Libvirt

```bash
sudo systemctl enable --now libvirtd
```

Verify:

```bash
sudo systemctl status libvirtd
```

Service must be active (running).

---

### 5.2 Configure QEMU VNC (Required)

CloudStack uses VNC/SPICE for console access.
By default, VNC listens only on localhost.

Edit:

```bash
sudo vi /etc/libvirt/qemu.conf
```

Uncomment and set:

```
vnc_listen = "0.0.0.0"
```

Restart libvirt:

```bash
sudo systemctl restart libvirtd
```

---

### 5.3 Verify Libvirt Access

Test local libvirt connectivity:

```bash
virsh -c qemu:///system list
```

If it returns an empty VM list without error, libvirt is working correctly.
---

## 6. CloudStack Agent Setup

Update the agent properties to ensure it uses Linux Bridges and connects to the correct Manager.

```bash
# Set bridge type
sudo sed -i 's/network.bridge.type=native/network.bridge.type=linux/' /etc/cloudstack/agent/agent.properties

# Enable and start the agent
sudo systemctl enable --now cloudstack-agent
```

---

## 7. Verification & Next Steps

1. **Check Status**: sudo systemctl status cloudstack-agent  
2. **Check Logs**: sudo tail -f /var/log/cloudstack/agent/agent.log  
3. **Register Host**: Go to the CloudStack UI -> Infrastructure -> Hosts -> Add Host.
