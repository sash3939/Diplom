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


#---------Backet---------------------------------------------
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
