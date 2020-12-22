output "reverse_proxy_fqdn" {
  value = azurerm_public_ip.nginx_ip.fqdn
}

output "reverse_proxy_ip_address" {
  value = azurerm_public_ip.nginx_ip.ip_address
}

output "reverse_proxy_private_ip" {
  value = azurerm_network_interface.nginx_nic.ip_configuration[0].private_ip_address
}

output "reverse_proxy_cloudinit" {
  value = local.cloudinit_data
}
