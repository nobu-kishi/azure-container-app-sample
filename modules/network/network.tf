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
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

resource "azurerm_subnet" "postgresql_subnet" {
  name                 = var.postgresql_subnet_name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.postgresql_subnet_prefixes
  delegation {
    name = "delegation"
    service_delegation {
      name    = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

resource "azurerm_postgresql_flexible_server" "postgresql" {
  name                   = var.postgresql_server_name
  resource_group_name    = azurerm_resource_group.rg.name
  location               = var.location
  administrator_login    = var.postgresql_admin_user
  administrator_password = var.postgresql_admin_password
  version                = "13"
  storage_mb             = 32768
  sku_name               = "B_Standard_B1ms"
  zone                   = "1" # 任意のAZ指定（柔軟サーバーの場合必要）
  delegated_subnet_id    = azurerm_subnet.postgresql_subnet.id
}