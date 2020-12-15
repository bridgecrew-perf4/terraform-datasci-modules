output "prometheus_ip_address" {
  value = azurerm_container_group.datasci_monitor.ip_address
}
