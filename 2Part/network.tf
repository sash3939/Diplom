#Создание пустой VPC
resource "yandex_vpc_network" "vpc0" {
  name = var.vpc_name
}

#Создадим в VPC subnet c названием subnet-a
resource "yandex_vpc_subnet" "subnet-a" {
  name           = var.subnet-a
  zone           = var.zone-a
  network_id     = yandex_vpc_network.vpc0.id
  v4_cidr_blocks = var.cidr-a
}

#Создание в VPC subnet с названием subnet-b
resource "yandex_vpc_subnet" "subnet-b" {
  name           = var.subnet-b
  zone           = var.zone-b
  network_id     = yandex_vpc_network.vpc0.id
  v4_cidr_blocks = var.cidr-b
}

#Создание в VPC subnet с названием subnet-d
resource "yandex_vpc_subnet" "subnet-d" {
  name           = var.subnet-d
  zone           = var.zone-d
  network_id     = yandex_vpc_network.vpc0.id
  v4_cidr_blocks = var.cidr-d
}



locals {
  domain_name = "kms-netology.ru."

  # The following settings are predefined. Change them only if necessary.
  zone_name       = "my-public-zone" # Name of the public DNS zone
  ip_address_name = "my-ip-address" # Name of the static public IP address
}

resource "yandex_vpc_address" "addr" {
  name = local.ip_address_name
  external_ipv4_address {
    zone_id = "ru-central1-a"
  }
}

resource "yandex_dns_zone" "public" {
  name        = local.zone_name
  description = "Public DNS zone"
  zone        = local.domain_name
  public      = true
}

resource "yandex_dns_recordset" "record" {
  zone_id = yandex_dns_zone.public.id
  name    = local.domain_name
  type    = "A"
  ttl     = 600
  data    = [yandex_kubernetes_cluster.k8s-regional.master.0.external_v4_address]
}
