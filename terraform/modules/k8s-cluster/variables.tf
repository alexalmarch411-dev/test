variable "cluster_name" {
  description = "Kubernetes cluster name"
  type        = string
}

variable "network_id" {
  description = "VPC network ID"
  type        = string
}

variable "master_zone" {
  description = "Availability zone for the master"
  type        = string
}

variable "master_subnet_id" {
  description = "Subnet ID for the master"
  type        = string
}

variable "master_public" {
  description = "Whether the master has a public IP"
  type        = bool
  default     = true
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.33"
}

variable "service_account_id" {
  description = "Service account ID for the cluster"
  type        = string
}

variable "node_service_account_id" {
  description = "Service account ID for nodes"
  type        = string
}

variable "release_channel" {
  description = "Release channel (RAPID, REGULAR, STABLE)"
  type        = string
  default     = "REGULAR"
}

variable "master_security_group_ids" {
  description = "Security group IDs for the master"
  type        = list(string)
  default     = []
}

variable "labels" {
  description = "Kubernetes cluster labels"
  type        = map(string)
  default     = {}
}
