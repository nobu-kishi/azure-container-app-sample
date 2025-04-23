env                 = "dev"
subscription_id     = "b17158f1-9101-4ce3-9224-19e1561bbd4b"
location            = "japaneast"
resource_group_name = "aca-appgw-rg"
vnet_name           = "aca-vnet"
subnet_name         = "aca-subnet"
acr_name            = "acaregistry20250423"
aca_env_name        = "aca-env"
aca_profile_name    = "aca-profile"
# frontend_app_name    = "frontend-app"
# backend_app_name     = "backend-app"
app_gateway_name = "aca-appgw"

backend_services = {
  frontend = {
    # fqdn = "frontend.containers.azure.com"
    port = 8081
    name = "frontend"
  },
  backend = {
    # fqdn = "backend.containers.azure.com"
    port = 8082
    name = "backend"
  },
}
