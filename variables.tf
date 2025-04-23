variable "env" {
  description = "環境名"
  type        = string
  default     = "dev"
}

variable "subscription_id" {
  description = "サブスクリプションID"
  type        = string
  default     = "b17158f1-9101-4ce3-9224-19e1561bbd4b"
}

variable "location" {
  description = "Azureのリージョン"
  type        = string
  default     = "Japan East"
}

variable "resource_group_name" {
  description = "リソースグループ名"
  type        = string
  default     = "aca-appgw-rg"
}

variable "vnet_name" {
  description = "仮想ネットワーク名"
  type        = string
  default     = "aca-vnet"
}

variable "subnet_name" {
  description = "サブネット名"
  type        = string
  default     = "aca-subnet"
}

variable "acr_name" {
  description = "ACR名"
  type        = string
  default     = "acaregistry"
}

variable "aca_env_name" {
  description = "ACAの環境名"
  type        = string
  default     = "aca-env"
}

variable "aca_profile_name" {
  description = "ACAのプロファイル名"
  type        = string
  default     = "aca-profile"
}

variable "app_gateway_name" {
  description = "Application Gateway名"
  type        = string
  default     = "aca-appgw"
}

variable "backend_services" {
  description = "バックエンドサービスの一覧とポート設定"
  type = map(object({
    # fqdn = string
    port = number
    name = string
  }))
}

variable "vnet_address_space" {
  description = "仮想ネットワークのアドレス空間"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnet_address_prefixes" {
  description = "サブネットのアドレスプレフィックス"
  type        = list(string)
  default     = ["10.0.0.0/23"]
}

variable "container_apps" {
  description = "デプロイするコンテナアプリの設定"
  type = map(object({
    image  = string
    cpu    = number
    memory = string
  }))
  default = {
    backend = {
      image  = "backend:latest"
      cpu    = 0.5
      memory = "1Gi"
    },
    frontend = {
      image  = "frontend:latest"
      cpu    = 0.5
      memory = "1Gi"
    }
  }
}