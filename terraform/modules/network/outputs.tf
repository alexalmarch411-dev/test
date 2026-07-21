output "network_id" {
  value = yandex_vpc_network.this.id
}

output "public_subnet_ids" {
  value = yandex_vpc_subnet.public[*].id
}

output "private_subnet_ids" {
  value = yandex_vpc_subnet.private[*].id
}

output "k8s_master_sg_id" {
  value = yandex_vpc_security_group.k8s_master.id
}

output "k8s_nodes_sg_id" {
  value = yandex_vpc_security_group.k8s_nodes.id
}
