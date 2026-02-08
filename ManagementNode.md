# Bootstrap CloudStack Management Node (Rocky Linux)

This document provides a **step-by-step bootstrap guide** for installing  
a CloudStack Management Node on a fresh Rocky Linux system.

All steps are designed to be:
- Script-friendly
- Reproducible
- Non-interactive where possible
- Suitable for lab / PoC environments

---

## Step 0 – Preconditions

Before starting, ensure:

- Rocky Linux 8 or 9 (Minimal Install)
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

## Step 2 – Install Required Repositories (CloudStack 4.20)

```bash
# Enable EPEL
dnf -y install epel-release

# Add Apache CloudStack repository (Rocky / CentOS 8 compatible)
dnf -y install https://download.cloudstack.org/centos/8/cloudstack-release-8.rpm

# Explicitly enable CloudStack 4.20 and disable older versions
dnf config-manager --set-enabled cloudstack-4.20
dnf config-manager --set-disabled cloudstack-4.19 cloudstack-4.18 || true
```

---

## Step 3 – Install Required Packages

```bash
dnf -y install   cloudstack-management   mariadb-server   nfs-utils   python3   curl   wget
```

Enable services:
```bash
systemctl enable mariadb
systemctl enable nfs-server
```

Verify CloudStack version:
```bash
rpm -qi cloudstack-management | grep Version
```

Expected:
```
Version     : 4.20.x
```

---

## Step 4 – Configure and Start MariaDB

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

## Step 5 – Configure NFS (Lab Mode Only)

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

## Step 6 – Initialize CloudStack Database

```bash
cloudstack-setup-databases cloud:cloud@localhost   --deploy-as=root   --mariadb-root-password <root_password>
```

> ⚠️ This step must be executed **EXACTLY ONCE**.

---

## Step 7 – Configure and Start CloudStack Management Server

```bash
cloudstack-setup-management
```

```bash
systemctl start cloudstack-management
systemctl enable cloudstack-management
```

---

## Step 8 – Verify Management Node

```bash
systemctl status cloudstack-management
systemctl status mariadb
systemctl status nfs-server
```

```
http://<management-ip>:8080/client
```

---

## Design Principles

- Script-first installation
- No UI-based initial configuration
- Idempotent where possible
