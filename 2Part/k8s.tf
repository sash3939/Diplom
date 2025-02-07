locals {
  folder_id   = var.folder_id
}

resource "yandex_kubernetes_cluster" "k8s-regional" {
  name = "k8s-regional"
  network_id = yandex_vpc_network.vpc0.id
  master {
    regional {
      region = "ru-central1"

      location {
        zone      = "${yandex_vpc_subnet.subnet-a.zone}"
        subnet_id = "${yandex_vpc_subnet.subnet-a.id}"
      }

      location {
        zone      = "${yandex_vpc_subnet.subnet-b.zone}"
        subnet_id = "${yandex_vpc_subnet.subnet-b.id}"
      }

      location {
        zone      = "${yandex_vpc_subnet.subnet-d.zone}"
        subnet_id = "${yandex_vpc_subnet.subnet-d.id}"
      }
    }

    security_group_ids = ["${yandex_vpc_security_group.k8s-main-sg.id}", "${yandex_vpc_security_group.k8s-master-whitelist.id}"]
  
    version   = "1.28"
    public_ip = true
  
    master_logging {
      enabled = true
      folder_id = "${var.folder_id}"
      kube_apiserver_enabled = true
      cluster_autoscaler_enabled = true
      events_enabled = true
      audit_enabled = true
    }
  }
  service_account_id      = yandex_iam_service_account.kuber.id
  node_service_account_id = yandex_iam_service_account.kuber.id
  
  depends_on = [
    yandex_resourcemanager_folder_iam_member.kuber-admin,
    yandex_resourcemanager_folder_iam_member.k8s-clusters-agent,
    yandex_resourcemanager_folder_iam_member.vpc-public-admin,
    yandex_resourcemanager_folder_iam_member.images-puller,
    yandex_resourcemanager_folder_iam_member.encrypterDecrypter
  ]
  kms_provider {
    key_id = yandex_kms_symmetric_key.kms-key.id
  }
  labels = {
    "custom-label" = "master-1"
  }
}

#----------------------Nodes---------------

# Create worker-nodes-a
resource "yandex_kubernetes_node_group" "worker-nodes-a" {
  cluster_id = "${yandex_kubernetes_cluster.k8s-regional.id}"
  name       = "worker-nodes-a"
  version    = "1.28"
  instance_template {
    metadata = {
      ssh-keys = "debian:${local.ssh-keys}"
      serial-port-enable = "1"
    }    
    platform_id = "standard-v2"

    network_interface {
      nat                = true
      subnet_ids         = ["${yandex_vpc_subnet.subnet-a.id}"]
      security_group_ids = [
        "${yandex_vpc_security_group.k8s-main-sg.id}",
        "${yandex_vpc_security_group.k8s-nodes-ssh-access.id}"
      ]
    }

    resources {
      memory = 6
      cores  = 2
    }

    boot_disk {
      type = "network-hdd"
      size = 64
    }

    container_runtime {
      type = "containerd"
    }
  }

  scale_policy {
    fixed_scale {
      size = 1
  }
  }

  allocation_policy {
    location {
      zone = "${yandex_vpc_subnet.subnet-a.zone}"
    }
  }
  labels = {
    "custom-label" = "worker-1"
  }
}


# Create worker-nodes-b
resource "yandex_kubernetes_node_group" "worker-nodes-b" {
  cluster_id = "${yandex_kubernetes_cluster.k8s-regional.id}"
  name       = "worker-nodes-b"
  version    = "1.28"
  instance_template {
    metadata = {
      ssh-keys = "debian:${local.ssh-keys}"
      serial-port-enable = "1"
    }
    platform_id = "standard-v2"

    network_interface {
      nat                = true
      subnet_ids         = ["${yandex_vpc_subnet.subnet-b.id}"]
      security_group_ids = [
        "${yandex_vpc_security_group.k8s-main-sg.id}",
        "${yandex_vpc_security_group.k8s-nodes-ssh-access.id}",
      ]
    }

    resources {
      memory = 6
      cores  = 2
    }

    boot_disk {
      type = "network-hdd"
      size = 64
    }

    container_runtime {
      type = "containerd"
    }
  }

  scale_policy {
    fixed_scale {
      size = 1
  }
  }

  allocation_policy {
    location {
      zone = "${yandex_vpc_subnet.subnet-b.zone}"
    }
  }
  labels = {
    "custom-label" = "worker-2"
  }
}

# Create worker-nodes-d
resource "yandex_kubernetes_node_group" "worker-nodes-d" {
  cluster_id = "${yandex_kubernetes_cluster.k8s-regional.id}"
  name       = "worker-nodes-d"
  version    = "1.28"
  instance_template {
    metadata = {
      ssh-keys = "debian:${local.ssh-keys}"
      serial-port-enable = "1"
    }
    platform_id = "standard-v2"

    network_interface {
      nat                = true
      subnet_ids         = ["${yandex_vpc_subnet.subnet-d.id}"]
      security_group_ids = [
        "${yandex_vpc_security_group.k8s-main-sg.id}",
        "${yandex_vpc_security_group.k8s-nodes-ssh-access.id}",
      ]
    }

    resources {
      memory = 6
      cores  = 2
    }

    boot_disk {
      type = "network-hdd"
      size = 64
    }

    container_runtime {
      type = "containerd"
    }
  }

  scale_policy {
    fixed_scale {
      size = 1
  }
  }

  allocation_policy {
    location {
      zone = "${yandex_vpc_subnet.subnet-d.zone}"
    }
  }
  labels = {
    "custom-label" = "worker-2"
  }
}
