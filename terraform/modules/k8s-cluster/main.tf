resource "yandex_kubernetes_cluster" "this" {
  name       = var.cluster_name
  network_id = var.network_id
  labels     = var.labels

  master {
    version   = var.kubernetes_version
    public_ip = var.master_public

    zonal {
      zone      = var.master_zone
      subnet_id = var.master_subnet_id
    }

    security_group_ids = var.master_security_group_ids
  }

  service_account_id      = var.service_account_id
  node_service_account_id = var.node_service_account_id

  release_channel = var.release_channel

  depends_on = [var.network_id]
}
