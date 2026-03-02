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

## 3. Network Configuration (Bridge Setup)

CloudStack KVM nodes require standard Linux Bridges. 
- **cloudbr0**: Used for Management and Public traffic.
- **cloudbr1**: Used for Guest (Private) traffic.

### 3.1 Configure Physical Interface (e.g., eth0)
```bash
sudo cat <<EOF > /etc/sysconfig/network-scripts/ifcfg-eth0
DEVICE=eth0
ONBOOT=yes
HOTPLUG=no
NM_CONTROLLED=no
BOOTPROTO=none
BRIDGE=cloudbr0
EOF
```

### 3.2 Configure Management Bridge (cloudbr0)
```bash
sudo cat <<EOF > /etc/sysconfig/network-scripts/ifcfg-cloudbr0
DEVICE=cloudbr0
ONBOOT=yes
HOTPLUG=no
NM_CONTROLLED=no
BOOTPROTO=static
IPADDR=192.168.1.20  # Change to your Worker Node IP
NETMASK=255.255.255.0
GATEWAY=192.168.1.1
DNS1=8.8.8.8
TYPE=Bridge
STP=off
EOF
```

### 3.3 Configure Guest Bridge (cloudbr1)
```bash
sudo cat <<EOF > /etc/sysconfig/network-scripts/ifcfg-cloudbr1
DEVICE=cloudbr1
ONBOOT=yes
HOTPLUG=no
NM_CONTROLLED=no
BOOTPROTO=none
TYPE=Bridge
STP=off
EOF
```

```bash
# Apply changes
sudo systemctl restart network
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

```bash
sudo dnf config-manager --set-enabled cloudstack-4.20
```

### 4.2 Install Packages
```bash
sudo dnf -y install cloudstack-agent qemu-kvm libvirt
```

---

## 5. Hypervisor Configuration (Libvirt)

CloudStack needs Libvirt to listen on TCP for Live Migration and remote orchestration.

### 5.1 Enable TCP Listening
```bash
# Modify libvirtd.conf
sudo sed -i 's/^#listen_tls = 0/listen_tls = 0/' /etc/libvirt/libvirtd.conf
sudo sed -i 's/^#listen_tcp = 1/listen_tcp = 1/' /etc/libvirt/libvirtd.conf
sudo sed -i 's/^#tcp_port = "16509"/tcp_port = "16509"/' /etc/libvirt/libvirtd.conf
sudo sed -i 's/^#auth_tcp = "sasl"/auth_tcp = "none"/' /etc/libvirt/libvirtd.conf

# Add listen flag to service arguments
echo 'LIBVIRTD_ARGS="--listen"' | sudo tee -a /etc/sysconfig/libvirtd > /dev/null

sudo systemctl enable --now libvirtd
```

### 5.2 Configure QEMU VNC
```bash
sudo sed -i 's/^#vnc_listen = "127.0.0.1"/vnc_listen = "0.0.0.0"/' /etc/libvirt/qemu.conf
sudo systemctl restart libvirtd
```

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
