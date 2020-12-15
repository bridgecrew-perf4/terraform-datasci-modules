output "vm_ids" {
  value = [azurerm_linux_virtual_machine.datasci_node.*.id]
}

output "vm_private_ips" {
  value = [azurerm_linux_virtual_machine.datasci_node.*.private_ip_address]
}

output "vm_list_private" {
  value = zipmap(azurerm_linux_virtual_machine.datasci_node.*.id, azurerm_linux_virtual_machine.datasci_node.*.private_ip_address)
}

output "vm_list_public" {
  value = zipmap(azurerm_linux_virtual_machine.datasci_node.*.id, azurerm_linux_virtual_machine.datasci_node.*.public_ip_address)
}

# Use the first node as the consul_server
output "consul_server_ip" {
  value = azurerm_linux_virtual_machine.datasci_node[0].private_ip_address
}

output "vm_list_inventory" {
  value = zipmap(azurerm_linux_virtual_machine.datasci_node.*.name, azurerm_linux_virtual_machine.datasci_node.*.private_ip_address)
}

resource "local_file" "AnsibleInventory" {
  content = templatefile("${path.module}/inventory.tmpl",
    {
      admin_user     = var.admin_username
      cluster_name   = var.cluster_name
      resource_group = var.resource_group_name
      namespaces = join(",", [
        join("-", [var.cluster_name, var.environment, "mqtt-eventhubs-namespace"]),
      join("-", [var.cluster_name, var.environment, "alert-eventhubs-namespace"])])
      azure_datalake_container = var.container_template_deploy_name
      azure_datalake_endpoint  = var.storage_account_facts_primary_dfs_endpoint
      node_name                = azurerm_linux_virtual_machine.datasci_node.*.computer_name
      public_ip                = azurerm_linux_virtual_machine.datasci_node.*.public_ip_address,
      private_ip               = azurerm_linux_virtual_machine.datasci_node.*.private_ip_address,
      node_fqdn                = var.network_public_fqdn_list
    }
  )
  filename = "${path.module}/inventory.yml"
}
