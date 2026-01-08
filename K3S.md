CÀI ĐẶT K3S – SINGLE NODE (BARE-METAL)

Mục đích:
- Cài k3s trên 1 node duy nhất
- Node vừa là control-plane vừa là worker
- Phù hợp bare-metal (X99 / Xeon)
- Có thể mở rộng thêm node sau mà không phải cài lại

Yêu cầu:
- Ubuntu Server 22.04 LTS
- Kernel 5.15+
--------------------------------------------------
A. CHUẨN BỊ HỆ THỐNG (BẮT BUỘC)
--------------------------------------------------

A1. Tắt swap (Kubernetes không chạy với swap)

sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

Kiểm tra:
free -h

--------------------------------------------------
A2. Load kernel modules cần cho Kubernetes
--------------------------------------------------

Tạo file cấu hình load module khi boot:

sudo tee /etc/modules-load.d/k8s.conf <<EOF
overlay
br_netfilter
EOF

Load ngay các module:

sudo modprobe overlay
sudo modprobe br_netfilter

--------------------------------------------------
A3. Cấu hình sysctl cho Kubernetes networking
--------------------------------------------------

Tạo file sysctl:

sudo tee /etc/sysctl.d/99-kubernetes.conf <<EOF
net.bridge.bridge-nf-call-iptables=1
net.bridge.bridge-nf-call-ip6tables=1
net.ipv4.ip_forward=1
vm.swappiness=10
EOF

Apply cấu hình:

sudo sysctl --system

--------------------------------------------------
B. CÀI K3S (SINGLE NODE)
--------------------------------------------------

Cài k3s server.
Tắt Traefik và ServiceLB để chủ động ingress sau này.

curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --disable traefik --disable servicelb --write-kubeconfig-mode 644 --kubelet-arg=max-pods=250" sh -

--------------------------------------------------
C. KIỂM TRA K3S
--------------------------------------------------

kubectl get nodes -o wide

Kết quả mong đợi:
- Node ở trạng thái Ready
- Role: control-plane, master

--------------------------------------------------
D. CÀI CÔNG CỤ CƠ BẢN (KHUYẾN NGHỊ)
--------------------------------------------------

sudo apt install -y curl htop jq ca-certificates apt-transport-https

--------------------------------------------------
E. BACKUP TỐI THIỂU (RẤT QUAN TRỌNG)
--------------------------------------------------

Tạo snapshot etcd thủ công:

sudo k3s etcd-snapshot save

Snapshot nằm trong:
/var/lib/rancher/k3s/server/db/snapshots
