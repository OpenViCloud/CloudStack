################################################################################
# 1. TERRAFORM & PROVIDER CONFIGURATION
################################################################################
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    cloudstack = {
      source  = "cloudstack/cloudstack"
      version = "~> 0.4"
    }
  }
}

provider "cloudstack" {
  api_url    = var.api_url
  api_key    = var.api_key
  secret_key = var.secret_key
}

################################################################################
# 2. CORE INFRASTRUCTURE (ZONE -> POD -> CLUSTER)
################################################################################

# --- Zone ---
resource "cloudstack_zone" "zone" {
  name               = var.zone_name
  network_type       = "Advanced"
  guest_cidr_address = "10.1.0.0/16"
  dns1               = "8.8.8.8"
  dns2               = "8.8.4.4"
  allocation_state   = "Enabled"
}

# --- Pod ---
resource "cloudstack_pod" "pod" {
  name     = var.pod_name
  zone_id  = cloudstack_zone.zone.id
  cidr     = "10.1.1.0/24"
  gateway  = "10.1.1.1"
  start_ip = "10.1.1.10"
  end_ip   = "10.1.1.200"
}

# --- Cluster ---
resource "cloudstack_cluster" "cluster" {
  name         = var.cluster_name
  zone_id      = cloudstack_zone.zone.id
  pod_id       = cloudstack_pod.pod.id
  hypervisor   = "KVM"
  cluster_type = "CloudManaged"
}

################################################################################
# 3. STORAGE RESOURCES
################################################################################

# --- Primary Storage (Local Disk) ---
resource "cloudstack_primary_storage" "local" {
  name         = "local-primary"
  zone_id      = cloudstack_zone.zone.id
  cluster_id   = cloudstack_cluster.cluster.id
  scope        = "CLUSTER"
  storage_type = "Local"
  url          = "local"
}

# --- Secondary Storage (NFS) ---
resource "cloudstack_secondary_storage" "secondary" {
  zone_id = cloudstack_zone.zone.id
  url     = "nfs://${var.secondary_nfs_ip}${var.secondary_nfs_path}"
}

################################################################################
# 4. VARIABLES & OUTPUTS
################################################################################

# Connection Variables
variable "api_url"    { type = string }
variable "api_key"    { type = string; sensitive = true }
variable "secret_key" { type = string; sensitive = true }

# Naming Variables
variable "zone_name"    { default = "lab-zone" }
variable "pod_name"     { default = "lab-pod" }
variable "cluster_name" { default = "lab-cluster" }

# Storage Variables
variable "secondary_nfs_ip"   { type = string }
variable "secondary_nfs_path" { default = "/export/secondary" }

# Outputs
output "summary" {
  value = {
    zone_id    = cloudstack_zone.zone.id
    pod_id     = cloudstack_pod.pod.id
    cluster_id = cloudstack_cluster.cluster.id
  }
}
