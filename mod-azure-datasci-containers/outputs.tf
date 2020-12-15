output "datasci_containers_group" {
  value = azurerm_container_group.datasci_mqtt
}

output "datasci_containers_mqtt_server" {
  value = "tcp://${azurerm_container_group.datasci_mqtt.ip_address}:1883"
}

output "datasci_containers_mqtt_dns_label" {
  value = join("-", [var.cluster_name, var.environment, "mqtt"])
}

output "datasci_containers_group_ip_address" {
  value = azurerm_container_group.datasci_mqtt.ip_address
}
