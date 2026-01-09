# Install k3s on Ubuntu Server (Bare-metal, Production Oriented)

This document describes how to install **k3s** on a **bare-metal Ubuntu Server**.
The setup is optimized for:
- X99 / Xeon servers
- Long-running workloads
- Backend / database / GitOps
- Minimal overhead, high stability

---

## Goals

- Lightweight Kubernetes on bare metal
- No hypervisor required
- Predictable resource usage
- Easy to debug and maintain
- Suitable for single-node or future scale-out

---

## Recommended Environment

- OS: Ubuntu Server 22.04 LTS
- Kernel: 5.15+
- CPU: Intel Xeon (many cores)
- RAM: 64 GB+
- Disk: SSD / NVMe preferred
- Network: Static IP recommended

---

## 1. OS Preparation (Important)

### 1.1 Disable swap

```sh
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab
```

Verify:

```sh
free -h
```

---

### 1.2 Load required kernel modules

```sh
cat <<EOF | sudo tee /etc/modules-load.d/k3s.conf
overlay
br_netfilter
EOF
```

```sh
sudo modprobe overlay
sudo modprobe br_netfilter
```

---

### 1.3 Kernel sysctl tuning

```sh
cat <<EOF | sudo tee /etc/sysctl.d/99-k3s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
vm.swappiness                       = 10
EOF
```

Apply:

```sh
sudo sysctl --system
```

---

## 2. Install k3s (Server Mode)

This installs **k3s server + agent** on the same node
(single-node cluster).

### 2.1 Install k3s

```sh
curl -sfL https://get.k3s.io | \
  INSTALL_K3S_VERSION="v1.34.2+k3s1" \
  sh -s - server \
    --disable traefik \
    --disable servicelb \
    --disable-network-policy \
    --flannel-backend=none \
    --write-kubeconfig-mode 644
```

Explanation:
- Disable Traefik: use your own ingress later
- Disable ServiceLB: use MetalLB if needed
- Increase max pods for large machines

---

### 2.2 Verify installation

```sh
kubectl get nodes -o wide
```

Expected:
- STATUS: Ready
- ROLES: control-plane,master

---

### 2.3 Install Calico CNI

```sh
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.2/manifests/calico.yaml
kubectl get pods -n calico-system
kubectl get nodes -o wide
```

Expected:
- STATUS: Ready
- ROLES: control-plane,master
---

## 3. kubeconfig Access

k3s installs kubeconfig at:

```sh
/etc/rancher/k3s/k3s.yaml
```

To use as normal user:

```sh
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config
```

Test:

```sh
kubectl get pods -A
```

---

## 5. Networking Notes

- Default CNI: flannel
- Works well for most setups
- Replace only if you really need (e.g. Cilium)

---

## 6. Basic Health Checks

```sh
kubectl get nodes
kubectl get pods -A
kubectl top nodes
kubectl top pods -A
```

---

## 7. Logs and Debugging

k3s service:

```sh
sudo systemctl status k3s
sudo journalctl -u k3s -f
```

containerd logs:

```sh
sudo journalctl -u containerd -f
```

---

## 8. Uninstall k3s (if needed)

```sh
sudo /usr/local/bin/k3s-uninstall.sh
```

---

## Conclusion

- k3s is ideal for bare-metal servers
- Minimal overhead, easy operations
- Excellent choice for X99 / Xeon systems
- Scales well from single-node to multi-node

This document can be used directly as:
- installation guide
- runbook
- infra documentation
