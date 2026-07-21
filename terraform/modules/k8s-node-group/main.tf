resource "yandex_kubernetes_node_group" "this" {
  name        = var.node_group_name
  cluster_id  = var.cluster_id
  version     = var.kubernetes_version
  labels      = var.labels

  instance_template {
    platform_id = var.platform_id

    resources {
      cores         = var.cores
      memory        = var.memory
      core_fraction = var.core_fraction
    }

    boot_disk {
      size = var.disk_size
      type = var.disk_type
    }

    network_interface {
      subnet_ids         = var.subnet_ids
      nat                = var.nat
      security_group_ids = var.security_group_ids
    }

    scheduling_policy {
      preemptible = var.preemptible
    }
  }

  scale_policy {
    fixed_scale {
      size = var.node_count
    }
  }

  allocation_policy {
    location {
      zone = var.zone
    }
  }

  maintenance_policy {
    auto_upgrade = var.auto_upgrade
    auto_repair  = var.auto_repair
  }
}
