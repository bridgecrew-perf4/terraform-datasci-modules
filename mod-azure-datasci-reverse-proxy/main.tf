
provider "azurerm" {
  features {}
}

data "http" "myip" {
  url = "http://ipecho.net/plain"
}

# Create nginx public IP address
resource "azurerm_public_ip" "nginx_ip" {
  name                = join("-", ["pip", var.cluster_name, var.environment, var.sub_cluster_name])
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  domain_name_label   = join("-", [var.cluster_name, var.environment, var.sub_cluster_name])

  tags = merge(
    var.default_tags,
    map("name", "nginx")
  )
}

# Create network interface
resource "azurerm_network_interface" "nginx_nic" {
  name                = join("-", ["nic", var.cluster_name, var.environment, var.sub_cluster_name])
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.default_tags

  ip_configuration {
    name                          = "nginx_nicConfiguration"
    subnet_id                     = azurerm_subnet.nginx_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.nginx_ip.id
  }
}

# Create subnet
resource "azurerm_subnet" "nginx_subnet" {
  name                 = join("-", ["snet", var.cluster_name, var.environment, var.sub_cluster_name])
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.parent_vnetwork_name
  address_prefixes     = ["10.0.2.0/24"]
  service_endpoints    = ["Microsoft.EventHub"]
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "nginx_nsg" {
  name                = join("-", ["nsg", var.cluster_name, var.environment, var.sub_cluster_name])
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.default_tags

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = chomp(data.http.myip.body)
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTP"
    priority                   = 2001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTPS"
    priority                   = 2002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "MQTT"
    priority                   = 201
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8883"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "nginx_subnet_nsg" {
  subnet_id                 = azurerm_subnet.nginx_subnet.id
  network_security_group_id = azurerm_network_security_group.nginx_nsg.id
}

# Generate random text for a unique storage account name
resource "random_id" "nginx_randomStorageId" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = var.resource_group_name
  }

  byte_length = 4
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "nginx_boot_storage" {
  name                     = "stdiag${random_id.nginx_randomStorageId.hex}nginx"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = var.default_tags
}

locals {
  envs = [
    join("=", ["fqdn", azurerm_public_ip.nginx_ip.fqdn]),
    join("=", ["admin_username", var.admin_username]),
    join("=", ["admin_email", var.admin_email]),
    join("=", ["mqtt_ip_address", var.mqtt_ip_address]),
    join("=", ["grafana_ip_address", var.grafana_ip_address]),
    join("=", ["consul_server", var.consul_server])
  ]

  cloudinit_data = <<EOF
  #cloud-config
  runcmd:
    - yum install git epel-release -y
    - yum clean all -y
    - yum install ansible -y
    - ansible-galaxy install geerlingguy.nginx
    - ansible-galaxy install geerlingguy.certbot
    - ansible-galaxy install geerlingguy.java
    - ansible-galaxy install bdellegrazie.nginx_exporter
    - git clone https://github.com/shrapk2/ans-datasci-wip.git
    - pushd ans-datasci-wip
    - ansible-playbook -i "localhost, " ./nginx_play.yml -e ansible_connection=local ${length(compact("${local.envs}")) > 0 ? "-e" : ""} ${join(" -e ", compact("${local.envs}"))}
  EOF

}

# Create nginx virtual machine
resource "azurerm_linux_virtual_machine" "nginx_node" {
  name                  = join("-", ["vm", var.cluster_name, var.sub_cluster_name, var.environment])
  location              = var.location
  resource_group_name   = var.resource_group_name
  network_interface_ids = [azurerm_network_interface.nginx_nic.id]
  size                  = "Standard_DS1_v2"
  tags                  = var.default_tags
  computer_name         = join("-", ["vm", var.cluster_name, var.sub_cluster_name, var.environment])
  admin_username        = var.admin_username
  custom_data           = base64encode(local.cloudinit_data)

  os_disk {
    name                 = join("-", ["disknginx", var.cluster_name, var.sub_cluster_name, var.environment])
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
    storage_account_uri = azurerm_storage_account.nginx_boot_storage.primary_blob_endpoint
  }


}
