# Cài đặt Cockpit trên Ubuntu Server (có tùy chọn KVM / libvirt)

Tài liệu hướng dẫn cài Cockpit để quản trị Linux server / bare-metal.
Có thể dùng Cockpit thuần (không VM) hoặc mở rộng thêm KVM / libvirt khi cần.

Phù hợp cho:
- Bare-metal X99 / Xeon
- k3s node
- Server backend / DB
- Lab VM nhẹ (tùy chọn)

---

## Mục tiêu

- Quản trị server qua web UI
- Theo dõi CPU / RAM / Disk / Network / systemd
- Mặc định KHÔNG cài hypervisor
- Chỉ cài KVM / libvirt khi thực sự cần VM

---

## Môi trường khuyến nghị

- OS: Ubuntu Server 22.04 LTS
- Kernel: 5.15+
- CPU: Intel Xeon (VT-x, VT-d)
- Vai trò: Bare-metal server

---

## 1. Cài Cockpit (thuần – không KVM)

sudo apt update
sudo apt install -y cockpit

---

## 2. Khởi động Cockpit

sudo systemctl enable --now cockpit.socket

Kiểm tra:
systemctl status cockpit.socket

---

## 3. Truy cập giao diện Web

https://<SERVER_IP>:9090

- Đăng nhập bằng user Linux (có sudo)
- Chấp nhận self-signed certificate

---

## 4. Chức năng Cockpit (khi chưa có KVM)

- CPU / Load
- RAM / Swap
- Disk / IO
- Network
- systemd services
- journal logs
- Web terminal

Không có Virtual Machines

---

## 5. Cài module giám sát (khuyến nghị)

cockpit-pcp (monitoring chi tiết)

sudo apt install -y cockpit-pcp

---

## 6. (TÙY CHỌN) Cài KVM + libvirt

Chỉ thực hiện bước này nếu cần chạy VM.
Nếu chỉ chạy k3s / container thì bỏ qua.

### 6.1 Kiểm tra CPU hỗ trợ ảo hóa

egrep -c '(vmx|svm)' /proc/cpuinfo

Kết quả > 0 là CPU hỗ trợ.

---

### 6.2 Cài KVM và libvirt

sudo apt install -y \
  qemu-kvm \
  libvirt-daemon-system \
  libvirt-clients \
  bridge-utils

---

### 6.3 Thêm user vào group libvirt và kvm

sudo usermod -aG libvirt,kvm $USER
newgrp libvirt

---

### 6.4 Enable và kiểm tra libvirt

sudo systemctl enable --now libvirtd
virsh list --all

---

## 7. (TÙY CHỌN) Bật quản lý VM trong Cockpit

Cài module quản lý VM cho Cockpit:

sudo apt install -y cockpit-machines

Restart Cockpit:

sudo systemctl restart cockpit.socket

Sau đó Cockpit sẽ xuất hiện mục:
Virtual Machines

---

## 8. Network cho VM (khuyến nghị)

Mặc định libvirt tạo:
- NAT bridge: virbr0

Phù hợp cho:
- VM test
- Lab nội bộ

Không khuyến nghị chạy VM prod nặng song song k3s trên cùng máy.

---

## 9. Bảo mật Cockpit

### Cách 1: Giới hạn IP truy cập bằng UFW

sudo ufw allow from 192.168.0.0/16 to any port 9090
sudo ufw deny 9090

---

### Cách 2: Bind localhost + SSH tunnel (khuyến nghị)

sudo mkdir -p /etc/systemd/system/cockpit.socket.d
sudo nano /etc/systemd/system/cockpit.socket.d/listen.conf

Nội dung file:

[Socket]
ListenStream=
ListenStream=127.0.0.1:9090

Reload và restart:

sudo systemctl daemon-reexec
sudo systemctl restart cockpit.socket

Truy cập qua SSH tunnel:

ssh -L 9090:localhost:9090 user@server_ip

---

## 10. Những điều KHÔNG nên làm

- Không chạy VM prod nặng chung với k3s
- Không bật auto-update OS trên server prod
- Không overcommit CPU/RAM khi dùng VM
- Không dùng Cockpit thay Proxmox cho hạ tầng lớn

---

## 11. Gỡ KVM / libvirt (nếu không dùng nữa)

sudo systemctl stop libvirtd
sudo apt remove --purge \
  cockpit-machines \
  qemu-kvm \
  libvirt-daemon-system \
  libvirt-clients

---

## 12. Gỡ Cockpit hoàn toàn

sudo systemctl stop cockpit.socket
sudo apt remove --purge cockpit cockpit-pcp

---

## Kết luận

- Cockpit có thể chạy độc lập
- KVM / libvirt là tùy chọn
- Phù hợp cho k3s bare-metal, DB / backend server, và lab VM nhỏ
