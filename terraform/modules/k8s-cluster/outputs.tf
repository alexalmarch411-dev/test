output "cluster_id" {
  value = yandex_kubernetes_cluster.this.id
}

output "cluster_name" {
  value = yandex_kubernetes_cluster.this.name
}

output "master_endpoint" {
  value = yandex_kubernetes_cluster.this.master[0].external_v4_endpoint
}

output "master_ca_cert" {
  value = yandex_kubernetes_cluster.this.master[0].cluster_ca_certificate
}

output "kubeconfig" {
  value = yandex_kubernetes_cluster.this.master[0].cluster_ca_certificate
  sensitive = true
}
