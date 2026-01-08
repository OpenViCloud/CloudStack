# Install Cockpit on Ubuntu Server (with optional KVM / libvirt)

This document describes how to install **Cockpit** on an Ubuntu Server
for **bare-metal usage**.
Cockpit can be used **standalone** (no virtualization), and **optionally**
extended with **KVM / libvirt** only when virtual machines are required.

Suitable for:
- Bare-metal X99 / Xeon servers
- k3s nodes
- Backend / database servers
- Light VM lab (optional)

---

## Goals

- Web-based server management
- Monitor CPU / RAM / Disk / Network / systemd
- Default setup **without hypervisor**
- Add KVM / libvirt only if VMs are really needed

---

## Recommended Environment

- OS: Ubuntu Server 22.04 LTS
- Kernel: 5.15+
- CPU: Intel Xeon (VT-x / VT-d supported)
- Role: Bare-metal server

---

## 1. Install Cockpit

```sh
sudo apt update
sudo apt install -y cockpit
```

⚠️ Do NOT install the following packages at this stage:

- cockpit-machines
- libvirt-daemon
- qemu-kvm

---

## 2. Enable and start Cockpit

```sh
sudo systemctl enable --now cockpit.socket
```

Verify status:

```sh
systemctl status cockpit.socket
```

---

## 3. Access the Web UI

```
https://<SERVER_IP>:9090
```

- Log in with a Linux user that has sudo privileges
- Accept the self-signed certificate warning

---

## 4. Available features (without KVM)

- CPU / Load monitoring
- Memory / Swap
- Disk and I/O
- Network
- systemd services
- journal logs
- Web terminal

❌ Virtual Machines are **not** available yet

---

## 5. Install monitoring add-on (recommended)

### cockpit-pcp (advanced metrics)

```sh
sudo apt install -y cockpit-pcp
```

Provides:
- Per-core CPU metrics
- Disk I/O statistics
- Network throughput

---

## 6. (Optional) Install KVM and libvirt

⚠️ Perform this section **only if you need virtual machines**.
If you only run k3s or containers, **skip this entire section**.

---

### 6.1 Check CPU virtualization support

```sh
egrep -c '(vmx|svm)' /proc/cpuinfo
```

Result > 0 means virtualization is supported.

---

### 6.2 Install KVM and libvirt packages

```sh
sudo apt install -y \
  qemu-kvm \
  libvirt-daemon-system \
  libvirt-clients \
  bridge-utils
```

---

### 6.3 Add user to libvirt and kvm groups

```sh
sudo usermod -aG libvirt,kvm $USER
newgrp libvirt
```

---

### 6.4 Enable and verify libvirt

```sh
sudo systemctl enable --now libvirtd
```

```sh
virsh list --all
```

---

## 7. (Optional) Enable VM management in Cockpit

Install the Cockpit VM module:

```sh
sudo apt install -y cockpit-machines
```

Restart Cockpit:

```sh
sudo systemctl restart cockpit.socket
```

After this, a **Virtual Machines** section will appear in Cockpit.

---

## 8. VM networking notes

By default, libvirt creates:
- NAT bridge: `virbr0`

Recommended for:
- Test VMs
- Lab environments

❌ Not recommended to run heavy production VMs alongside k3s on the same host.

---

## 9. Secure Cockpit access

### Option 1: Restrict access by IP (UFW)

```sh
sudo ufw allow from 192.168.0.0/16 to any port 9090
sudo ufw deny 9090
```

---

## 10. Remove KVM / libvirt (if no longer needed)

```sh
sudo systemctl stop libvirtd
sudo apt remove --purge \
  cockpit-machines \
  qemu-kvm \
  libvirt-daemon-system \
  libvirt-clients
```

---

## 11. Remove Cockpit completely

```sh
sudo systemctl stop cockpit.socket
sudo apt remove --purge cockpit cockpit-pcp
```

---
