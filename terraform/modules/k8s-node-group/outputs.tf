output "node_group_id" {
  value = yandex_kubernetes_node_group.this.id
}

output "node_count" {
  value = yandex_kubernetes_node_group.this.scale_policy[0].fixed_scale[0].size
}
