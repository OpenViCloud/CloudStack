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
- Root or passwordless sudo access
- Static IP configured
- Proper hostname and DNS resolution
- Internet access (or local mirror)

> **NOTE**  
> The Management Node **MUST NOT** run any guest VMs.

---

## Step 1 – OS Preparation

### 1. Update system packages
```bash
dnf -y update
```

### 2. Set hostname
```bash
hostnamectl set-hostname cloudstack-mgmt
```

### 3. Disable firewalld (lab only)
```bash
systemctl disable --now firewalld
```

### 4. Set SELinux to permissive (lab only)
```bash
sed -i 's/^SELINUX=.*/SELINUX=permissive/' /etc/selinux/config
setenforce 0
```

### 5. Enable time synchronization
```bash
dnf -y install chrony
systemctl enable --now chronyd
```

---

## Step 2 – Install Required Repositories

### 2.1 Enable EPEL
```bash
dnf -y install epel-release
```

### 2.2 Add Apache CloudStack repository
```bash
dnf -y install https://download.cloudstack.org/centos/8/cloudstack-release-8.rpm
```

### 2.3 Explicitly enable CloudStack 4.20
```bash
dnf config-manager --set-enabled cloudstack-4.20
dnf config-manager --set-disabled cloudstack-4.19 cloudstack-4.18 || true
```

---

## Step 3 – Pin MariaDB Version (IMPORTANT)

CloudStack 4.20 is validated primarily with **MariaDB 10.5 / 10.6**.  
This guide **pins MariaDB to 10.5** to avoid unexpected upgrades.

### 3.1 Reset and enable MariaDB 10.5 module
```bash
dnf module reset mariadb -y
dnf module enable mariadb:10.5 -y
```

### 3.2 Install MariaDB
```bash
dnf -y install mariadb-server
```

### 3.3 (Optional but recommended) Version lock MariaDB
```bash
dnf -y install dnf-plugins-core
dnf versionlock add mariadb\*
```

---

## Step 4 – Install CloudStack and Supporting Packages

```bash
dnf -y install   cloudstack-management   nfs-utils   python3   curl   wget
```

Enable services:
```bash
systemctl enable mariadb
systemctl enable nfs-server
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
systemctl start mariadb
```

```bash
mysql_secure_installation
```

```bash
systemctl status mariadb
```

---

## Step 6 – Configure NFS (Lab Mode Only)

```bash
mkdir -p /export/primary
mkdir -p /export/secondary
```

```bash
chown -R nfsnobody:nfsnobody /export
chmod -R 755 /export
```

```bash
echo "/export *(rw,async,no_root_squash,no_subtree_check)" >> /etc/exports
```

```bash
systemctl start nfs-server
exportfs -a
```

> ⚠️ **WARNING**  
> Running NFS on the Management Node is **for lab/demo only**.

---

## Step 7 – Initialize CloudStack Database

```bash
cloudstack-setup-databases cloud:cloud@localhost \
  --deploy-as=root \
  --mariadb-root-password <root_password>
```

> ⚠️ This step must be executed **EXACTLY ONCE**.

---

## Step 8 – Configure and Start CloudStack Management Server

```bash
cloudstack-setup-management
```

```bash
systemctl start cloudstack-management
systemctl enable cloudstack-management
```

---

## Step 9 – Verify Management Node

```bash
systemctl status cloudstack-management
systemctl status mariadb
systemctl status nfs-server
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
