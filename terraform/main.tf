################################################################################
# 1. TERRAFORM & PROVIDER CONFIGURATION
################################################################################
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    cloudstack = {
      source  = "cloudstack/cloudstack"
      version = "~> 0.6"
    }
  }
}

provider "cloudstack" {
  api_url    = var.api_url
  api_key    = var.api_key
  secret_key = var.secret_key
}

################################################################################
# 2. USE EXISTING ZONE (CREATED BY UI)
################################################################################

resource "cloudstack_zone" "zone" {
  name               = var.zone_name
  network_type       = "Advanced"
  guest_cidr_address = var.guest_cidr

  dns1  = "8.8.8.8"
  dns2  = "1.1.1.1"

  internal_dns1 = "8.8.8.8"
  internal_dns2 = "1.1.1.1"
}

################################################################################
# 3. POD
################################################################################

resource "cloudstack_pod" "pod" {
  name    = var.pod_name
  zone_id = cloudstack_zone.zone.id

  gateway  = var.pod_gateway
  netmask  = var.pod_netmask
  start_ip = var.pod_start_ip
  end_ip   = var.pod_end_ip
}

################################################################################
# 4. SECONDARY STORAGE
################################################################################

resource "cloudstack_secondary_storage" "secondary" {
  zone_id          = cloudstack_zone.zone.id
  storage_provider = "nfs"
  url              = "nfs://${var.nfs_ip}/${trim(var.secondary_nfs_path, "/")}"
}

################################################################################
# 5. CLUSTER
################################################################################

resource "cloudstack_cluster" "cluster" {
  cluster_name = var.cluster_name
  zone_id      = cloudstack_zone.zone.id
  pod_id       = cloudstack_pod.pod.id

  hypervisor   = "KVM"
  cluster_type = "CloudManaged"
  allocation_state = "Enabled"

  depends_on = [
    cloudstack_secondary_storage.secondary
  ]
}

################################################################################
# 6. KVM HOST
################################################################################

resource "cloudstack_host" "kvm1" {
  zone_id    = cloudstack_zone.zone.id
  pod_id     = cloudstack_pod.pod.id
  cluster_id = cloudstack_cluster.cluster.id

  hypervisor = "KVM"

  url      = "http://${var.kvm_host_ip}"
  username = var.kvm_host_user
  password = var.kvm_host_password

  timeouts {
    create = "20m"
    delete = "20m"
  }
}

################################################################################
# 6. PRIMARY STORAGE
################################################################################

resource "cloudstack_storage_pool" "primary" {
  name       = "primary-nfs"
  zone_id    = cloudstack_zone.zone.id
  pod_id     = cloudstack_pod.pod.id
  cluster_id = cloudstack_cluster.cluster.id

  scope      = "CLUSTER"
  hypervisor = "KVM"

  url = "nfs://${var.nfs_ip}/${trim(var.primary_nfs_path, "/")}"
  
}

################################################################################
# 7. OUTPUTS
################################################################################

output "summary" {
  value = {
    zone_id    = cloudstack_zone.zone.id
    pod_id     = cloudstack_pod.pod.id
    cluster_id = cloudstack_cluster.cluster.id
  }
}