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

variable "zone_name" { default = "lab-zone" }
variable "pod_name" { default = "lab-pod" }
variable "cluster_name" { default = "lab-cluster" }

variable "guest_cidr" { default = "10.1.0.0/16" }

variable "pod_gateway" {
  default = "10.2.1.1"
}

variable "pod_netmask" {
  default = "255.255.255.0"
}

variable "pod_start_ip" {
  default = "10.2.1.10"
}

variable "pod_end_ip" {
  default = "10.2.1.200"
}

variable "secondary_nfs_ip" { 
  type = string 
}
variable "secondary_nfs_path" { 
  default = "/export/secondary" 
}