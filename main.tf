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
  default     = "acaregistry2025"
}

variable "aca_env_name" {
  description = "ACAの環境名"
  type        = string
  default     = "aca-env"
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
    image   = string
    cpu     = number
    memory  = string
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

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  address_space       = var.vnet_address_space
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
}

# NOTE: AWSのサブネットと違い、単一のAZに依存しない論理的グループであるため、AZを指定する必要はない
# https://learn.microsoft.com/ja-jp/azure/virtual-network/virtual-networks-overview#virtual-networks-and-availability-zones
resource "azurerm_subnet" "aca_subnet" {
  name                 = var.subnet_name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.subnet_address_prefixes
  delegation {
    name = "delegation"
    service_delegation {
      name    = "Microsoft.App/environments"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

resource "azurerm_container_app_environment" "aca_env" {
  name                           = var.aca_env_name
  location                       = var.location
  resource_group_name            = azurerm_resource_group.rg.name
  infrastructure_subnet_id       = azurerm_subnet.aca_subnet.id
  internal_load_balancer_enabled = true
  zone_redundancy_enabled        = true
}

resource "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  sku                 = "Basic"
  admin_enabled       = true
}

resource "azurerm_container_app" "aca_apps" {
  for_each                     = var.container_apps
  name                         = "${each.key}-app"
  container_app_environment_id = azurerm_container_app_environment.aca_env.id
  resource_group_name          = azurerm_resource_group.rg.name
  revision_mode                = "Single"

  template {
    container {
      name   = each.key
      image  = "${azurerm_container_registry.acr.login_server}/${each.value.image}"
      cpu    = each.value.cpu
      memory = each.value.memory
    }
    min_replicas = 0 # 0を設定することで、リクストがない時は停止できる（常駐させる場合は、1を設定）
    max_replicas = 1
    # NOTE: スケールルールは、「azure_queue_scale_rule,custom_scale_rule,http_scale_rule,tcp_scale_rule」から選択
  }
}

# NOTE: バックエンド用コンテナもリクエストを受けられるようにしているが、紐付けできるコンテナ数が100までなので不要でれば削除する
# https://learn.microsoft.com/ja-jp/azure/azure-resource-manager/management/azure-subscription-service-limits#azure-application-gateway-limits
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/application_gateway
resource "azurerm_application_gateway" "appgw" {
  name                = var.app_gateway_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  frontend_ip_configuration {
    name                          = "appgw-fe-ip"
    subnet_id                     = azurerm_subnet.aca_subnet.id
    # private_ip_address            = "10.0.1.5"
    # NOTE: Dynamicの場合、コンテナが再デプロイされた時、古いIPアドレスが参照される恐れあり（要検証）
    # private_ip_address_allocation = "Static"
    private_ip_address_allocation = "Dynamic"
  }

  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "appgw-ip-config"
    subnet_id = azurerm_subnet.aca_subnet.id
  }

  # NOTE: リスナーポートに相当する
  # NOTE: Application Gatewayのリスナーは、HTTP/HTTPSのプロトコルを指定する必要がある
  dynamic "frontend_port" {
    for_each = var.backend_services
    content {
      name = "port-${frontend_port.value.port}"
      port = frontend_port.value.port
    }
  }

  # NOTE: リスナーに相当する
  dynamic "http_listener" {
    for_each = var.backend_services
    content {
      name                           = "${http_listener.value.name}-listener"
      frontend_ip_configuration_name = "appgw-fe-ip"
      frontend_port_name             = "port-${http_listener.value.port}"
      protocol                       = "Http"
    }
  }

  # NOTE: ターゲットグループに相当する
  # NOTE: Application Gatewayのバックエンドプールは、IPアドレスまたはFQDNを指定する必要がある
  dynamic "backend_address_pool" {
    for_each = var.backend_services
    content {
      name  = "${backend_address_pool.value.name}-backend-pool"
      fqdns = [azurerm_container_app.aca_apps[backend_address_pool.value.name].latest_revision_fqdn]
    }
  }

  dynamic "backend_http_settings" {
    for_each = var.backend_services
    content {
      name                  = "${backend_http_settings.value.name}-http-settings"
      cookie_based_affinity = backend_http_settings.key == "frontend" ? "Enabled" : "Disabled"
      port                  = 80
      protocol              = "Http"
      request_timeout       = 30
    }
  }

  # NOTE: リスナールールに相当する
  dynamic "request_routing_rule" {
    for_each = var.backend_services
    content {
      name                       = "${request_routing_rule.value.name}-rule"
      rule_type                  = "Basic"
      http_listener_name         = "${request_routing_rule.value.name}-listener"
      backend_address_pool_name  = "${request_routing_rule.value.name}-backend-pool"
      backend_http_settings_name = "${request_routing_rule.value.name}-http-settings"
    }
  }
}

# output "container_app_fqdns" {
#   value = { for k, app in azurerm_container_app.aca_apps : k => app.latest_revision_fqdn }
# }
