variable "resource_group_name" {
  description = "ネットワーク用のリソースグループ名"
  type        = string
}

variable "location" {
  description = "Azureリージョン"
  type        = string
}

variable "vnet_name" {
  description = "仮想ネットワーク名"
  type        = string
}

variable "subnet_name" {
  description = "サブネット名"
  type        = string
}

variable "vnet_address_space" {
  description = "VNetのアドレス空間"
  type        = list(string)
}

variable "subnet_address_prefixes" {
  description = "サブネットのアドレスプレフィックス"
  type        = list(string)
}

variable "postgresql_subnet_name" {
  default = "postgresql-subnet"
}

variable "postgresql_subnet_prefixes" {
  default = ["10.0.2.0/24"]
}

variable "postgresql_server_name" {
  default = "mypg-flexibleserver"
}

variable "postgresql_admin_user" {
  default = "postgres"
}

variable "postgresql_admin_password" {
  sensitive = true
  default   = "passw0rd"
}