variable "network_name" {
  description = "VPC network name"
  type        = string
  default     = "prod"
}

variable "cluster_name" {
  description = "Kubernetes cluster name"
  type        = string
  default     = "prod-cluster"
}

variable "zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["ru-central1-a", "ru-central1-b", "ru-central1-d"]
}

variable "public_subnets" {
  description = "Public subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_subnets" {
  description = "Private subnet CIDR blocks"
  type        = list(string)
  default     = ["10.10.1.0/24", "10.10.2.0/24", "10.10.3.0/24"]
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

variable "node_cores" {
  description = "Number of CPU cores per node"
  type        = number
  default     = 4
}

variable "node_memory" {
  description = "Memory per node in GB"
  type        = number
  default     = 8
}

variable "node_disk_size" {
  description = "Boot disk size per node in GB"
  type        = number
  default     = 64
}

variable "node_count" {
  description = "Number of worker nodes"
  type        = number
  default     = 3
}

variable "image_tag" {
  description = "Docker image tag to deploy"
  type        = string
  default     = "latest"
}

variable "preemptible" {
  description = "Use preemptible instances"
  type        = bool
  default     = false
}
