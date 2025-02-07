# Создание Kubernetes кластера
<details>
	<summary></summary>
      <br>

На этом этапе необходимо создать [Kubernetes](https://kubernetes.io/ru/docs/concepts/overview/what-is-kubernetes/) кластер на базе предварительно созданной инфраструктуры.   Требуется обеспечить доступ к ресурсам из Интернета.

Это можно сделать двумя способами:

1. Рекомендуемый вариант: самостоятельная установка Kubernetes кластера.
   а. При помощи Terraform подготовить как минимум 3 виртуальных машины Compute Cloud для создания Kubernetes-кластера. Тип виртуальной машины следует выбрать самостоятельно с учётом требовании к производительности и стоимости. Если в дальнейшем поймете, что необходимо сменить тип инстанса, используйте Terraform для внесения изменений.  
   б. Подготовить [ansible](https://www.ansible.com/) конфигурации, можно воспользоваться, например [Kubespray](https://kubernetes.io/docs/setup/production-environment/tools/kubespray/)  
   в. Задеплоить Kubernetes на подготовленные ранее инстансы, в случае нехватки каких-либо ресурсов вы всегда можете создать их при помощи Terraform.
2. Альтернативный вариант: воспользуйтесь сервисом [Yandex Managed Service for Kubernetes](https://cloud.yandex.ru/services/managed-kubernetes)  
  а. С помощью terraform resource для [kubernetes](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/kubernetes_cluster) создать **региональный** мастер kubernetes с размещением нод в разных 3 подсетях      
  б. С помощью terraform resource для [kubernetes node group](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/kubernetes_node_group)

Ожидаемый результат:

1. Работоспособный Kubernetes кластер.
2. В файле `~/.kube/config` находятся данные для доступа к кластеру.
3. Команда `kubectl get pods --all-namespaces` отрабатывает без ошибок.

</details>

---
## Решение:

На этом этапе создадим `Kubernetes` кластер на базе предварительно созданной инфраструктуры.

### 2.1. При помощи [Terraform](./terraform) 3 виртуальные машины в Yandex Managed Kubernetes Cluster для создания Kubernetes-кластера: 1 Cluster и 3 Worker-node. Также создадим сервисные аккаунты и назначим им роли. Создадим бакет и сетевую инфраструктуру для Кубернетес
<details>
	<summary></summary>
      <br>

```bash
root@ubuntu-VirtualBox:/home/ubuntu/Diplom2/2Part# terraform apply
Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # yandex_iam_service_account.kuber will be created
  + resource "yandex_iam_service_account" "kuber" {
      + created_at  = (known after apply)
      + description = "service account to manage VMs"
      + folder_id   = "b1gc36q9v49llnddjkvr"
      + id          = (known after apply)
      + name        = "kuber"
    }

  # yandex_iam_service_account.service will be created
  + resource "yandex_iam_service_account" "service" {
      + created_at  = (known after apply)
      + description = "service account to manage VMs"
      + folder_id   = "b1gc36q9v49llnddjkvr"
      + id          = (known after apply)
      + name        = "egorkin-ae"
    }

  # yandex_iam_service_account_static_access_key.terraform_service_account_key will be created
  + resource "yandex_iam_service_account_static_access_key" "terraform_service_account_key" {
      + access_key                   = (known after apply)
      + created_at                   = (known after apply)
      + description                  = "static access key for object storage"
      + encrypted_secret_key         = (known after apply)
      + id                           = (known after apply)
      + key_fingerprint              = (known after apply)
      + output_to_lockbox_version_id = (known after apply)
      + secret_key                   = (sensitive value)
      + service_account_id           = (known after apply)
    }

  # yandex_iam_service_account_static_access_key.terraform_service_account_key_k8s will be created
  + resource "yandex_iam_service_account_static_access_key" "terraform_service_account_key_k8s" {
      + access_key                   = (known after apply)
      + created_at                   = (known after apply)
      + description                  = "static access key for object storage"
      + encrypted_secret_key         = (known after apply)
      + id                           = (known after apply)
      + key_fingerprint              = (known after apply)
      + output_to_lockbox_version_id = (known after apply)
      + secret_key                   = (sensitive value)
      + service_account_id           = (known after apply)
    }

  # yandex_kms_symmetric_key.kms-key will be created
  + resource "yandex_kms_symmetric_key" "kms-key" {
      + created_at          = (known after apply)
      + default_algorithm   = "AES_256"
      + deletion_protection = false
      + folder_id           = (known after apply)
      + id                  = (known after apply)
      + name                = "kms-key"
      + rotated_at          = (known after apply)
      + rotation_period     = "8760h"
      + status              = (known after apply)
    }

  # yandex_kubernetes_cluster.k8s-regional will be created
  + resource "yandex_kubernetes_cluster" "k8s-regional" {
      + cluster_ipv4_range       = (known after apply)
      + cluster_ipv6_range       = (known after apply)
      + created_at               = (known after apply)
      + description              = (known after apply)
      + folder_id                = (known after apply)
      + health                   = (known after apply)
      + id                       = (known after apply)
      + labels                   = (known after apply)
      + log_group_id             = (known after apply)
      + name                     = "k8s-regional"
      + network_id               = (known after apply)
      + node_ipv4_cidr_mask_size = 24
      + node_service_account_id  = (known after apply)
      + release_channel          = (known after apply)
      + service_account_id       = (known after apply)
      + service_ipv4_range       = (known after apply)
      + service_ipv6_range       = (known after apply)
      + status                   = (known after apply)

      + kms_provider {
          + key_id = (known after apply)
        }

      + master {
          + cluster_ca_certificate = (known after apply)
          + etcd_cluster_size      = (known after apply)
          + external_v4_address    = (known after apply)
          + external_v4_endpoint   = (known after apply)
          + external_v6_endpoint   = (known after apply)
          + internal_v4_address    = (known after apply)
          + internal_v4_endpoint   = (known after apply)
          + public_ip              = true
          + security_group_ids     = (known after apply)
          + version                = "1.28"
          + version_info           = (known after apply)

          + master_logging {
              + audit_enabled              = true
              + cluster_autoscaler_enabled = true
              + enabled                    = true
              + events_enabled             = true
              + folder_id                  = "b1gc36q9v49llnddjkvr"
              + kube_apiserver_enabled     = true
            }

          + regional {
              + region = "ru-central1"

              + location {
                  + subnet_id = (known after apply)
                  + zone      = "ru-central1-a"
                }
              + location {
                  + subnet_id = (known after apply)
                  + zone      = "ru-central1-b"
                }
              + location {
                  + subnet_id = (known after apply)
                  + zone      = "ru-central1-d"
                }
            }
        }
    }

  # yandex_kubernetes_node_group.worker-nodes-a will be created
  + resource "yandex_kubernetes_node_group" "worker-nodes-a" {
      + cluster_id        = (known after apply)
      + created_at        = (known after apply)
      + description       = (known after apply)
      + id                = (known after apply)
      + instance_group_id = (known after apply)
      + labels            = (known after apply)
      + name              = "worker-nodes-a"
      + status            = (known after apply)
      + version           = "1.28"
      + version_info      = (known after apply)

      + allocation_policy {
          + location {
              + subnet_id = (known after apply)
              + zone      = "ru-central1-a"
            }
        }

      + instance_template {
          + metadata                  = (known after apply)
          + nat                       = (known after apply)
          + network_acceleration_type = (known after apply)
          + platform_id               = "standard-v2"

          + boot_disk {
              + size = 64
              + type = "network-hdd"
            }

          + container_runtime {
              + type = "containerd"
            }

          + network_interface {
              + ipv4               = true
              + ipv6               = (known after apply)
              + nat                = true
              + security_group_ids = (known after apply)
              + subnet_ids         = (known after apply)
            }

          + resources {
              + core_fraction = (known after apply)
              + cores         = 2
              + gpus          = 0
              + memory        = 6
            }
        }

      + scale_policy {
          + fixed_scale {
              + size = 1
            }
        }
    }

  # yandex_kubernetes_node_group.worker-nodes-b will be created
  + resource "yandex_kubernetes_node_group" "worker-nodes-b" {
      + cluster_id        = (known after apply)
      + created_at        = (known after apply)
      + description       = (known after apply)
      + id                = (known after apply)
      + instance_group_id = (known after apply)
      + labels            = (known after apply)
      + name              = "worker-nodes-b"
      + status            = (known after apply)
      + version           = "1.28"
      + version_info      = (known after apply)

      + allocation_policy {
          + location {
              + subnet_id = (known after apply)
              + zone      = "ru-central1-b"
            }
        }

      + instance_template {
          + metadata                  = (known after apply)
          + nat                       = (known after apply)
          + network_acceleration_type = (known after apply)
          + platform_id               = "standard-v2"

          + boot_disk {
              + size = 64
              + type = "network-hdd"
            }

          + container_runtime {
              + type = "containerd"
            }

          + network_interface {
              + ipv4               = true
              + ipv6               = (known after apply)
              + nat                = true
              + security_group_ids = (known after apply)
              + subnet_ids         = (known after apply)
            }

          + resources {
              + core_fraction = (known after apply)
              + cores         = 2
              + gpus          = 0
              + memory        = 6
            }
        }

      + scale_policy {
          + fixed_scale {
              + size = 1
            }
        }
    }

  # yandex_kubernetes_node_group.worker-nodes-d will be created
  + resource "yandex_kubernetes_node_group" "worker-nodes-d" {
      + cluster_id        = (known after apply)
      + created_at        = (known after apply)
      + description       = (known after apply)
      + id                = (known after apply)
      + instance_group_id = (known after apply)
      + labels            = (known after apply)
      + name              = "worker-nodes-d"
      + status            = (known after apply)
      + version           = "1.28"
      + version_info      = (known after apply)

      + allocation_policy {
          + location {
              + subnet_id = (known after apply)
              + zone      = "ru-central1-d"
            }
        }

      + instance_template {
          + metadata                  = (known after apply)
          + nat                       = (known after apply)
          + network_acceleration_type = (known after apply)
          + platform_id               = "standard-v2"

          + boot_disk {
              + size = 64
              + type = "network-hdd"
            }

          + container_runtime {
              + type = "containerd"
            }

          + network_interface {
              + ipv4               = true
              + ipv6               = (known after apply)
              + nat                = true
              + security_group_ids = (known after apply)
              + subnet_ids         = (known after apply)
            }

          + resources {
              + core_fraction = (known after apply)
              + cores         = 2
              + gpus          = 0
              + memory        = 6
            }
        }

      + scale_policy {
          + fixed_scale {
              + size = 1
            }
        }
    }

  # yandex_resourcemanager_folder_iam_member.editor will be created
  + resource "yandex_resourcemanager_folder_iam_member" "editor" {
      + folder_id = "b1gc36q9v49llnddjkvr"
      + id        = (known after apply)
      + member    = (known after apply)
      + role      = "editor"
    }

  # yandex_resourcemanager_folder_iam_member.encrypterDecrypter will be created
  + resource "yandex_resourcemanager_folder_iam_member" "encrypterDecrypter" {
      + folder_id = "b1gc36q9v49llnddjkvr"
      + id        = (known after apply)
      + member    = (known after apply)
      + role      = "kms.keys.encrypterDecrypter"
    }

  # yandex_resourcemanager_folder_iam_member.images-puller will be created
  + resource "yandex_resourcemanager_folder_iam_member" "images-puller" {
      + folder_id = "b1gc36q9v49llnddjkvr"
      + id        = (known after apply)
      + member    = (known after apply)
      + role      = "container-registry.images.puller"
    }

  # yandex_resourcemanager_folder_iam_member.k8s-clusters-agent will be created
  + resource "yandex_resourcemanager_folder_iam_member" "k8s-clusters-agent" {
      + folder_id = "b1gc36q9v49llnddjkvr"
      + id        = (known after apply)
      + member    = (known after apply)
      + role      = "k8s.clusters.agent"
    }

  # yandex_resourcemanager_folder_iam_member.kuber-admin will be created
  + resource "yandex_resourcemanager_folder_iam_member" "kuber-admin" {
      + folder_id = "b1gc36q9v49llnddjkvr"
      + id        = (known after apply)
      + member    = (known after apply)
      + role      = "editor"
    }

  # yandex_resourcemanager_folder_iam_member.vpc-public-admin will be created
  + resource "yandex_resourcemanager_folder_iam_member" "vpc-public-admin" {
      + folder_id = "b1gc36q9v49llnddjkvr"
      + id        = (known after apply)
      + member    = (known after apply)
      + role      = "vpc.publicAdmin"
    }

  # yandex_storage_bucket.state_storage will be created
  + resource "yandex_storage_bucket" "state_storage" {
      + access_key            = (known after apply)
      + bucket                = (known after apply)
      + bucket_domain_name    = (known after apply)
      + default_storage_class = (known after apply)
      + folder_id             = (known after apply)
      + force_destroy         = false
      + id                    = (known after apply)
      + secret_key            = (sensitive value)
      + website_domain        = (known after apply)
      + website_endpoint      = (known after apply)

      + anonymous_access_flags {
          + list = false
          + read = false
        }
    }

  # yandex_storage_object.backend will be created
  + resource "yandex_storage_object" "backend" {
      + access_key   = (known after apply)
      + acl          = "private"
      + bucket       = (known after apply)
      + content_type = (known after apply)
      + id           = (known after apply)
      + key          = "terraform.tfstate"
      + secret_key   = (sensitive value)
      + source       = "./terraform.tfstate"
    }

  # yandex_vpc_network.vpc0 will be created
  + resource "yandex_vpc_network" "vpc0" {
      + created_at                = (known after apply)
      + default_security_group_id = (known after apply)
      + folder_id                 = (known after apply)
      + id                        = (known after apply)
      + labels                    = (known after apply)
      + name                      = "vpc0"
      + subnet_ids                = (known after apply)
    }

  # yandex_vpc_security_group.k8s-main-sg will be created
  + resource "yandex_vpc_security_group" "k8s-main-sg" {
      + created_at  = (known after apply)
      + description = "Правила группы обеспечивают базовую работоспособность кластера"
      + folder_id   = (known after apply)
      + id          = (known after apply)
      + labels      = (known after apply)
      + name        = "k8s-main-sg"
      + network_id  = (known after apply)
      + status      = (known after apply)

      + egress {
          + description       = "Правило разрешает весь исходящий трафик. Узлы могут связаться с Yandex Container Registry, Object Storage, Docker Hub и т.д."
          + from_port         = 0
          + id                = (known after apply)
          + labels            = (known after apply)
          + port              = -1
          + protocol          = "ANY"
          + to_port           = 65535
          + v4_cidr_blocks    = [
              + "0.0.0.0/0",
            ]
          + v6_cidr_blocks    = []
            # (2 unchanged attributes hidden)
        }

      + ingress {
          + description       = "Правило разрешает взаимодействие мастер-узел и узел-узел внутри группы безопасности."
          + from_port         = 0
          + id                = (known after apply)
          + labels            = (known after apply)
          + port              = -1
          + predefined_target = "self_security_group"
          + protocol          = "ANY"
          + to_port           = 65535
          + v4_cidr_blocks    = []
          + v6_cidr_blocks    = []
            # (1 unchanged attribute hidden)
        }
      + ingress {
          + description       = "Правило разрешает взаимодействие под-под и сервис-сервис. Указываем подсети нашего кластера и сервисов."
          + from_port         = 0
          + id                = (known after apply)
          + labels            = (known after apply)
          + port              = -1
          + protocol          = "ANY"
          + to_port           = 65535
          + v4_cidr_blocks    = [
              + "10.0.1.0/24",
              + "10.0.2.0/24",
              + "10.0.3.0/24",
            ]
          + v6_cidr_blocks    = []
            # (2 unchanged attributes hidden)
        }
      + ingress {
          + description       = "Правило разрешает входящий трафик из интернета на диапазон портов NodePort. Добавляем или изменяем порты на нужные нам."
          + from_port         = 30000
          + id                = (known after apply)
          + labels            = (known after apply)
          + port              = -1
          + protocol          = "TCP"
          + to_port           = 32767
          + v4_cidr_blocks    = [
              + "0.0.0.0/0",
            ]
          + v6_cidr_blocks    = []
            # (2 unchanged attributes hidden)
        }
      + ingress {
          + description       = "Правило разрешает отладочные ICMP-пакеты из внутренних подсетей."
          + from_port         = -1
          + id                = (known after apply)
          + labels            = (known after apply)
          + port              = -1
          + protocol          = "ICMP"
          + to_port           = -1
          + v4_cidr_blocks    = [
              + "172.16.0.0/12",
              + "10.0.0.0/8",
              + "192.168.0.0/16",
            ]
          + v6_cidr_blocks    = []
            # (2 unchanged attributes hidden)
        }
      + ingress {
          + description       = "Правило разрешает проверки доступности с диапазона адресов балансировщика нагрузки. Нужно для работы отказоустойчивого кластера и сервисов балансировщика."
          + from_port         = 0
          + id                = (known after apply)
          + labels            = (known after apply)
          + port              = -1
          + predefined_target = "loadbalancer_healthchecks"
          + protocol          = "TCP"
          + to_port           = 65535
          + v4_cidr_blocks    = []
          + v6_cidr_blocks    = []
            # (1 unchanged attribute hidden)
        }
    }

  # yandex_vpc_security_group.k8s-master-whitelist will be created
  + resource "yandex_vpc_security_group" "k8s-master-whitelist" {
      + created_at  = (known after apply)
      + description = "Правила группы разрешают доступ к API Kubernetes из интернета. Применяем правила только к кластеру."
      + folder_id   = (known after apply)
      + id          = (known after apply)
      + labels      = (known after apply)
      + name        = "k8s-master-whitelist"
      + network_id  = (known after apply)
      + status      = (known after apply)

      + ingress {
          + description       = "Правило разрешает подключение к API Kubernetes через порт 443 из указанной сети."
          + from_port         = -1
          + id                = (known after apply)
          + labels            = (known after apply)
          + port              = 443
          + protocol          = "TCP"
          + to_port           = -1
          + v4_cidr_blocks    = [
              + "0.0.0.0/0",
            ]
          + v6_cidr_blocks    = []
            # (2 unchanged attributes hidden)
        }
      + ingress {
          + description       = "Правило разрешает подключение к API Kubernetes через порт 6443 из указанной сети."
          + from_port         = -1
          + id                = (known after apply)
          + labels            = (known after apply)
          + port              = 6443
          + protocol          = "TCP"
          + to_port           = -1
          + v4_cidr_blocks    = [
              + "0.0.0.0/0",
            ]
          + v6_cidr_blocks    = []
            # (2 unchanged attributes hidden)
        }
    }

  # yandex_vpc_security_group.k8s-nodes-ssh-access will be created
  + resource "yandex_vpc_security_group" "k8s-nodes-ssh-access" {
      + created_at  = (known after apply)
      + description = "Правила группы разрешают подключение к узлам кластера по SSH. Применяем правила только для групп узлов."
      + folder_id   = (known after apply)
      + id          = (known after apply)
      + labels      = (known after apply)
      + name        = "k8s-nodes-ssh-access"
      + network_id  = (known after apply)
      + status      = (known after apply)

      + ingress {
          + description       = "Правило разрешает подключение к узлам по SSH с указанных IP-адресов."
          + from_port         = -1
          + id                = (known after apply)
          + labels            = (known after apply)
          + port              = 22
          + protocol          = "TCP"
          + to_port           = -1
          + v4_cidr_blocks    = [
              + "0.0.0.0/0",
            ]
          + v6_cidr_blocks    = []
            # (2 unchanged attributes hidden)
        }
    }

  # yandex_vpc_subnet.subnet-a will be created
  + resource "yandex_vpc_subnet" "subnet-a" {
      + created_at     = (known after apply)
      + folder_id      = (known after apply)
      + id             = (known after apply)
      + labels         = (known after apply)
      + name           = "subnet-a"
      + network_id     = (known after apply)
      + v4_cidr_blocks = [
          + "10.0.1.0/24",
        ]
      + v6_cidr_blocks = (known after apply)
      + zone           = "ru-central1-a"
    }

  # yandex_vpc_subnet.subnet-b will be created
  + resource "yandex_vpc_subnet" "subnet-b" {
      + created_at     = (known after apply)
      + folder_id      = (known after apply)
      + id             = (known after apply)
      + labels         = (known after apply)
      + name           = "subnet-b"
      + network_id     = (known after apply)
      + v4_cidr_blocks = [
          + "10.0.2.0/24",
        ]
      + v6_cidr_blocks = (known after apply)
      + zone           = "ru-central1-b"
    }

  # yandex_vpc_subnet.subnet-d will be created
  + resource "yandex_vpc_subnet" "subnet-d" {
      + created_at     = (known after apply)
      + folder_id      = (known after apply)
      + id             = (known after apply)
      + labels         = (known after apply)
      + name           = "subnet-d"
      + network_id     = (known after apply)
      + v4_cidr_blocks = [
          + "10.0.3.0/24",
        ]
      + v6_cidr_blocks = (known after apply)
      + zone           = "ru-central1-d"
    }

Plan: 24 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

yandex_kms_symmetric_key.kms-key: Creating...
yandex_iam_service_account.service: Creating...
yandex_vpc_network.vpc0: Creating...
yandex_iam_service_account.kuber: Creating...
yandex_kms_symmetric_key.kms-key: Creation complete after 2s [id=abjvlaec1o5vqpkrb7me]
yandex_vpc_network.vpc0: Creation complete after 4s [id=enp4fh739a6gclq59l26]
yandex_vpc_security_group.k8s-nodes-ssh-access: Creating...
yandex_vpc_subnet.subnet-a: Creating...
yandex_vpc_subnet.subnet-d: Creating...
yandex_vpc_security_group.k8s-master-whitelist: Creating...
yandex_vpc_subnet.subnet-b: Creating...
yandex_iam_service_account.kuber: Creation complete after 4s [id=ajeasvt1plj7h82u7hrv]
yandex_resourcemanager_folder_iam_member.encrypterDecrypter: Creating...
yandex_resourcemanager_folder_iam_member.k8s-clusters-agent: Creating...
yandex_resourcemanager_folder_iam_member.kuber-admin: Creating...
yandex_iam_service_account_static_access_key.terraform_service_account_key_k8s: Creating...
yandex_vpc_subnet.subnet-a: Creation complete after 1s [id=e9b1p54h2f2cmedsp30q]
yandex_resourcemanager_folder_iam_member.images-puller: Creating...
yandex_vpc_subnet.subnet-b: Creation complete after 1s [id=e2lpgi94siub1cfrmj9e]
yandex_resourcemanager_folder_iam_member.vpc-public-admin: Creating...
yandex_iam_service_account_static_access_key.terraform_service_account_key_k8s: Creation complete after 2s [id=aje5ndsfe1jglprd4ee1]
yandex_vpc_subnet.subnet-d: Creation complete after 2s [id=fl85j6o8hkdabgqbp1aq]
yandex_vpc_security_group.k8s-main-sg: Creating...
yandex_iam_service_account.service: Creation complete after 6s [id=aje83re6h448udfuuc8i]
yandex_resourcemanager_folder_iam_member.editor: Creating...
yandex_iam_service_account_static_access_key.terraform_service_account_key: Creating...
yandex_resourcemanager_folder_iam_member.encrypterDecrypter: Creation complete after 3s [id=b1gc36q9v49llnddjkvr/kms.keys.encrypterDecrypter/serviceAccount:ajeasvt1plj7h82u7hrv]
yandex_vpc_security_group.k8s-nodes-ssh-access: Creation complete after 3s [id=enpa31kkklsb88kn4m1u]
yandex_iam_service_account_static_access_key.terraform_service_account_key: Creation complete after 2s [id=ajej90ab4qd4gktptrve]
yandex_storage_bucket.state_storage: Creating...
yandex_resourcemanager_folder_iam_member.k8s-clusters-agent: Creation complete after 6s [id=b1gc36q9v49llnddjkvr/k8s.clusters.agent/serviceAccount:ajeasvt1plj7h82u7hrv]
yandex_vpc_security_group.k8s-master-whitelist: Creation complete after 7s [id=enpq351n8o7g7mthajkn]
yandex_resourcemanager_folder_iam_member.kuber-admin: Creation complete after 9s [id=b1gc36q9v49llnddjkvr/editor/serviceAccount:ajeasvt1plj7h82u7hrv]
yandex_resourcemanager_folder_iam_member.images-puller: Still creating... [10s elapsed]
yandex_resourcemanager_folder_iam_member.vpc-public-admin: Still creating... [10s elapsed]
yandex_vpc_security_group.k8s-main-sg: Still creating... [10s elapsed]
yandex_resourcemanager_folder_iam_member.editor: Still creating... [10s elapsed]
yandex_vpc_security_group.k8s-main-sg: Creation complete after 10s [id=enpg9idmaiu0d9dk19mm]
yandex_resourcemanager_folder_iam_member.images-puller: Creation complete after 11s [id=b1gc36q9v49llnddjkvr/container-registry.images.puller/serviceAccount:ajeasvt1plj7h82u7hrv]
yandex_resourcemanager_folder_iam_member.vpc-public-admin: Creation complete after 14s [id=b1gc36q9v49llnddjkvr/vpc.publicAdmin/serviceAccount:ajeasvt1plj7h82u7hrv]
yandex_kubernetes_cluster.k8s-regional: Creating...
yandex_resourcemanager_folder_iam_member.editor: Creation complete after 16s [id=b1gc36q9v49llnddjkvr/editor/serviceAccount:aje83re6h448udfuuc8i]
yandex_kubernetes_cluster.k8s-regional: Still creating... [10s elapsed]
yandex_kubernetes_cluster.k8s-regional: Still creating... [20s elapsed]
yandex_kubernetes_cluster.k8s-regional: Still creating... [30s elapsed]
yandex_kubernetes_cluster.k8s-regional: Still creating... [40s elapsed]
yandex_kubernetes_cluster.k8s-regional: Still creating... [51s elapsed]
yandex_kubernetes_cluster.k8s-regional: Still creating... [1m1s elapsed]
yandex_kubernetes_cluster.k8s-regional: Still creating... [1m11s elapsed]
yandex_kubernetes_cluster.k8s-regional: Still creating... [1m21s elapsed]
yandex_kubernetes_cluster.k8s-regional: Still creating... [1m31s elapsed]
yandex_kubernetes_cluster.k8s-regional: Still creating... [1m41s elapsed]
yandex_kubernetes_cluster.k8s-regional: Still creating... [1m51s elapsed]
yandex_kubernetes_cluster.k8s-regional: Still creating... [2m1s elapsed]
yandex_kubernetes_cluster.k8s-regional: Still creating... [2m11s elapsed]
yandex_kubernetes_cluster.k8s-regional: Still creating... [2m21s elapsed]
yandex_kubernetes_cluster.k8s-regional: Still creating... [2m31s elapsed]
yandex_kubernetes_cluster.k8s-regional: Still creating... [2m41s elapsed]
yandex_kubernetes_cluster.k8s-regional: Still creating... [2m51s elapsed]
yandex_kubernetes_cluster.k8s-regional: Still creating... [3m1s elapsed]
yandex_kubernetes_cluster.k8s-regional: Still creating... [3m11s elapsed]
yandex_kubernetes_cluster.k8s-regional: Still creating... [3m21s elapsed]
yandex_kubernetes_cluster.k8s-regional: Still creating... [3m31s elapsed]
yandex_kubernetes_cluster.k8s-regional: Still creating... [3m41s elapsed]
yandex_kubernetes_cluster.k8s-regional: Still creating... [3m51s elapsed]
yandex_kubernetes_cluster.k8s-regional: Still creating... [4m1s elapsed]
yandex_kubernetes_cluster.k8s-regional: Still creating... [4m11s elapsed]
yandex_kubernetes_cluster.k8s-regional: Still creating... [4m21s elapsed]
yandex_kubernetes_cluster.k8s-regional: Still creating... [4m31s elapsed]
yandex_kubernetes_cluster.k8s-regional: Still creating... [4m41s elapsed]
yandex_kubernetes_cluster.k8s-regional: Still creating... [4m51s elapsed]
yandex_kubernetes_cluster.k8s-regional: Still creating... [5m1s elapsed]
yandex_kubernetes_cluster.k8s-regional: Still creating... [5m11s elapsed]
yandex_kubernetes_cluster.k8s-regional: Still creating... [5m21s elapsed]
yandex_kubernetes_cluster.k8s-regional: Still creating... [5m31s elapsed]
yandex_kubernetes_cluster.k8s-regional: Still creating... [5m41s elapsed]
yandex_kubernetes_cluster.k8s-regional: Still creating... [5m51s elapsed]
yandex_kubernetes_cluster.k8s-regional: Still creating... [6m1s elapsed]
yandex_kubernetes_cluster.k8s-regional: Still creating... [6m11s elapsed]
yandex_kubernetes_cluster.k8s-regional: Still creating... [6m21s elapsed]
yandex_kubernetes_cluster.k8s-regional: Still creating... [6m31s elapsed]
yandex_kubernetes_cluster.k8s-regional: Still creating... [6m41s elapsed]
yandex_kubernetes_cluster.k8s-regional: Still creating... [6m51s elapsed]
yandex_kubernetes_cluster.k8s-regional: Still creating... [7m1s elapsed]
yandex_kubernetes_cluster.k8s-regional: Creation complete after 7m8s [id=cathadg1h6d500lr7nnc]
yandex_kubernetes_node_group.worker-nodes-a: Creating...
yandex_kubernetes_node_group.worker-nodes-d: Creating...
yandex_kubernetes_node_group.worker-nodes-b: Creating...
yandex_kubernetes_node_group.worker-nodes-a: Still creating... [10s elapsed]
yandex_kubernetes_node_group.worker-nodes-d: Still creating... [10s elapsed]
yandex_kubernetes_node_group.worker-nodes-b: Still creating... [10s elapsed]
yandex_kubernetes_node_group.worker-nodes-a: Still creating... [20s elapsed]
yandex_kubernetes_node_group.worker-nodes-d: Still creating... [20s elapsed]
yandex_kubernetes_node_group.worker-nodes-b: Still creating... [20s elapsed]
yandex_kubernetes_node_group.worker-nodes-a: Still creating... [30s elapsed]
yandex_kubernetes_node_group.worker-nodes-d: Still creating... [30s elapsed]
yandex_kubernetes_node_group.worker-nodes-b: Still creating... [30s elapsed]
yandex_kubernetes_node_group.worker-nodes-a: Still creating... [40s elapsed]
yandex_kubernetes_node_group.worker-nodes-d: Still creating... [40s elapsed]
yandex_kubernetes_node_group.worker-nodes-b: Still creating... [40s elapsed]
yandex_kubernetes_node_group.worker-nodes-a: Still creating... [50s elapsed]
yandex_kubernetes_node_group.worker-nodes-d: Still creating... [50s elapsed]
yandex_kubernetes_node_group.worker-nodes-b: Still creating... [50s elapsed]
yandex_kubernetes_node_group.worker-nodes-a: Still creating... [1m0s elapsed]
yandex_kubernetes_node_group.worker-nodes-d: Still creating... [1m0s elapsed]
yandex_kubernetes_node_group.worker-nodes-b: Still creating... [1m0s elapsed]
yandex_kubernetes_node_group.worker-nodes-a: Still creating... [1m10s elapsed]
yandex_kubernetes_node_group.worker-nodes-d: Still creating... [1m10s elapsed]
yandex_kubernetes_node_group.worker-nodes-b: Still creating... [1m10s elapsed]
yandex_kubernetes_node_group.worker-nodes-d: Still creating... [1m20s elapsed]
yandex_kubernetes_node_group.worker-nodes-b: Still creating... [1m20s elapsed]
yandex_kubernetes_node_group.worker-nodes-a: Still creating... [1m20s elapsed]
yandex_kubernetes_node_group.worker-nodes-d: Still creating... [1m30s elapsed]
yandex_kubernetes_node_group.worker-nodes-b: Still creating... [1m30s elapsed]
yandex_kubernetes_node_group.worker-nodes-a: Still creating... [1m30s elapsed]
yandex_kubernetes_node_group.worker-nodes-d: Still creating... [1m40s elapsed]
yandex_kubernetes_node_group.worker-nodes-b: Still creating... [1m40s elapsed]
yandex_kubernetes_node_group.worker-nodes-a: Still creating... [1m40s elapsed]
yandex_kubernetes_node_group.worker-nodes-a: Creation complete after 1m43s [id=catqd6je5qjvq7hihpl7]
yandex_kubernetes_node_group.worker-nodes-d: Creation complete after 1m44s [id=catjefhckvflj8gijd2u]
yandex_kubernetes_node_group.worker-nodes-b: Still creating... [1m50s elapsed]
yandex_kubernetes_node_group.worker-nodes-b: Still creating... [2m0s elapsed]
yandex_kubernetes_node_group.worker-nodes-b: Still creating... [2m10s elapsed]
yandex_kubernetes_node_group.worker-nodes-b: Still creating... [2m20s elapsed]
yandex_kubernetes_node_group.worker-nodes-b: Creation complete after 2m26s [id=catqnf9dfuca7qareb2h]
yandex_storage_bucket.state_storage: Creating...
yandex_storage_bucket.state_storage: Creation complete after 7s [id=state-storage-06-02-2025]
yandex_storage_object.backend: Creating...
yandex_storage_object.backend: Creation complete after 1s [id=terraform.tfstate]

Apply complete! Resources: 21 added, 0 changed, 0 destroyed.


```

</details>

Проверим созданные ресурсы с помощью CLI:
```bash
ubuntu@ubuntu-VirtualBox:~/Diplom2/2Part$ yc managed-kubernetes cluster list
+----------------------+--------------+---------------------+---------+---------+-----------------------+-------------------+
|          ID          |     NAME     |     CREATED AT      | HEALTH  | STATUS  |   EXTERNAL ENDPOINT   | INTERNAL ENDPOINT |
+----------------------+--------------+---------------------+---------+---------+-----------------------+-------------------+
| cathadg1h6d500lr7nnc | k8s-regional | 2025-02-06 11:09:57 | HEALTHY | RUNNING | https://84.201.148.13 | https://10.0.1.19 |
+----------------------+--------------+---------------------+---------+---------+-----------------------+-------------------+

ubuntu@ubuntu-VirtualBox:~/Diplom2/2Part$ yc managed-kubernetes cluster get k8s-regional
id: cathadg1h6d500lr7nnc
folder_id: b1gc36q9v49llnddjkvr
created_at: "2025-02-06T11:09:57Z"
name: k8s-regional
labels:
  custom-label: master-1
status: RUNNING
health: HEALTHY
network_id: enp4fh739a6gclq59l26
master:
  regional_master:
    region_id: ru-central1
    internal_v4_address: 10.0.1.19
    external_v4_address: 84.201.148.13
  locations:
    - zone_id: ru-central1-a
      subnet_id: e9b1p54h2f2cmedsp30q
    - zone_id: ru-central1-b
      subnet_id: e2lpgi94siub1cfrmj9e
    - zone_id: ru-central1-d
      subnet_id: fl85j6o8hkdabgqbp1aq
  etcd_cluster_size: "3"
  version: "1.28"
  endpoints:
    internal_v4_endpoint: https://10.0.1.19
    external_v4_endpoint: https://84.201.148.13
  master_auth:
    cluster_ca_certificate: |
      -----BEGIN CERTIFICATE-----
      -----END CERTIFICATE-----
  version_info:
    current_version: "1.28"
  maintenance_policy:
    auto_upgrade: true
    maintenance_window:
      anytime: {}
  security_group_ids:
    - enpg9idmaiu0d9dk19mm
    - enpq351n8o7g7mthajkn
  master_logging:
    enabled: true
    folder_id: b1gc36q9v49llnddjkvr
    audit_enabled: true
    cluster_autoscaler_enabled: true
    kube_apiserver_enabled: true
    events_enabled: true
ip_allocation_policy:
  cluster_ipv4_cidr_block: 10.112.0.0/16
  node_ipv4_cidr_mask_size: "24"
  service_ipv4_cidr_block: 10.96.0.0/16
service_account_id: ajeasvt1plj7h82u7hrv
node_service_account_id: ajeasvt1plj7h82u7hrv
release_channel: REGULAR
kms_provider:
  key_id: abjvlaec1o5vqpkrb7me

```

### 2.2. При помощи Terraform создадим Kubernetes node group

<details>
        <summary></summary>
      <br>

```bash
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
```
</details>

Проверим, что кластер активный и поднялся
<img width="941" alt="Cluster Active" src="https://github.com/user-attachments/assets/585987cd-b5cb-445c-9799-d2d708de8249" />

<img width="1007" alt="Nodes Cluster" src="https://github.com/user-attachments/assets/e424c9f1-1a34-4019-ba68-3dadc9f06200" />

<img width="1048" alt="VMs" src="https://github.com/user-attachments/assets/500db65d-13f8-4a40-b6bc-6d7e69b3ced5" />
