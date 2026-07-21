output "cluster_id" {
  value = module.k8s_cluster.cluster_id
}

output "cluster_name" {
  value = module.k8s_cluster.cluster_name
}

output "master_endpoint" {
  value = module.k8s_cluster.master_endpoint
}

output "network_id" {
  value = module.network.network_id
}

output "node_group_id" {
  value = module.k8s_node_group.node_group_id
}

output "registry_id" {
  value = yandex_container_registry.app.id
}

output "registry_image" {
  value = "cr.yandex/${yandex_container_registry.app.id}/app_python-app"
}

resource "local_file" "kubeconfig" {
  content  = module.k8s_cluster.kubeconfig
  filename = "${path.module}/kubeconfig"
}
