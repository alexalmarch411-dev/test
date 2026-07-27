resource "yandex_vpc_network" "this" {
  name        = var.network_name
  description = "Managed by Terraform"
  labels      = var.tags
}

resource "yandex_vpc_subnet" "public" {
  count          = length(var.public_subnets)
  name           = "${var.network_name}-public-${count.index}"
  v4_cidr_blocks = [var.public_subnets[count.index]]
  zone           = var.zones[count.index % length(var.zones)]
  network_id     = yandex_vpc_network.this.id
  labels         = var.tags
}

resource "yandex_vpc_subnet" "private" {
  count          = length(var.private_subnets)
  name           = "${var.network_name}-private-${count.index}"
  v4_cidr_blocks = [var.private_subnets[count.index]]
  zone           = var.zones[count.index % length(var.zones)]
  network_id     = yandex_vpc_network.this.id
  route_table_id = yandex_vpc_route_table.nat.id
  labels         = var.tags
}

resource "yandex_vpc_gateway" "nat" {
  name        = "${var.network_name}-nat"
  labels      = var.tags
  shared_egress_gateway {}
}

resource "yandex_vpc_route_table" "nat" {
  name       = "${var.network_name}-nat-rt"
  network_id = yandex_vpc_network.this.id
  labels     = var.tags

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat.id
  }
}

resource "yandex_vpc_security_group" "nat" {
  name        = "${var.network_name}-nat-sg"
  network_id  = yandex_vpc_network.this.id
  description = "NAT instance security group"
  labels      = var.tags

  ingress {
    protocol       = "TCP"
    port           = 0
    v4_cidr_blocks = var.private_subnets
    description    = "Allow all traffic from private subnets to NAT"
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    description    = "Allow all outbound traffic"
  }
}

resource "yandex_vpc_security_group" "k8s_master" {
  name        = "${var.network_name}-k8s-master-sg"
  network_id  = yandex_vpc_network.this.id
  description = "Kubernetes master security group"
  labels      = var.tags

  ingress {
    protocol       = "TCP"
    port           = 443
    v4_cidr_blocks = ["0.0.0.0/0"]
    description    = "Kubernetes API"
  }

  ingress {
    protocol       = "TCP"
    port           = 6443
    v4_cidr_blocks = ["0.0.0.0/0"]
    description    = "Kubernetes API (alternative)"
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    description    = "Allow all outbound traffic"
  }
}

resource "yandex_vpc_security_group" "k8s_nodes" {
  name        = "${var.network_name}-k8s-nodes-sg"
  network_id  = yandex_vpc_network.this.id
  description = "Kubernetes nodes security group"
  labels      = var.tags

  ingress {
    protocol       = "TCP"
    port           = 0
    v4_cidr_blocks = var.public_subnets
    description    = "Allow traffic from public subnets"
  }

  ingress {
    protocol       = "TCP"
    port           = 0
    v4_cidr_blocks = var.private_subnets
    description    = "Allow traffic from private subnets"
  }

  ingress {
    protocol          = "ANY"
    predefined_target = "self_security_group"
    description       = "Allow traffic within the group"
  }

  ingress {
    protocol          = "TCP"
    port              = 10250
    security_group_id = yandex_vpc_security_group.k8s_master.id
    description       = "Allow kubelet from master"
  }

  ingress {
    protocol          = "TCP"
    port              = 0
    security_group_id = yandex_vpc_security_group.k8s_master.id
    description       = "Allow all traffic from master to nodes"
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    description    = "Allow all outbound traffic"
  }
}
