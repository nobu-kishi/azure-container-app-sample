output "application_gateway_id" {
  description = "作成されたApplication GatewayのID"
  value       = azurerm_application_gateway.appgw.id
}