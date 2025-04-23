
# NOTE: ECRは1リソース=1リポジトリだが、ACRは1リソース=複数のリポジトリを持つことができる
# https://learn.microsoft.com/ja-jp/azure/container-registry/container-registry-overview
resource "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Basic"
  admin_enabled       = true
}

resource "azurerm_container_app_environment" "aca_env" {
  name                     = var.aca_env_name
  location                 = var.location
  resource_group_name      = var.resource_group_name
  infrastructure_subnet_id = var.subnet_id

  # NOTE: 1つの環境に対して、最大5つのワークロードプロファイルを作成できる
  # https://learn.microsoft.com/ja-jp/azure/container-apps/environment-workload-profiles
  workload_profile {
    name                  = "Consumption"
    workload_profile_type = "Consumption"
    maximum_count         = 5
    minimum_count         = 0
  }

  internal_load_balancer_enabled = true
  zone_redundancy_enabled        = true
}

resource "azurerm_container_app" "aca_apps" {
  for_each                     = var.container_apps
  name                         = "${each.key}-app"
  container_app_environment_id = azurerm_container_app_environment.aca_env.id
  resource_group_name          = var.resource_group_name
  revision_mode                = "Single"

  identity {
    type = "SystemAssigned"
  }

  template {
    container {
      name   = each.key
      image  = "${azurerm_container_registry.acr.login_server}/${each.value.image}"
      cpu    = each.value.cpu
      memory = each.value.memory
    }
    min_replicas = 0 # 0を設定することで、リクストがない時は停止できる（常駐させる場合は、1を設定）
    max_replicas = 1
  }
  # NOTE: スケールルールは、「azure_queue_scale_rule,custom_scale_rule,http_scale_rule,tcp_scale_rule」から選択
}

resource "azurerm_role_assignment" "acr_pull" {
  for_each = azurerm_container_app.aca_apps

  principal_id         = each.value.identity[0].principal_id
  role_definition_name = "AcrPull"
  scope                = azurerm_container_registry.acr.id
}
