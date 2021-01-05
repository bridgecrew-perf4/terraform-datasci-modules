provider "azurerm" {
  features {}
}

# resource "random_id" "default" {
#   byte_length = 8
# }

# data "archive_file" "default" {
#   type        = "zip"
#   source_dir  = path.module
#   output_path = "${path.module}/${random_id.default.hex}.zip"
# }

# Create public IP address
resource "azurerm_public_ip" "fact_ip" {
  count               = var.factnode_count
  name                = join("", ["pip-", var.sub_cluster_name, "-", var.environment, count.index])
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  domain_name_label   = join("", [var.sub_cluster_name, "-", var.environment, count.index])

  tags = merge(
    var.default_tags,
    map("name", "fact")
  )
}

# Create network interface
resource "azurerm_network_interface" "fact_nic" {
  count               = var.factnode_count
  name                = join("-", ["nic", var.sub_cluster_name, var.environment, count.index])
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.default_tags

  ip_configuration {
    name                          = "fact_nicConfiguration"
    subnet_id                     = var.parent_subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = element(concat(azurerm_public_ip.fact_ip.*.id, list("")), count.index)
  }
}

# Generate random text for a unique storage account name
resource "random_id" "fact_randomStorageId" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = var.resource_group_name
  }

  byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "fact_boot_storage" {
  name                     = "stdiag${random_id.fact_randomStorageId.hex}"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = var.default_tags
}

# Create fact virtual machine
resource "azurerm_linux_virtual_machine" "fact_node" {
  count                 = var.factnode_count
  name                  = join("", ["vm-", var.sub_cluster_name, "-", var.environment, count.index])
  location              = var.location
  resource_group_name   = var.resource_group_name
  network_interface_ids = [element(azurerm_network_interface.fact_nic.*.id, count.index)]
  size                  = "Standard_DS1_v2"
  tags                  = merge(var.default_tags, { ansible_role = var.ans_role })
  #computer_name         = join("", ["nginx", var.environment])
  computer_name  = join("", ["vm-", var.sub_cluster_name, "-", var.environment, count.index])
  admin_username = var.admin_username
  custom_data    = base64encode(local.cloudinit_data)

  os_disk {
    name                 = join("", ["diskfact", "_", var.environment, count.index])
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

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.fact_boot_storage.primary_blob_endpoint
  }
}

locals {
  node_list       = join(",", [for pip in azurerm_public_ip.fact_ip : pip.fqdn])
  private_ip_list = join(",", [for nic in azurerm_network_interface.fact_nic : nic.ip_configuration[0].private_ip_address])
  envs = [
    join("=", ["admin_username", var.admin_username]),
    join("=", ["nodes", local.node_list]),
    join("=", ["consul_server", var.consul_server])
  ]

  cloudinit_data = <<EOF
  #cloud-config
  runcmd:
    - yum install git epel-release -y
    - yum clean all -y
    - yum install ansible -y
    - git clone https://github.com/shrapk2/ans-datasci-wip.git
    - pushd ans-datasci-wip
    - ansible-playbook -i "localhost, " ./postgres_play.yml -e ansible_connection=local ${length(compact("${local.envs}")) > 0 ? "-e" : ""} ${join(" -e ", compact("${local.envs}"))}
  EOF

}

output "cloud_init" {
  value = local.cloudinit_data
}
