# CloudStack Baremetal Bootstrap

Bootstrap Apache CloudStack from empty baremetal machines using a script-first and reproducible approach.

Target topology:
- 1 Management node
- 1 KVM Worker node

Designed for:
- No UI clicking
- PXE / iDRAC / cloud-init friendly
- Lab, PoC, and small production setups

---

## Project Structure

```
cloudstack-bootstrap/
├── README.md
├── manager/
│   └── bootstrap-manager.sh
├── worker/
│   └── bootstrap-worker.sh
└── cloudmonkey/
    └── cloudmonkey-init.sh
```

---

## Bootstrap Flow

1. Management bootstrap
   - OS preparation
   - MySQL
   - CloudStack Management Server
   - NFS (Primary and Secondary for demo purposes)

2. Worker bootstrap
   - KVM and libvirt
   - Network bridge
   - CloudStack Agent

3. CloudStack logical initialization
   - Zone
   - Pod
   - Cluster
   - Storage

---

## Usage

### 1. Bootstrap Management Node

```bash
curl -fsSL https://raw.githubusercontent.com/<org>/<repo>/manager/bootstrap-manager.sh | bash
```

After completion, CloudStack UI will be available at:

```
http://<manager-ip>:8080/client
```

Default credentials:
- Username: admin
- Password: password

---

### 2. Bootstrap Worker Node

```bash
MANAGER_IP=192.168.1.10 \
curl -fsSL https://raw.githubusercontent.com/<org>/<repo>/worker/bootstrap-worker.sh | bash
```

The worker will automatically register itself to the management server once the cluster exists.

---

### 3. Initialize CloudStack Topology (Logic Layer)

```bash
bash cloudmonkey/cloudmonkey-init.sh
```

This script creates:
- Basic Zone
- Pod
- KVM Cluster
- Primary Storage (NFS)
- Secondary Storage (NFS)

This step fully replaces initial UI-based configuration.

---

## Environment Assumptions

- OS: Ubuntu 22.04 LTS
- CloudStack: 4.18
- Hypervisor: KVM
- Network model: Basic Zone
- Storage backend: NFS (lab or demo only)

---

## Important Notes

- Each bootstrap script must be executed only once per node
- Do not use NFS on the management node in production
- Run cloudmonkey-init.sh only after:
  - Management server is running
  - Worker agent is connected
  - NFS storage is available

---

## Design Philosophy

- bootstrap-manager.sh and bootstrap-worker.sh
  Handle physical host and OS-level provisioning

- cloudmonkey-init.sh
  Handles CloudStack logical topology

No UI clicks. No hidden state. Everything is defined in Git.
