############################################
# Zone
############################################
resource "cloudstack_zone" "zone" {
  name               = var.zone_name
  network_type       = "Advanced"
  guest_cidr_address = "10.1.0.0/16"

  dns1 = "8.8.8.8"
  dns2 = "8.8.4.4"

  allocation_state = "Enabled"
}

############################################
# Pod
############################################
resource "cloudstack_pod" "pod" {
  name    = var.pod_name
  zone_id = cloudstack_zone.zone.id

  cidr     = "10.1.1.0/24"
  gateway  = "10.1.1.1"
  start_ip = "10.1.1.10"
  end_ip   = "10.1.1.200"
}

############################################
# Cluster
############################################
resource "cloudstack_cluster" "cluster" {
  name         = var.cluster_name
  zone_id      = cloudstack_zone.zone.id
  pod_id       = cloudstack_pod.pod.id
  hypervisor   = "KVM"
  cluster_type = "CloudManaged"
}

############################################
# Primary Storage - Ceph RBD
############################################
resource "cloudstack_primary_storage" "ceph" {
  name       = "ceph-primary"
  zone_id    = cloudstack_zone.zone.id
  cluster_id = cloudstack_cluster.cluster.id

  scope        = "CLUSTER"
  storage_type = "RBD"

  details = {
    monHosts = var.ceph_mon_hosts   # vd: 10.0.0.11,10.0.0.12,10.0.0.13
    pool     = var.ceph_pool        # vd: rbd
    user     = "cloudstack"
    secret   = var.ceph_secret_uuid
  }
}

############################################
# Secondary Storage - NFS
############################################
resource "cloudstack_secondary_storage" "secondary" {
  zone_id = cloudstack_zone.zone.id
  url     = "nfs://${var.nfs_secondary_server}${var.nfs_secondary_path}"
}
