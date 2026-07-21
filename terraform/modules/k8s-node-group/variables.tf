variable "node_group_name" {
  description = "Node group name"
  type        = string
}

variable "cluster_id" {
  description = "Kubernetes cluster ID"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version for nodes"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for nodes"
  type        = list(string)
}

variable "zone" {
  description = "Availability zone"
  type        = string
}

variable "platform_id" {
  description = "Platform ID (e.g. standard-v3)"
  type        = string
  default     = "standard-v3"
}

variable "cores" {
  description = "Number of CPU cores"
  type        = number
  default     = 4
}

variable "memory" {
  description = "Memory in GB"
  type        = number
  default     = 16
}

variable "core_fraction" {
  description = "Core fraction (0, 5, 20, 50, 100)"
  type        = number
  default     = 100
}

variable "disk_size" {
  description = "Boot disk size in GB"
  type        = number
  default     = 64
}

variable "disk_type" {
  description = "Boot disk type"
  type        = string
  default     = "network-ssd"
}

variable "node_count" {
  description = "Number of nodes"
  type        = number
  default     = 3
}

variable "nat" {
  description = "Whether to assign public IPs"
  type        = bool
  default     = false
}

variable "preemptible" {
  description = "Whether to use preemptible instances"
  type        = bool
  default     = false
}

variable "security_group_ids" {
  description = "Security group IDs for nodes"
  type        = list(string)
  default     = []
}

variable "labels" {
  description = "Node group labels"
  type        = map(string)
  default     = {}
}

variable "auto_upgrade" {
  description = "Enable auto upgrade"
  type        = bool
  default     = true
}

variable "auto_repair" {
  description = "Enable auto repair"
  type        = bool
  default     = true
}
