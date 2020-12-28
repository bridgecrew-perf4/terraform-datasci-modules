
provider "azurerm" {
  features {}
}

locals {
  cloud_data = templatefile("${path.module}/cloud_init.tmpl", {
    vm_ssh_pubkey                     = base64encode(var.vm_ssh_pubkey)
    vm_ssh_privkey                    = base64encode(var.vm_ssh_privkey) #use this when cloud-init bug fixed
    resource_group                    = var.resource_group_name
    environment                       = var.environment
    cluster_name                      = var.cluster_name
    public_ip                         = azurerm_network_interface.vm_nic.*.id
    admin_user                        = var.admin_username
    ans_role                          = var.ans_role
    automation_principal_appid        = var.automation_principal_appid
    automation_principal_password     = var.automation_principal_password
    automation_principal_tenant       = var.automation_principal_tenant
    automation_principal_subscription = var.automation_principal_subscription
    azure_cloud_name                  = "AzureCloud" #change this to a variable or data lookup
    namespaces = join(",", [
      join("-", [var.cluster_name, var.environment, "mqtt-eventhubs-namespace"]),
    join("-", [var.cluster_name, var.environment, "alert-eventhubs-namespace"])])
    azure_datalake_container = var.container_template_deploy_name
    azure_datalake_endpoint  = var.storage_account_facts_primary_dfs_endpoint
  })
}
resource "azurerm_network_interface" "vm_nic" {
  count               = var.node_count
  name                = join("", ["nic-", var.cluster_name, "-", var.environment, count.index])
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.default_tags

  ip_configuration {
    name                          = "datasci_nicConfiguration"
    subnet_id                     = var.network_subnet_data_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = element(var.network_public_ip_list, count.index)
  }
}

# Add count in here and only have cloud-init run on the "0" node
resource "azurerm_linux_virtual_machine" "datasci_node" {
  count                 = var.node_count
  name                  = join("", ["vm-", var.cluster_name, "-", var.environment, count.index])
  location              = var.location
  resource_group_name   = var.resource_group_name
  network_interface_ids = [element(azurerm_network_interface.vm_nic.*.id, count.index)]
  size                  = "Standard_B2ms"
  tags                  = merge(var.default_tags, { ansible_role = var.ans_role })
  admin_username        = var.admin_username
  computer_name         = join("", ["vm-", var.cluster_name, "-", var.environment, count.index])

  os_disk {
    name                 = join("", ["disk", var.cluster_name, "_", var.environment, count.index])
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "OpenLogic"
    offer     = "CentOS"
    sku       = "7.7"
    version   = "7.7.2020100800"
  }

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.vm_ssh_pubkey #file("~/.ssh/id_rsa.pub")
  }

  custom_data = base64encode(local.cloud_data)

  boot_diagnostics {
    storage_account_uri = var.storage_account_boot_storage_primary_blob_endpoint
  }
}

output "clouddata" {
  value = local.cloud_data
}



## Updated lines 106-108, need to validate non-breaking
# module "worker-node" {
#   source         = "./modules/worker-node-ansible"
#   user           = var.admin_username
#   envs           = [
#     join("=", ["inventory", "${local.inventory}"]),
#     join("=", ["resource_group", azurerm_resource_group.datasci_group.name]),
#     join("=", ["namespaces", join(",", [
#       join("-", [var.cluster_name, var.environment, "mqtt-eventhubs-namespace"]),
#       join("-", [var.cluster_name, var.environment, "alert-eventhubs-namespace"])])
#     ]),
#     join("=", ["azure_cloud_name", var.azure_cloud_name]),
#     join("=", ["azure_datalake_container", azurerm_template_deployment.datasci_container.name]),
#     join("=", ["azure_datalake_endpoint", azurerm_storage_account.datasci_lake_storage.primary_dfs_endpoint])
#   ]
#   arguments      = [join("", ["--user=", var.admin_username]), "--vault-password-file", var.ansible_pwfile]
#   playbook       = "../configure-datasci/datasci_play.yml"
# }
