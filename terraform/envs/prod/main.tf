provider "yandex" {
  zone = var.zones[0]
}

locals {
  tags = {
    environment = "prod"
    managed-by  = "terraform"
    project     = var.cluster_name
  }
}

module "network" {
  source = "../../modules/network"

  network_name    = var.network_name
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
  zones           = var.zones
  tags            = local.tags
}

module "k8s_cluster" {
  source = "../../modules/k8s-cluster"

  cluster_name              = var.cluster_name
  network_id                = module.network.network_id
  master_zone               = var.zones[0]
  master_subnet_id          = module.network.public_subnet_ids[0]
  master_security_group_ids = [module.network.k8s_master_sg_id]
  service_account_id        = var.service_account_id
  node_service_account_id   = var.node_service_account_id
  kubernetes_version        = var.kubernetes_version
  master_public             = true
  labels                    = local.tags
}

module "k8s_node_group" {
  source = "../../modules/k8s-node-group"

  node_group_name    = "${var.cluster_name}-workers"
  cluster_id         = module.k8s_cluster.cluster_id
  kubernetes_version = var.kubernetes_version
  subnet_ids         = [module.network.private_subnet_ids[0]]
  zone               = var.zones[0]

  cores       = var.node_cores
  memory      = var.node_memory
  disk_size   = var.node_disk_size
  node_count  = var.node_count
  nat         = false
  preemptible = var.preemptible

  security_group_ids = [module.network.k8s_nodes_sg_id]
  labels             = local.tags
}

resource "yandex_container_registry" "app" {
  name   = "${var.cluster_name}-registry"
  labels = local.tags
}

data "yandex_client_config" "client" {}

provider "helm" {
  kubernetes {
    host                   = module.k8s_cluster.master_endpoint
    cluster_ca_certificate = module.k8s_cluster.master_ca_cert
    token                  = data.yandex_client_config.client.iam_token
  }
}

resource "helm_release" "app" {
  name       = "myapp"
  chart      = "${path.module}/../../../helm/app-stack"
  depends_on = [module.k8s_node_group]

  set {
    name  = "web.image.repository"
    value = "cr.yandex/${yandex_container_registry.app.id}/app_python-app"
  }

  set {
    name  = "web.image.tag"
    value = var.image_tag
  }

  timeout = 600
}
