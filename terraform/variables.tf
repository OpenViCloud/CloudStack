################################################################################
# 4. VARIABLES
################################################################################

variable "api_url" { type = string }

variable "api_key" {
  type      = string
  sensitive = true
}

variable "secret_key" {
  type      = string
  sensitive = true
}

variable "zone_name" { default = "vn-hcm-zone" }
variable "pod_name" { default = "vn-hcm-pod" }
variable "cluster_name" { default = "vn-hcm-01-kvmcluster" }

variable "guest_cidr" { default = "10.1.0.0/16" }

variable "pod_gateway" {
  default = "192.168.0.1"
}

variable "pod_netmask" {
  default = "255.255.255.0"
}

variable "pod_start_ip" {
  default = "192.168.0.150"
}

variable "pod_end_ip" {
  default = "192.168.0.200"
}

variable "nfs_ip" {
  type = string
}
variable "secondary_nfs_path" {
  default = "/export/secondary"
}

variable "primary_nfs_path" {
  default = "/export/primary"
}

variable "kvm_host_ip" { default = "" }
variable "kvm_host_user" { default = "" }
variable "kvm_host_password" { default = "" }

