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
# 2. CORE INFRASTRUCTURE
################################################################################

resource "cloudstack_zone" "zone" {
  name               = var.zone_name
  network_type       = "Advanced"
  guest_cidr_address = var.guest_cidr

  dns1 = "8.8.8.8"
  dns2 = "8.8.4.4"

  internal_dns1 = "8.8.8.8"
  internal_dns2 = "8.8.4.4"

  allocation_state = "Enabled"
}

resource "cloudstack_pod" "pod" {
  name    = var.pod_name
  zone_id = cloudstack_zone.zone.id

  gateway  = var.pod_gateway
  netmask  = var.pod_netmask
  start_ip = var.pod_start_ip
  end_ip   = var.pod_end_ip
}

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
# 3. STORAGE
################################################################################

resource "cloudstack_storage_pool" "local" {
  name       = "local-primary"
  zone_id    = cloudstack_zone.zone.id
  pod_id     = cloudstack_pod.pod.id
  cluster_id = cloudstack_cluster.cluster.id

  scope            = "CLUSTER"
  storage_provider = "defaultprimary"
  hypervisor       = "KVM"
  url              = "local:///"
}

resource "cloudstack_secondary_storage" "secondary" {
  zone_id          = cloudstack_zone.zone.id
  storage_provider = "nfs"
  url              = "nfs://${var.secondary_nfs_ip}/${trim(var.secondary_nfs_path, "/")}"
}

################################################################################
# 4. OUTPUTS
################################################################################

output "summary" {
  value = {
    zone_id    = cloudstack_zone.zone.id
    pod_id     = cloudstack_pod.pod.id
    cluster_id = cloudstack_cluster.cluster.id
  }
}