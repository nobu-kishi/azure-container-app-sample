output "subnet_id" {
  description = "作成されたサブネットID"
  value       = azurerm_subnet.aca_subnet.id
}