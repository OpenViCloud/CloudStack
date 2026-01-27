variable "api_url" {
  description = "CloudStack API endpoint"
  type        = string
}

variable "api_key" {
  description = "CloudStack API key"
  type        = string
  sensitive   = true
}

variable "secret_key" {
  description = "CloudStack secret key"
  type        = string
  sensitive   = true
}

variable "zone_name" {
  description = "CloudStack zone name"
  type        = string
  default     = "lab-zone"
}

variable "ceph_mon_ip" {
  description = "Ceph MON IP address"
  type        = string
}

variable "ceph_key" {
  description = "Ceph client.cloudstack key"
  type        = string
  sensitive   = true
}

variable "secondary_nfs_ip" {
  description = "Secondary storage NFS server IP"
  type        = string
}

variable "secondary_nfs_path" {
  description = "Secondary storage NFS export path"
  type        = string
  default     = "/exports/secondary"
}
