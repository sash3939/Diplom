#Создание пустой VPC
resource "yandex_vpc_network" "vpc0" {
  name = var.vpc_name
}

#-----------------revision------------

# Создание подсетей в VPC
resource "yandex_vpc_subnet" "subnets" {
  for_each = var.subnets

  name           = each.key
  zone           = each.value.zone
  network_id     = yandex_vpc_network.vpc0.id
  v4_cidr_blocks = [each.value.cidr_block]
}

#----------end revision------------
