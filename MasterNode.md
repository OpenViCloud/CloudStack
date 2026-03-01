# Bootstrap CloudStack Management Node (Rocky Linux) – CloudStack 4.20 + MariaDB pinned

This document provides a **step-by-step bootstrap guide** for installing  
a CloudStack Management Node on a fresh Rocky Linux system.

Target stack:
- **CloudStack 4.20**
- **MariaDB 10.5 (pinned)**

All steps are designed to be:
- Script-friendly
- Reproducible
- Non-interactive where possible
- Suitable for lab / PoC / long-lived environments

---

## Step 0 – Preconditions

Before starting, ensure:

- Rocky Linux 8 (recommended) or 9
- User with passwordless sudo access
- Static IP configured
- Proper hostname and DNS resolution
- Internet access (or local mirror)

> **NOTE**  
> The Management Node **MUST NOT** run any guest VMs.

---

## Step 1 – OS Preparation

### 1. Update system packages
```bash
sudo dnf -y update
```

### 2. Set hostname
```bash
sudo hostnamectl set-hostname cloudstack-mgmt
```

### 3. Disable firewalld (lab only)
```bash
sudo systemctl disable --now firewalld
```

### 4. Set SELinux to permissive (lab only)
```bash
sudo sed -i 's/^SELINUX=.*/SELINUX=permissive/' /etc/selinux/config
sudo setenforce 0
```

### 5. Enable time synchronization
```bash
sudo dnf -y install chrony
sudo systemctl enable --now chronyd
```

---

## Step 2 – Install Required Repositories

### 2.1 Enable EPEL
```bash
sudo dnf -y install epel-release
```

### 2.2 Add Apache CloudStack repository
```bash
sudo tee /etc/yum.repos.d/cloudstack.repo > /dev/null <<EOF
[cloudstack]
name=Apache CloudStack
baseurl=http://download.cloudstack.org/centos/8/4.20/
enabled=1
gpgcheck=0
EOF
```

### 2.3 Install CloudStack packages
```bash
sudo dnf clean all
sudo dnf makecache
sudo dnf install -y cloudstack-management
```

---

## Step 3 – Pin MariaDB Version (IMPORTANT)

CloudStack 4.20 is validated primarily with **MariaDB 10.5 / 10.6**.  
This guide **pins MariaDB to 10.5** to avoid unexpected upgrades.

### 3.1 Reset and enable MariaDB 10.5 module
```bash
sudo dnf module reset mariadb -y
sudo dnf module enable mariadb:10.5 -y
```

### 3.2 Install MariaDB
```bash
sudo dnf -y install mariadb-server
```

### 3.3 (Optional but recommended) Version lock MariaDB
```bash
sudo dnf -y install dnf-plugins-core
sudo dnf versionlock add mariadb\*
```

---

## Step 4 – Install CloudStack and Supporting Packages

```bash
sudo dnf -y install \
  cloudstack-management \
  nfs-utils \
  python3 \
  curl \
  wget
```

Enable services:
```bash
sudo systemctl enable mariadb
sudo systemctl enable nfs-server
```

Verify versions:
```bash
rpm -qi cloudstack-management | grep Version
rpm -qi mariadb-server | grep Version
```

Expected:
```
CloudStack : 4.20.x
MariaDB    : 10.5.x
```

---

## Step 5 – Configure and Start MariaDB

```bash
sudo systemctl start mariadb
```

```bash
sudo mysql_secure_installation
```

```bash
sudo systemctl status mariadb
```

---

## Step 6 – Configure NFS (Lab Mode Only)

```bash
sudo mkdir -p /export/primary
sudo mkdir -p /export/secondary
```

```bash
sudo chown -R nfsnobody:nfsnobody /export
sudo chmod -R 755 /export
```

```bash
echo "/export *(rw,async,no_root_squash,no_subtree_check)" | sudo tee -a /etc/exports
```

```bash
sudo systemctl start nfs-server
sudo exportfs -a
```

> ⚠️ **WARNING**  
> Running NFS on the Management Node is **for lab/demo only**.

---

## Step 7 – Initialize CloudStack Database

```bash
sudo cloudstack-setup-databases cloud:cloud@localhost \
  --deploy-as=root \
  --mariadb-root-password <root_password>
```

> ⚠️ This step must be executed **EXACTLY ONCE**.

---

## Step 8 – Configure and Start CloudStack Management Server

```bash
sudo cloudstack-setup-management
```

```bash
sudo systemctl start cloudstack-management
sudo systemctl enable cloudstack-management
```

---

## Step 9 – Verify Management Node

```bash
sudo systemctl status cloudstack-management
sudo systemctl status mariadb
sudo systemctl status nfs-server
```

Access UI/API:
```
http://<management-ip>:8080/client
```

---

## Design Principles

- Explicit version pinning (CloudStack & MariaDB)
- Script-first installation
- No UI-based initial configuration
- Fail-fast on version mismatch
- Idempotent where possible

---

This file defines a **stable, reproducible bootstrap procedure** for a  
CloudStack 4.20 Management Node with pinned MariaDB.
