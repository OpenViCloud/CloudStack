# CloudStack Baremetal Bootstrap (Rocky Linux)

Bootstrap Apache CloudStack on empty baremetal machines using a script-first,
reproducible approach. This project avoids UI-based configuration and keeps
all system state explicitly defined in code.

================================================================

## 1. Target Topology

- 1 Management Node
- 1 KVM Worker Node (scalable to multiple workers)

================================================================

## 2. High-Level Architecture

CloudStack follows a strict **Control Plane / Data Plane** architecture.

================================================================

                    +----------------------------+
                    |      Admin / Automation    |
                    |  (Browser / cloudmonkey)   |
                    +-------------+--------------+
                                  |
                                  | HTTPS / REST API
                                  |
        +-------------------------v-------------------------+
        |              CloudStack Management Node            |
        |                    Rocky Linux                     |
        |----------------------------------------------------|
        |  cloudstack-management                              |
        |  - Scheduler                                       |
        |  - Orchestration Engine                            |
        |  - Network & Storage Control                       |
        |                                                    |
        |  Embedded Jetty (Spring Boot)                      |
        |  - CloudStack REST API                             |
        |  - Web UI                                         |
        |                                                    |
        |  MariaDB                                          |
        |  - Global metadata                                |
        |  - VM / Network / Storage state                   |
        |                                                    |
        |  NFS Server (lab only)                             |
        |  - Primary Storage                                |
        |  - Secondary Storage                              |
        +-------------------------+--------------------------+
                                  |
                                  | Management Network
                                  | (Agent & Control Traffic)
                                  |
        +-------------------------v--------------------------+
        |                 KVM Worker Node(s)                 |
        |                    Rocky Linux                     |
        |----------------------------------------------------|
        |  cloudstack-agent                                  |
        |  - Receives instructions from Manager              |
        |                                                    |
        |  libvirt + qemu-kvm                                |
        |  - VM lifecycle execution                          |
        |                                                    |
        |  Linux Bridges                                    |
        |  - cloudbr0 (Management / Public)                  |
        |  - cloudbr1 (Guest / Private)                      |
        |                                                    |
        |  Guest Virtual Machines                            |
        +----------------------------------------------------+

================================================================

Architecture rules:
- Management Node is control-plane only
- No guest VMs run on the Management Node
- All orchestration decisions originate from the Manager
- Worker Nodes never communicate directly with each other
- Agents maintain a persistent control channel to the Manager

================================================================

## 3. Management Node Architecture

### 3.1 Role and Responsibilities

The Management Node is the single source of truth for the cloud and is
responsible for:

- Scheduling and placing virtual machines
- Orchestrating compute, network, and storage resources
- Maintaining global system state and metadata
- Exposing CloudStack REST APIs and Web UI
- Coordinating all KVM Worker Nodes

----------------------------------------------------------------

### 3.2 Installed Components

CloudStack Management Server
- Package: cloudstack-management
- Runs as a Spring Boot application
- Uses embedded Jetty (no external application server)

Database (MariaDB)
- Runs locally on the Management Node
- Stores:
  - VM and host metadata
  - Network topology and state
  - Accounts, domains, and projects
  - Storage mappings and capacity data

Storage Services (Lab Mode Only)
- NFS server running on the Management Node
- Exports:
  - Primary Storage (VM disks)
  - Secondary Storage (templates, ISOs, snapshots)

WARNING:
Running NFS on the Management Node is for lab/demo only.
This design is NOT suitable for production environments.

================================================================

## 4. Design Principles

- Script-first provisioning
- No UI-based initial configuration
- Idempotent bootstrap per node
- Easy teardown and rebuild
- Clear separation between control plane and data plane
- All system state is defined and versioned in Git

================================================================

No UI clicks.
No hidden state.
Everything is defined in Git.
