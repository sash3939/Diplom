# Создание облачной инфраструктуры
<details>
	<summary></summary>
      <br>

Для начала необходимо подготовить облачную инфраструктуру в ЯО при помощи [Terraform](https://www.terraform.io/).

Особенности выполнения:

- Бюджет купона ограничен, что следует иметь в виду при проектировании инфраструктуры и использовании ресурсов;
Для облачного k8s используйте региональный мастер(неотказоустойчивый). Для self-hosted k8s минимизируйте ресурсы ВМ и долю ЦПУ. В обоих вариантах используйте прерываемые ВМ для worker nodes.

Предварительная подготовка к установке и запуску Kubernetes кластера.

1. Создайте сервисный аккаунт, который будет в дальнейшем использоваться Terraform для работы с инфраструктурой с необходимыми и достаточными правами. Не стоит использовать права суперпользователя
2. Подготовьте [backend](https://www.terraform.io/docs/language/settings/backends/index.html) для Terraform:  
   а. Рекомендуемый вариант: S3 bucket в созданном ЯО аккаунте(создание бакета через TF)
   б. Альтернативный вариант:  [Terraform Cloud](https://app.terraform.io/)  
3. Создайте VPC с подсетями в разных зонах доступности.
4. Убедитесь, что теперь вы можете выполнить команды `terraform destroy` и `terraform apply` без дополнительных ручных действий.
5. В случае использования [Terraform Cloud](https://app.terraform.io/) в качестве [backend](https://www.terraform.io/docs/language/settings/backends/index.html) убедитесь, что применение изменений успешно проходит, используя web-интерфейс Terraform cloud.

Ожидаемые результаты:

1. Terraform сконфигурирован и создание инфраструктуры посредством Terraform возможно без дополнительных ручных действий.
2. Полученная конфигурация инфраструктуры является предварительной, поэтому в ходе дальнейшего выполнения задания возможны изменения.

</details>

---
## Решение:

Подготовим облачную инфраструктуру в Яндекс.Облако при помощи Terraform.

### 1.1. Создадим сервисный аккаунт и ключ KMS, который будет использоваться Terraform для работы с инфраструктурой с необходимыми и достаточными правами.

```hcl
# Создание сервисного аккаунта для Terraform
resource "yandex_iam_service_account" "service" {
  name      = var.account_name
  description = "service account to manage VMs"
  folder_id = var.folder_id
}

# Назначение роли editor сервисному аккаунту
resource "yandex_resourcemanager_folder_iam_member" "editor" {
  folder_id = var.folder_id
  role      = "editor"
  member    = "serviceAccount:${yandex_iam_service_account.service.id}"
  depends_on = [yandex_iam_service_account.service]
}

# Создание статического ключа доступа для сервисного аккаунта
resource "yandex_iam_service_account_static_access_key" "terraform_service_account_key" {
  service_account_id = yandex_iam_service_account.service.id
  description        = "static access key for object storage"
}

#-------------------------------K8sCluster-----------------

resource "yandex_iam_service_account" "kuber" {
  name      = var.kuber
  description = "service account to manage VMs"
  folder_id = var.folder_id
}

# Назначение роли editor сервисному аккаунту
resource "yandex_resourcemanager_folder_iam_member" "kuber-admin" {
  folder_id = var.folder_id
  role      = "editor"
  member    = "serviceAccount:${yandex_iam_service_account.kuber.id}"
  depends_on = [yandex_iam_service_account.kuber]
}

# Сервисному аккаунту назначается роль "k8s.clusters.agent".
resource "yandex_resourcemanager_folder_iam_member" "k8s-clusters-agent" {
  folder_id = var.folder_id
  role      = "k8s.clusters.agent"
  member    = "serviceAccount:${yandex_iam_service_account.kuber.id}"
  depends_on = [yandex_iam_service_account.kuber]
}

# Сервисному аккаунту назначается роль "vpc.publicAdmin".
resource "yandex_resourcemanager_folder_iam_member" "vpc-public-admin" {
  folder_id = var.folder_id
  role      = "vpc.publicAdmin"
  member    = "serviceAccount:${yandex_iam_service_account.kuber.id}"
  depends_on = [yandex_iam_service_account.kuber]
}


# Сервисному аккаунту назначается роль "container-registry.images.puller".
resource "yandex_resourcemanager_folder_iam_member" "images-puller" {
  folder_id = var.folder_id
  role      = "container-registry.images.puller"
  member    = "serviceAccount:${yandex_iam_service_account.kuber.id}"
  depends_on = [yandex_iam_service_account.kuber]
}

# Сервисному аккаунту назначается роль "kms.keys.encrypterDecrypter".
resource "yandex_resourcemanager_folder_iam_member" "encrypterDecrypter" {
  folder_id = var.folder_id
  role      = "kms.keys.encrypterDecrypter"
  member    = "serviceAccount:${yandex_iam_service_account.kuber.id}"
  depends_on = [yandex_iam_service_account.kuber]
}

# Ключ Yandex Key Management Service для шифрования важной информации, такой как пароли, OAuth-токены и SSH-ключи.
resource "yandex_kms_symmetric_key" "kms-key" {
  name              = "kms-key"
  default_algorithm = "AES_256"
  rotation_period   = "8760h" # 1 год.
}
# Создание статического ключа доступа для сервисного аккаунта
resource "yandex_iam_service_account_static_access_key" "terraform_service_account_key_k8s" {
  service_account_id = yandex_iam_service_account.kuber.id
  description        = "static access key for object storage"
}
```

---
### 1.2. Подготовим backend для Terraform:  

```hcl
# Создадим бакет с использованием ключа
resource "yandex_storage_bucket" "state_storage" {
  bucket     = local.bucket_name
  access_key = yandex_iam_service_account_static_access_key.terraform_service_account_key.access_key
  secret_key = yandex_iam_service_account_static_access_key.terraform_service_account_key.secret_key

  anonymous_access_flags {
    read = false
    list = false
  }
}

# Локальная переменная отвечающая за текущую дату в названии бакета
locals {
    current_timestamp = timestamp()
    formatted_date = formatdate("DD-MM-YYYY", local.current_timestamp)
    bucket_name = "state-storage-${local.formatted_date}"
}

# Создание объекта в существующей папке
resource "yandex_storage_object" "backend" {
  access_key = yandex_iam_service_account_static_access_key.terraform_service_account_key.access_key
  secret_key = yandex_iam_service_account_static_access_key.terraform_service_account_key.secret_key
  bucket = local.bucket_name
  key    = "terraform.tfstate"
  source = "./terraform.tfstate"
  depends_on = [yandex_storage_bucket.state_storage]
}
```

---
### 1.3. Создадим VPC, variables с подсетями в разных зонах доступности.

```hcl
#Создание пустой VPC
resource "yandex_vpc_network" "vpc0" {
  name = var.vpc_name
}

# Создадим цикл for_each, который будет создавать подсети в соответствии с описанием
#-----------------revision------------

# Создание подсетей в VPC
resource "yandex_vpc_subnet" "subnets" {
  for_each = var.subnets

  name           = each.key
  zone           = each.value.zone
  network_id     = yandex_vpc_network.vpc0.id
  v4_cidr_blocks = [each.value.cidr_block]
}

#--------end revision----------------

#-------------revision---------
variable "vpc_name" {
  description = "Name VPC"
  default = "vpc0"
  type        = string
}

variable "subnets" {
  type = map(object({
    zone           = string
    cidr_block     = string
  }))
  default = {
    subnet-a = {
      zone       = "ru-central1-a"
      cidr_block = "10.0.1.0/24"
    }
    subnet-b = {
      zone       = "ru-central1-b"
      cidr_block = "10.0.2.0/24"
    }
    subnet-d = {
      zone       = "ru-central1-d"
      cidr_block = "10.0.3.0/24"
    }
  }
}

#----------end-revision---------------------


#---------------K8sCluster-----------------

variable "host_ip" {
  default = "0.0.0.0/0"
}

variable "kuber" {
  type        = string
  default     = "kuber"
  description = "account_name"
}

```

---
### 1.4. Убедимся, что теперь выполняется команды `terraform apply` без дополнительных ручных действий.
<details>
	<summary></summary>
      <br>

```bash
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
          + public_ip              = (known after apply)
          + security_group_ids     = (known after apply)
          + version                = (known after apply)
          + version_info           = (known after apply)

          + master_location {
              + subnet_id = (known after apply)
              + zone      = "ru-central1-a"
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

Plan: 21 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

yandex_kms_symmetric_key.kms-key: Creating...
yandex_iam_service_account.service: Creating...
yandex_vpc_network.vpc0: Creating...
yandex_iam_service_account.kuber: Creating...
yandex_kms_symmetric_key.kms-key: Creation complete after 1s [id=abjieqs20tjga4v8l41s]
yandex_vpc_network.vpc0: Creation complete after 4s [id=enp09ujo2gakav8c2kdl]
yandex_vpc_subnet.subnet-b: Creating...
yandex_vpc_subnet.subnet-a: Creating...
yandex_vpc_security_group.k8s-master-whitelist: Creating...
yandex_vpc_security_group.k8s-nodes-ssh-access: Creating...
yandex_vpc_subnet.subnet-d: Creating...
yandex_vpc_subnet.subnet-a: Creation complete after 1s [id=e9bh479piq0s50il9783]
yandex_vpc_subnet.subnet-d: Creation complete after 1s [id=fl8q8orh6l8p3o9199ur]
yandex_vpc_subnet.subnet-b: Creation complete after 1s [id=e2l6glvf2ea8ok6sr2vg]
yandex_vpc_security_group.k8s-main-sg: Creating...
yandex_vpc_security_group.k8s-master-whitelist: Creation complete after 2s [id=enppu7k8mklqb0a3bvgs]
yandex_iam_service_account.service: Creation complete after 8s [id=aje3m4em893v62pe8kn4]
yandex_resourcemanager_folder_iam_member.editor: Creating...
yandex_iam_service_account_static_access_key.terraform_service_account_key: Creating...
yandex_vpc_security_group.k8s-main-sg: Creation complete after 2s [id=enp2i3cdrt3nnrlntu4m]
yandex_iam_service_account_static_access_key.terraform_service_account_key: Creation complete after 2s [id=ajek1dcc82d1uv2plfvc]
yandex_storage_bucket.state_storage: Creating...
yandex_iam_service_account.kuber: Still creating... [10s elapsed]
yandex_iam_service_account.kuber: Creation complete after 10s [id=aje86k0tossfega3nv6u]
yandex_iam_service_account_static_access_key.terraform_service_account_key_k8s: Creating...
yandex_resourcemanager_folder_iam_member.vpc-public-admin: Creating...
yandex_resourcemanager_folder_iam_member.images-puller: Creating...
yandex_resourcemanager_folder_iam_member.kuber-admin: Creating...
yandex_resourcemanager_folder_iam_member.k8s-clusters-agent: Creating...
yandex_resourcemanager_folder_iam_member.encrypterDecrypter: Creating...
yandex_vpc_security_group.k8s-nodes-ssh-access: Creation complete after 7s [id=enpu66qdgg19naeah0s2]
yandex_resourcemanager_folder_iam_member.editor: Creation complete after 3s [id=b1gc36q9v49llnddjkvr/editor/serviceAccount:aje3m4em893v62pe8kn4]
yandex_iam_service_account_static_access_key.terraform_service_account_key_k8s: Creation complete after 2s [id=aje4op9831puug2ri07s]
yandex_resourcemanager_folder_iam_member.vpc-public-admin: Creation complete after 4s [id=b1gc36q9v49llnddjkvr/vpc.publicAdmin/serviceAccount:aje86k0tossfega3nv6u]
yandex_storage_bucket.state_storage: Creation complete after 7s [id=state-storage-06-02-2025]
yandex_storage_object.backend: Creating...
yandex_resourcemanager_folder_iam_member.kuber-admin: Creation complete after 7s [id=b1gc36q9v49llnddjkvr/editor/serviceAccount:aje86k0tossfega3nv6u]
yandex_storage_object.backend: Creation complete after 1s [id=terraform.tfstate]
yandex_resourcemanager_folder_iam_member.encrypterDecrypter: Creation complete after 10s [id=b1gc36q9v49llnddjkvr/kms.keys.encrypterDecrypter/serviceAccount:aje86k0tossfega3nv6u]
yandex_resourcemanager_folder_iam_member.images-puller: Still creating... [10s elapsed]
yandex_resourcemanager_folder_iam_member.k8s-clusters-agent: Still creating... [10s elapsed]
yandex_resourcemanager_folder_iam_member.images-puller: Creation complete after 13s [id=b1gc36q9v49llnddjkvr/container-registry.images.puller/serviceAccount:aje86k0tossfega3nv6u]
yandex_resourcemanager_folder_iam_member.k8s-clusters-agent: Creation complete after 16s [id=b1gc36q9v49llnddjkvr/k8s.clusters.agent/serviceAccount:aje86k0tossfega3nv6u]
yandex_kubernetes_cluster.k8s-regional: Creating...
yandex_kubernetes_cluster.k8s-regional: Still creating... [10s elapsed]
yandex_kubernetes_cluster.k8s-regional: Still creating... [20s elapsed]
yandex_kubernetes_cluster.k8s-regional: Still creating... [30s elapsed]
yandex_kubernetes_cluster.k8s-regional: Still creating... [40s elapsed]
yandex_kubernetes_cluster.k8s-regional: Still creating... [50s elapsed]
yandex_kubernetes_cluster.k8s-regional: Still creating... [1m0s elapsed]
yandex_kubernetes_cluster.k8s-regional: Still creating... [1m10s elapsed]
yandex_kubernetes_cluster.k8s-regional: Still creating... [1m20s elapsed]
yandex_kubernetes_cluster.k8s-regional: Still creating... [1m30s elapsed]
yandex_kubernetes_cluster.k8s-regional: Still creating... [1m40s elapsed]
yandex_kubernetes_cluster.k8s-regional: Still creating... [1m50s elapsed]
yandex_kubernetes_cluster.k8s-regional: Still creating... [2m0s elapsed]
yandex_kubernetes_cluster.k8s-regional: Still creating... [2m10s elapsed]
yandex_kubernetes_cluster.k8s-regional: Still creating... [2m20s elapsed]
yandex_kubernetes_cluster.k8s-regional: Still creating... [2m30s elapsed]
yandex_kubernetes_cluster.k8s-regional: Still creating... [2m40s elapsed]
yandex_kubernetes_cluster.k8s-regional: Still creating... [2m50s elapsed]
yandex_kubernetes_cluster.k8s-regional: Still creating... [3m0s elapsed]
yandex_kubernetes_cluster.k8s-regional: Still creating... [3m10s elapsed]
yandex_kubernetes_cluster.k8s-regional: Still creating... [3m20s elapsed]
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
yandex_kubernetes_cluster.k8s-regional: Still creating... [7m11s elapsed]
yandex_kubernetes_cluster.k8s-regional: Still creating... [7m21s elapsed]
yandex_kubernetes_cluster.k8s-regional: Still creating... [7m31s elapsed]
yandex_kubernetes_cluster.k8s-regional: Still creating... [7m41s elapsed]
yandex_kubernetes_cluster.k8s-regional: Still creating... [7m51s elapsed]
yandex_kubernetes_cluster.k8s-regional: Still creating... [8m1s elapsed]
yandex_kubernetes_cluster.k8s-regional: Still creating... [8m11s elapsed]
yandex_kubernetes_cluster.k8s-regional: Creation complete after 8m19s [id=catgk6p1ucdv1cmps9db]

Apply complete! Resources: 21 added, 0 changed, 0 destroyed.
```

</details>

Посмотрим созданные ресурсы с помощью CLI

```bash
root@ubuntu-VirtualBox:/home/ubuntu/Diploma-DevOPS-YC/1-Creating-a-cloud-infrastructure# yc vpc network list
+----------------------+------+
|          ID          | NAME |
+----------------------+------+
| enp09ujo2gakav8c2kdl | vpc0 |
+----------------------+------+

root@ubuntu-VirtualBox:/home/ubuntu/Diploma-DevOPS-YC/1-Creating-a-cloud-infrastructure# yc vpc subnet list
+----------------------+-----------------------------------------------------------+----------------------+----------------+---------------+-----------------+
|          ID          |                           NAME                            |      NETWORK ID      | ROUTE TABLE ID |     ZONE      |      RANGE      |
+----------------------+-----------------------------------------------------------+----------------------+----------------+---------------+-----------------+
| e2l6glvf2ea8ok6sr2vg | subnet-b                                                  | enp09ujo2gakav8c2kdl |                | ru-central1-b | [10.0.2.0/24]   |
| e9b4t63psoqdupvbmttc | k8s-cluster-catgk6p1ucdv1cmps9db-service-cidr-reservation | enp09ujo2gakav8c2kdl |                | ru-central1-a | [10.96.0.0/16]  |
| e9bch5lmhv6hqvdsehto | k8s-cluster-catgk6p1ucdv1cmps9db-pod-cidr-reservation     | enp09ujo2gakav8c2kdl |                | ru-central1-a | [10.112.0.0/16] |
| e9bh479piq0s50il9783 | subnet-a                                                  | enp09ujo2gakav8c2kdl |                | ru-central1-a | [10.0.1.0/24]   |
| fl8q8orh6l8p3o9199ur | subnet-d                                                  | enp09ujo2gakav8c2kdl |                | ru-central1-d | [10.0.3.0/24]   |
+----------------------+-----------------------------------------------------------+----------------------+----------------+---------------+-----------------+

root@ubuntu-VirtualBox:/home/ubuntu/Diploma-DevOPS-YC/1-Creating-a-cloud-infrastructure# yc storage bucket list
+--------------------------+----------------------+----------+-----------------------+---------------------+
|           NAME           |      FOLDER ID       | MAX SIZE | DEFAULT STORAGE CLASS |     CREATED AT      |
+--------------------------+----------------------+----------+-----------------------+---------------------+
| state-storage-06-02-2025 | b1gc36q9v49llnddjkvr |        0 | STANDARD              | 2025-02-06 09:39:32 |
+--------------------------+----------------------+----------+-----------------------+---------------------+

root@ubuntu-VirtualBox:/home/ubuntu/Diploma-DevOPS-YC/1-Creating-a-cloud-infrastructure# yc storage bucket stats --name state-storage-23-01-2025
name: state-storage-06-02-2025
used_size: "23584"
storage_class_used_sizes:
  - storage_class: STANDARD
    class_size: "23584"
storage_class_counters:
  - storage_class: STANDARD
    counters:
      simple_object_size: "23584"
      simple_object_count: "1"
default_storage_class: STANDARD
anonymous_access_flags:
  read: false
  list: false
  config_read: false
created_at: "2025-02-06T09:39:32.678133Z"
updated_at: "2025-02-06T09:44:40.162379Z"

```

---
### 1.5. Убедимся, что теперь выполняется команды `terraform destroy` без дополнительных ручных действий.
<details>
	<summary></summary>
      <br>

```bash
root@ubuntu-VirtualBox:/home/ubuntu/Diplom2/1Part# terraform destroy
yandex_vpc_network.vpc0: Refreshing state... [id=enp09ujo2gakav8c2kdl]
yandex_kms_symmetric_key.kms-key: Refreshing state... [id=abjieqs20tjga4v8l41s]
yandex_iam_service_account.service: Refreshing state... [id=aje3m4em893v62pe8kn4]
yandex_iam_service_account.kuber: Refreshing state... [id=aje86k0tossfega3nv6u]
yandex_resourcemanager_folder_iam_member.images-puller: Refreshing state... [id=b1gc36q9v49llnddjkvr/container-registry.images.puller/serviceAccount:aje86k0tossfega3nv6u]
yandex_iam_service_account_static_access_key.terraform_service_account_key: Refreshing state... [id=ajek1dcc82d1uv2plfvc]
yandex_resourcemanager_folder_iam_member.vpc-public-admin: Refreshing state... [id=b1gc36q9v49llnddjkvr/vpc.publicAdmin/serviceAccount:aje86k0tossfega3nv6u]
yandex_resourcemanager_folder_iam_member.kuber-admin: Refreshing state... [id=b1gc36q9v49llnddjkvr/editor/serviceAccount:aje86k0tossfega3nv6u]
yandex_resourcemanager_folder_iam_member.k8s-clusters-agent: Refreshing state... [id=b1gc36q9v49llnddjkvr/k8s.clusters.agent/serviceAccount:aje86k0tossfega3nv6u]
yandex_resourcemanager_folder_iam_member.encrypterDecrypter: Refreshing state... [id=b1gc36q9v49llnddjkvr/kms.keys.encrypterDecrypter/serviceAccount:aje86k0tossfega3nv6u]
yandex_resourcemanager_folder_iam_member.editor: Refreshing state... [id=b1gc36q9v49llnddjkvr/editor/serviceAccount:aje3m4em893v62pe8kn4]
yandex_iam_service_account_static_access_key.terraform_service_account_key_k8s: Refreshing state... [id=aje4op9831puug2ri07s]
yandex_storage_bucket.state_storage: Refreshing state... [id=state-storage-06-02-2025]
yandex_vpc_security_group.k8s-master-whitelist: Refreshing state... [id=enppu7k8mklqb0a3bvgs]
yandex_vpc_subnet.subnet-a: Refreshing state... [id=e9bh479piq0s50il9783]
yandex_vpc_subnet.subnet-d: Refreshing state... [id=fl8q8orh6l8p3o9199ur]
yandex_vpc_security_group.k8s-nodes-ssh-access: Refreshing state... [id=enpu66qdgg19naeah0s2]
yandex_vpc_subnet.subnet-b: Refreshing state... [id=e2l6glvf2ea8ok6sr2vg]
yandex_vpc_security_group.k8s-main-sg: Refreshing state... [id=enp2i3cdrt3nnrlntu4m]
yandex_kubernetes_cluster.k8s-regional: Refreshing state... [id=catgk6p1ucdv1cmps9db]
yandex_storage_object.backend: Refreshing state... [id=terraform.tfstate]

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  - destroy
Terraform will perform the following actions:

  # yandex_iam_service_account.kuber will be destroyed
  - resource "yandex_iam_service_account" "kuber" {
      - created_at  = "2025-02-06T09:39:30Z" -> null
      - description = "service account to manage VMs" -> null
      - folder_id   = "b1gc36q9v49llnddjkvr" -> null
      - id          = "aje86k0tossfega3nv6u" -> null
      - name        = "kuber" -> null
    }

  # yandex_iam_service_account.service will be destroyed
  - resource "yandex_iam_service_account" "service" {
      - created_at  = "2025-02-06T09:39:23Z" -> null
      - description = "service account to manage VMs" -> null
      - folder_id   = "b1gc36q9v49llnddjkvr" -> null
      - id          = "aje3m4em893v62pe8kn4" -> null
      - name        = "egorkin-ae" -> null
    }

  # yandex_iam_service_account_static_access_key.terraform_service_account_key will be destroyed
  - resource "yandex_iam_service_account_static_access_key" "terraform_service_account_key" {
      - access_key         = "YCAJEobSg7jdBoBleTy80D5mO" -> null
      - created_at         = "2025-02-06T09:39:30Z" -> null
      - description        = "static access key for object storage" -> null
      - id                 = "ajek1dcc82d1uv2plfvc" -> null
      - secret_key         = (sensitive value) -> null
      - service_account_id = "aje3m4em893v62pe8kn4" -> null
    }

  # yandex_iam_service_account_static_access_key.terraform_service_account_key_k8s will be destroyed
  - resource "yandex_iam_service_account_static_access_key" "terraform_service_account_key_k8s" {
      - access_key         = "YCAJEETYls5X5xl5pvKFO4-W-" -> null
      - created_at         = "2025-02-06T09:39:32Z" -> null
      - description        = "static access key for object storage" -> null
      - id                 = "aje4op9831puug2ri07s" -> null
      - secret_key         = (sensitive value) -> null
      - service_account_id = "aje86k0tossfega3nv6u" -> null
    }

  # yandex_kms_symmetric_key.kms-key will be destroyed
  - resource "yandex_kms_symmetric_key" "kms-key" {
      - created_at          = "2025-02-06T09:39:22Z" -> null
      - default_algorithm   = "AES_256" -> null
      - deletion_protection = false -> null
      - folder_id           = "b1gc36q9v49llnddjkvr" -> null
      - id                  = "abjieqs20tjga4v8l41s" -> null
      - labels              = {} -> null
      - name                = "kms-key" -> null
      - rotation_period     = "8760h0m0s" -> null
      - status              = "active" -> null
        # (2 unchanged attributes hidden)
    }

  # yandex_kubernetes_cluster.k8s-regional will be destroyed
  - resource "yandex_kubernetes_cluster" "k8s-regional" {
      - cluster_ipv4_range       = "10.112.0.0/16" -> null
      - created_at               = "2025-02-06T09:39:49Z" -> null
      - folder_id                = "b1gc36q9v49llnddjkvr" -> null
      - health                   = "healthy" -> null
      - id                       = "catgk6p1ucdv1cmps9db" -> null
      - labels                   = {} -> null
      - name                     = "k8s-regional" -> null
      - network_id               = "enp09ujo2gakav8c2kdl" -> null
      - node_ipv4_cidr_mask_size = 24 -> null
      - node_service_account_id  = "aje86k0tossfega3nv6u" -> null
      - release_channel          = "REGULAR" -> null
      - service_account_id       = "aje86k0tossfega3nv6u" -> null
      - service_ipv4_range       = "10.96.0.0/16" -> null
      - status                   = "running" -> null
        # (4 unchanged attributes hidden)

      - kms_provider {
          - key_id = "abjieqs20tjga4v8l41s" -> null
        }
         - etcd_cluster_size      = 1 -> null
          - internal_v4_address    = "10.0.1.29" -> null
          - internal_v4_endpoint   = "https://10.0.1.29" -> null
          - public_ip              = false -> null
          - security_group_ids     = [
              - "enp2i3cdrt3nnrlntu4m",
            ] -> null
          - version                = "1.28" -> null
          - version_info           = [
              - {
                  - current_version        = "1.28"
                  - new_revision_available = false
                  - version_deprecated     = false
                    # (1 unchanged attribute hidden)
                },
            ] -> null
            # (4 unchanged attributes hidden)

          - maintenance_policy {
              - auto_upgrade = true -> null
            }

          - master_location {
              - subnet_id = "e9bh479piq0s50il9783" -> null
              - zone      = "ru-central1-a" -> null
            }

          - zonal {
              - zone      = "ru-central1-a" -> null
                # (1 unchanged attribute hidden)
            }
        }
    }

  # yandex_resourcemanager_folder_iam_member.editor will be destroyed
  - resource "yandex_resourcemanager_folder_iam_member" "editor" {
      - folder_id = "b1gc36q9v49llnddjkvr" -> null
      - id        = "b1gc36q9v49llnddjkvr/editor/serviceAccount:aje3m4em893v62pe8kn4" -> null
      - member    = "serviceAccount:aje3m4em893v62pe8kn4" -> null
      - role      = "editor" -> null
    }

  # yandex_resourcemanager_folder_iam_member.encrypterDecrypter will be destroyed
  - resource "yandex_resourcemanager_folder_iam_member" "encrypterDecrypter" {
      - folder_id = "b1gc36q9v49llnddjkvr" -> null
      - id        = "b1gc36q9v49llnddjkvr/kms.keys.encrypterDecrypter/serviceAccount:aje86k0tossfega3nv6u" -> null
      - member    = "serviceAccount:aje86k0tossfega3nv6u" -> null
      - role      = "kms.keys.encrypterDecrypter" -> null
    }

  # yandex_resourcemanager_folder_iam_member.images-puller will be destroyed
  - resource "yandex_resourcemanager_folder_iam_member" "images-puller" {
      - folder_id = "b1gc36q9v49llnddjkvr" -> null
      - id        = "b1gc36q9v49llnddjkvr/container-registry.images.puller/serviceAccount:aje86k0tossfega3nv6u" -> null
      - member    = "serviceAccount:aje86k0tossfega3nv6u" -> null
      - role      = "container-registry.images.puller" -> null
    }

  # yandex_resourcemanager_folder_iam_member.k8s-clusters-agent will be destroyed
  - resource "yandex_resourcemanager_folder_iam_member" "k8s-clusters-agent" {
      - folder_id = "b1gc36q9v49llnddjkvr" -> null
      - id        = "b1gc36q9v49llnddjkvr/k8s.clusters.agent/serviceAccount:aje86k0tossfega3nv6u" -> null
      - member    = "serviceAccount:aje86k0tossfega3nv6u" -> null
      - role      = "k8s.clusters.agent" -> null
    }
 # yandex_resourcemanager_folder_iam_member.kuber-admin will be destroyed
  - resource "yandex_resourcemanager_folder_iam_member" "kuber-admin" {
      - folder_id = "b1gc36q9v49llnddjkvr" -> null
      - id        = "b1gc36q9v49llnddjkvr/editor/serviceAccount:aje86k0tossfega3nv6u" -> null
      - member    = "serviceAccount:aje86k0tossfega3nv6u" -> null
      - role      = "editor" -> null
    }

  # yandex_resourcemanager_folder_iam_member.vpc-public-admin will be destroyed
  - resource "yandex_resourcemanager_folder_iam_member" "vpc-public-admin" {
      - folder_id = "b1gc36q9v49llnddjkvr" -> null
      - id        = "b1gc36q9v49llnddjkvr/vpc.publicAdmin/serviceAccount:aje86k0tossfega3nv6u" -> null
      - member    = "serviceAccount:aje86k0tossfega3nv6u" -> null
      - role      = "vpc.publicAdmin" -> null
    }

  # yandex_storage_bucket.state_storage will be destroyed
  - resource "yandex_storage_bucket" "state_storage" {
      - access_key            = "YCAJEobSg7jdBoBleTy80D5mO" -> null
      - bucket                = "state-storage-06-02-2025" -> null
      - bucket_domain_name    = "state-storage-06-02-2025.storage.yandexcloud.net" -> null
      - default_storage_class = "STANDARD" -> null
      - folder_id             = "b1gc36q9v49llnddjkvr" -> null
      - force_destroy         = false -> null
      - id                    = "state-storage-06-02-2025" -> null
      - max_size              = 0 -> null
      - secret_key            = (sensitive value) -> null
      - tags                  = {} -> null
        # (1 unchanged attribute hidden)

      - anonymous_access_flags {
          - config_read = false -> null
          - list        = false -> null
          - read        = false -> null
        }

      - versioning {
          - enabled = false -> null
        }
    }

  # yandex_storage_object.backend will be destroyed
  - resource "yandex_storage_object" "backend" {
      - access_key   = "YCAJEobSg7jdBoBleTy80D5mO" -> null
      - acl          = "private" -> null
      - bucket       = "state-storage-06-02-2025" -> null
      - content_type = "application/octet-stream" -> null
      - id           = "terraform.tfstate" -> null
      - key          = "terraform.tfstate" -> null
      - secret_key   = (sensitive value) -> null
      - source       = "./terraform.tfstate" -> null
      - tags         = {} -> null
    }

  # yandex_vpc_network.vpc0 will be destroyed
  - resource "yandex_vpc_network" "vpc0" {
      - created_at                = "2025-02-06T09:39:22Z" -> null
      - default_security_group_id = "enp6aaha4n1gjnnl6s8c" -> null
      - folder_id                 = "b1gc36q9v49llnddjkvr" -> null
      - id                        = "enp09ujo2gakav8c2kdl" -> null
      - labels                    = {} -> null
      - name                      = "vpc0" -> null
      - subnet_ids                = [
          - "e2l6glvf2ea8ok6sr2vg",
          - "e9b4t63psoqdupvbmttc",
          - "e9bch5lmhv6hqvdsehto",
          - "e9bh479piq0s50il9783",
          - "fl8q8orh6l8p3o9199ur",
        ] -> null
        # (1 unchanged attribute hidden)
    }

  # yandex_vpc_security_group.k8s-main-sg will be destroyed
  - resource "yandex_vpc_security_group" "k8s-main-sg" {
      - created_at  = "2025-02-06T09:39:29Z" -> null
      - description = "Правила группы обеспечивают базовую работоспособность кластера" -> null
      - folder_id   = "b1gc36q9v49llnddjkvr" -> null
      - id          = "enp2i3cdrt3nnrlntu4m" -> null
      - labels      = {} -> null
      - name        = "k8s-main-sg" -> null
      - network_id  = "enp09ujo2gakav8c2kdl" -> null
      - status      = "ACTIVE" -> null

      - egress {
          - description       = "Правило разрешает весь исходящий трафик. Узлы могут связаться с Yandex Container Registry, Object Storage, Docker Hub и т.д." -> null
          - from_port         = 0 -> null
          - id                = "enp5etdnjj13m15i2ak6" -> null
          - labels            = {} -> null
          - port              = -1 -> null
          - protocol          = "ANY" -> null
          - to_port           = 65535 -> null
          - v4_cidr_blocks    = [
              - "0.0.0.0/0",
            ] -> null
          - v6_cidr_blocks    = [] -> null
            # (2 unchanged attributes hidden)
        }

      - ingress {
          - description       = "Правило разрешает взаимодействие мастер-узел и узел-узел внутри группы безопасности." -> null
          - from_port         = 0 -> null
          - id                = "enpe48he1qdqpako4uan" -> null
          - labels            = {} -> null
          - port              = -1 -> null
          - predefined_target = "self_security_group" -> null
          - protocol          = "ANY" -> null
          - to_port           = 65535 -> null
          - v4_cidr_blocks    = [] -> null
          - v6_cidr_blocks    = [] -> null
            # (1 unchanged attribute hidden)
        }
      - ingress {
          - description       = "Правило разрешает взаимодействие под-под и сервис-сервис. Указываем подсети нашего кластера и сервисов." -> null
          - from_port         = 0 -> null
          - id                = "enpts6e7j1dfafv0n1oj" -> null
          - labels            = {} -> null
          - port              = -1 -> null
          - protocol          = "ANY" -> null
          - to_port           = 65535 -> null
          - v4_cidr_blocks    = [
              - "10.0.1.0/24",
              - "10.0.2.0/24",
              - "10.0.3.0/24",
            ] -> null
          - v6_cidr_blocks    = [] -> null
            # (2 unchanged attributes hidden)
        }
      - ingress {
          - description       = "Правило разрешает входящий трафик из интернета на диапазон портов NodePort. Добавляем или изменяем порты на нужные нам." -> null
          - from_port         = 30000 -> null
          - id                = "enpku5vhkknsdkcjs77e" -> null
          - labels            = {} -> null
          - port              = -1 -> null
          - protocol          = "TCP" -> null
          - to_port           = 32767 -> null
          - v4_cidr_blocks    = [
              - "0.0.0.0/0",
            ] -> null
          - v6_cidr_blocks    = [] -> null
            # (2 unchanged attributes hidden)
        }
      - ingress {
          - description       = "Правило разрешает отладочные ICMP-пакеты из внутренних подсетей." -> null
          - from_port         = -1 -> null
          - id                = "enpaeup46a0o40uhegtd" -> null
          - labels            = {} -> null
          - port              = -1 -> null
          - protocol          = "ICMP" -> null
          - to_port           = -1 -> null
          - v4_cidr_blocks    = [
              - "172.16.0.0/12",
              - "10.0.0.0/8",
              - "192.168.0.0/16",
            ] -> null
          - v6_cidr_blocks    = [] -> null
            # (2 unchanged attributes hidden)
        }
      - ingress {
          - description       = "Правило разрешает проверки доступности с диапазона адресов балансировщика нагрузки. Нужно для работы отказоустойчивого кластера и сервисов балансировщика." -> null
          - from_port         = 0 -> null
          - id                = "enpcbmnpouqgq9h9v4ul" -> null
          - labels            = {} -> null
          - port              = -1 -> null
          - predefined_target = "loadbalancer_healthchecks" -> null
          - protocol          = "TCP" -> null
          - to_port           = 65535 -> null
          - v4_cidr_blocks    = [] -> null
          - v6_cidr_blocks    = [] -> null
            # (1 unchanged attribute hidden)
        }
    }

  # yandex_vpc_security_group.k8s-master-whitelist will be destroyed
  - resource "yandex_vpc_security_group" "k8s-master-whitelist" {
      - created_at  = "2025-02-06T09:39:27Z" -> null
      - description = "Правила группы разрешают доступ к API Kubernetes из интернета. Применяем правила только к кластеру." -> null
      - folder_id   = "b1gc36q9v49llnddjkvr" -> null
      - id          = "enppu7k8mklqb0a3bvgs" -> null
      - labels      = {} -> null
      - name        = "k8s-master-whitelist" -> null
      - network_id  = "enp09ujo2gakav8c2kdl" -> null
      - status      = "ACTIVE" -> null

      - ingress {
          - description       = "Правило разрешает подключение к API Kubernetes через порт 443 из указанной сети." -> null
          - from_port         = -1 -> null
          - id                = "enpjn42u52hpk91lau00" -> null
          - labels            = {} -> null
          - port              = 443 -> null
          - protocol          = "TCP" -> null
          - to_port           = -1 -> null
          - v4_cidr_blocks    = [
              - "0.0.0.0/0",
            ] -> null
          - v6_cidr_blocks    = [] -> null
            # (2 unchanged attributes hidden)
        }
      - ingress {
          - description       = "Правило разрешает подключение к API Kubernetes через порт 6443 из указанной сети." -> null
          - from_port         = -1 -> null
          - id                = "enp9bpmebjltji252ea8" -> null
          - labels            = {} -> null
          - port              = 6443 -> null
          - protocol          = "TCP" -> null
          - to_port           = -1 -> null
          - v4_cidr_blocks    = [
              - "0.0.0.0/0",
            ] -> null
          - v6_cidr_blocks    = [] -> null
            # (2 unchanged attributes hidden)
        }
    }

  # yandex_vpc_security_group.k8s-nodes-ssh-access will be destroyed
  - resource "yandex_vpc_security_group" "k8s-nodes-ssh-access" {
      - created_at  = "2025-02-06T09:39:32Z" -> null
      - description = "Правила группы разрешают подключение к узлам кластера по SSH. Применяем правила только для групп узлов." -> null
      - folder_id   = "b1gc36q9v49llnddjkvr" -> null
      - id          = "enpu66qdgg19naeah0s2" -> null
      - labels      = {} -> null
      - name        = "k8s-nodes-ssh-access" -> null
      - network_id  = "enp09ujo2gakav8c2kdl" -> null
      - status      = "ACTIVE" -> null

      - ingress {
          - description       = "Правило разрешает подключение к узлам по SSH с указанных IP-адресов." -> null
          - from_port         = -1 -> null
          - id                = "enp56a8tnq1pqnrnnpp7" -> null
          - labels            = {} -> null
          - port              = 22 -> null
          - protocol          = "TCP" -> null
          - to_port           = -1 -> null
          - v4_cidr_blocks    = [
              - "0.0.0.0/0",
            ] -> null
          - v6_cidr_blocks    = [] -> null
            # (2 unchanged attributes hidden)
        }
    }

 # yandex_vpc_subnet.subnet-a will be destroyed
  - resource "yandex_vpc_subnet" "subnet-a" {
      - created_at     = "2025-02-06T09:39:26Z" -> null
      - folder_id      = "b1gc36q9v49llnddjkvr" -> null
      - id             = "e9bh479piq0s50il9783" -> null
      - labels         = {} -> null
      - name           = "subnet-a" -> null
      - network_id     = "enp09ujo2gakav8c2kdl" -> null
      - v4_cidr_blocks = [
          - "10.0.1.0/24",
        ] -> null
      - v6_cidr_blocks = [] -> null
      - zone           = "ru-central1-a" -> null
        # (2 unchanged attributes hidden)
    }

  # yandex_vpc_subnet.subnet-b will be destroyed
  - resource "yandex_vpc_subnet" "subnet-b" {
      - created_at     = "2025-02-06T09:39:27Z" -> null
      - folder_id      = "b1gc36q9v49llnddjkvr" -> null
      - id             = "e2l6glvf2ea8ok6sr2vg" -> null
      - labels         = {} -> null
      - name           = "subnet-b" -> null
      - network_id     = "enp09ujo2gakav8c2kdl" -> null
      - v4_cidr_blocks = [
          - "10.0.2.0/24",
        ] -> null
      - v6_cidr_blocks = [] -> null
      - zone           = "ru-central1-b" -> null
        # (2 unchanged attributes hidden)
    }

  # yandex_vpc_subnet.subnet-d will be destroyed
  - resource "yandex_vpc_subnet" "subnet-d" {
      - created_at     = "2025-02-06T09:39:26Z" -> null
      - folder_id      = "b1gc36q9v49llnddjkvr" -> null
      - id             = "fl8q8orh6l8p3o9199ur" -> null
      - labels         = {} -> null
      - name           = "subnet-d" -> null
      - network_id     = "enp09ujo2gakav8c2kdl" -> null
      - v4_cidr_blocks = [
          - "10.0.3.0/24",
        ] -> null
      - v6_cidr_blocks = [] -> null
      - zone           = "ru-central1-d" -> null
        # (2 unchanged attributes hidden)
    }

Plan: 0 to add, 0 to change, 21 to destroy.

Do you really want to destroy all resources?
  Terraform will destroy all your managed infrastructure, as shown above.
  There is no undo. Only 'yes' will be accepted to confirm.

  Enter a value: yes

yandex_resourcemanager_folder_iam_member.editor: Destroying... [id=b1gc36q9v49llnddjkvr/editor/serviceAccount:aje3m4em893v62pe8kn4]
yandex_vpc_security_group.k8s-master-whitelist: Destroying... [id=enppu7k8mklqb0a3bvgs]
yandex_kubernetes_cluster.k8s-regional: Destroying... [id=catgk6p1ucdv1cmps9db]
yandex_iam_service_account_static_access_key.terraform_service_account_key_k8s: Destroying... [id=aje4op9831puug2ri07s]
yandex_vpc_security_group.k8s-nodes-ssh-access: Destroying... [id=enpu66qdgg19naeah0s2]
yandex_storage_object.backend: Destroying... [id=terraform.tfstate]
yandex_storage_object.backend: Destruction complete after 0s
yandex_storage_bucket.state_storage: Destroying... [id=state-storage-06-02-2025]
yandex_iam_service_account_static_access_key.terraform_service_account_key_k8s: Destruction complete after 0s
yandex_vpc_security_group.k8s-nodes-ssh-access: Destruction complete after 0s
yandex_vpc_security_group.k8s-master-whitelist: Destruction complete after 1s
yandex_resourcemanager_folder_iam_member.editor: Destruction complete after 3s
yandex_kubernetes_cluster.k8s-regional: Still destroying... [id=catgk6p1ucdv1cmps9db, 10s elapsed]
yandex_storage_bucket.state_storage: Still destroying... [id=state-storage-06-02-2025, 10s elapsed]
yandex_storage_bucket.state_storage: Destruction complete after 13s
yandex_iam_service_account_static_access_key.terraform_service_account_key: Destroying... [id=ajek1dcc82d1uv2plfvc]
yandex_iam_service_account_static_access_key.terraform_service_account_key: Destruction complete after 0s
yandex_iam_service_account.service: Destroying... [id=aje3m4em893v62pe8kn4]
yandex_iam_service_account.service: Destruction complete after 5s
yandex_kubernetes_cluster.k8s-regional: Still destroying... [id=catgk6p1ucdv1cmps9db, 20s elapsed]
yandex_kubernetes_cluster.k8s-regional: Still destroying... [id=catgk6p1ucdv1cmps9db, 30s elapsed]
yandex_kubernetes_cluster.k8s-regional: Still destroying... [id=catgk6p1ucdv1cmps9db, 40s elapsed]
yandex_kubernetes_cluster.k8s-regional: Still destroying... [id=catgk6p1ucdv1cmps9db, 50s elapsed]
yandex_kubernetes_cluster.k8s-regional: Still destroying... [id=catgk6p1ucdv1cmps9db, 1m0s elapsed]
yandex_kubernetes_cluster.k8s-regional: Still destroying... [id=catgk6p1ucdv1cmps9db, 1m10s elapsed]
yandex_kubernetes_cluster.k8s-regional: Still destroying... [id=catgk6p1ucdv1cmps9db, 1m20s elapsed]
yandex_kubernetes_cluster.k8s-regional: Still destroying... [id=catgk6p1ucdv1cmps9db, 1m30s elapsed]
yandex_kubernetes_cluster.k8s-regional: Still destroying... [id=catgk6p1ucdv1cmps9db, 1m40s elapsed]
yandex_kubernetes_cluster.k8s-regional: Still destroying... [id=catgk6p1ucdv1cmps9db, 1m50s elapsed]
yandex_kubernetes_cluster.k8s-regional: Still destroying... [id=catgk6p1ucdv1cmps9db, 2m0s elapsed]
yandex_kubernetes_cluster.k8s-regional: Still destroying... [id=catgk6p1ucdv1cmps9db, 2m10s elapsed]
yandex_kubernetes_cluster.k8s-regional: Still destroying... [id=catgk6p1ucdv1cmps9db, 2m20s elapsed]
yandex_kubernetes_cluster.k8s-regional: Still destroying... [id=catgk6p1ucdv1cmps9db, 2m30s elapsed]
yandex_kubernetes_cluster.k8s-regional: Still destroying... [id=catgk6p1ucdv1cmps9db, 2m40s elapsed]
yandex_kubernetes_cluster.k8s-regional: Still destroying... [id=catgk6p1ucdv1cmps9db, 2m50s elapsed]
yandex_kubernetes_cluster.k8s-regional: Still destroying... [id=catgk6p1ucdv1cmps9db, 3m0s elapsed]
yandex_kubernetes_cluster.k8s-regional: Still destroying... [id=catgk6p1ucdv1cmps9db, 3m10s elapsed]
yandex_kubernetes_cluster.k8s-regional: Still destroying... [id=catgk6p1ucdv1cmps9db, 3m20s elapsed]
yandex_kubernetes_cluster.k8s-regional: Still destroying... [id=catgk6p1ucdv1cmps9db, 3m30s elapsed]
yandex_kubernetes_cluster.k8s-regional: Still destroying... [id=catgk6p1ucdv1cmps9db, 3m40s elapsed]
yandex_kubernetes_cluster.k8s-regional: Destruction complete after 3m41s
yandex_resourcemanager_folder_iam_member.vpc-public-admin: Destroying... [id=b1gc36q9v49llnddjkvr/vpc.publicAdmin/serviceAccount:aje86k0tossfega3nv6u]
yandex_resourcemanager_folder_iam_member.kuber-admin: Destroying... [id=b1gc36q9v49llnddjkvr/editor/serviceAccount:aje86k0tossfega3nv6u]
yandex_resourcemanager_folder_iam_member.k8s-clusters-agent: Destroying... [id=b1gc36q9v49llnddjkvr/k8s.clusters.agent/serviceAccount:aje86k0tossfega3nv6u]
yandex_kms_symmetric_key.kms-key: Destroying... [id=abjieqs20tjga4v8l41s]
yandex_resourcemanager_folder_iam_member.images-puller: Destroying... [id=b1gc36q9v49llnddjkvr/container-registry.images.puller/serviceAccount:aje86k0tossfega3nv6u]
yandex_resourcemanager_folder_iam_member.encrypterDecrypter: Destroying... [id=b1gc36q9v49llnddjkvr/kms.keys.encrypterDecrypter/serviceAccount:aje86k0tossfega3nv6u]
yandex_vpc_security_group.k8s-main-sg: Destroying... [id=enp2i3cdrt3nnrlntu4m]
yandex_kms_symmetric_key.kms-key: Destruction complete after 0s
yandex_vpc_security_group.k8s-main-sg: Destruction complete after 1s
yandex_vpc_subnet.subnet-d: Destroying... [id=fl8q8orh6l8p3o9199ur]
yandex_vpc_subnet.subnet-b: Destroying... [id=e2l6glvf2ea8ok6sr2vg]
yandex_vpc_subnet.subnet-a: Destroying... [id=e9bh479piq0s50il9783]
yandex_vpc_subnet.subnet-b: Destruction complete after 1s
yandex_vpc_subnet.subnet-a: Destruction complete after 2s
yandex_resourcemanager_folder_iam_member.images-puller: Destruction complete after 3s
yandex_vpc_subnet.subnet-d: Destruction complete after 3s
yandex_vpc_network.vpc0: Destroying... [id=enp09ujo2gakav8c2kdl]
yandex_vpc_network.vpc0: Destruction complete after 1s
yandex_resourcemanager_folder_iam_member.kuber-admin: Destruction complete after 6s
yandex_resourcemanager_folder_iam_member.encrypterDecrypter: Destruction complete after 9s
yandex_resourcemanager_folder_iam_member.vpc-public-admin: Still destroying... [id=b1gc36q9v49llnddjkvr/vpc.publicAdmin/serviceAccount:aje86k0tossfega3nv6u, 10s elapsed]
yandex_resourcemanager_folder_iam_member.k8s-clusters-agent: Still destroying... [id=b1gc36q9v49llnddjkvr/k8s.clusters.agent/serviceAccount:aje86k0tossfega3nv6u, 10s elapsed]
yandex_resourcemanager_folder_iam_member.vpc-public-admin: Destruction complete after 12s
yandex_resourcemanager_folder_iam_member.k8s-clusters-agent: Destruction complete after 15s
yandex_iam_service_account.kuber: Destroying... [id=aje86k0tossfega3nv6u]
yandex_iam_service_account.kuber: Destruction complete after 5s

Destroy complete! Resources: 21 destroyed.

```
</details>
