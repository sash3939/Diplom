#cloud vars
variable "token" {
  type        = string
  description = "OAuth-token; https://cloud.yandex.ru/docs/iam/concepts/authorization/oauth-token"
}

variable "cloud_id" {
  type        = string
  description = "https://cloud.yandex.ru/docs/resource-manager/operations/cloud/get-id"
}

variable "folder_id" {
  type        = string
  description = "https://cloud.yandex.ru/docs/resource-manager/operations/folder/get-id"
}

variable "default_zone" {
  type        = string
  default     = "ru-central1-a"
  description = "https://cloud.yandex.ru/docs/overview/concepts/geo-scope"
}

variable "account_name" {
  type        = string
  default     = "egorkin-ae"
  description = "account_name"
}


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

# IP
variable "host_ip" {
  default = "0.0.0.0/0"
}

variable "kuber" {
  type        = string
  default     = "kuber"
  description = "account_name"
}
