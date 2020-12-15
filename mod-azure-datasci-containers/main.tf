# Create a Container Group
provider "azurerm" {
  features {}
}

resource "azurerm_container_group" "datasci_mqtt" {
  name                = join("-", [var.cluster_name, var.environment, "mqtt"])
  resource_group_name = var.resource_group_name
  location            = var.location
  ip_address_type     = "private"
  network_profile_id  = var.network_profile_id
  os_type             = "Linux"

  tags = var.default_tags

  # MQTT Broker
  container {
    name   = "mqtt"
    image  = "chesapeaketechnology/mqtt-consul:0.4"
    cpu    = "1.0"
    memory = "1.5"

    ports {
      port     = 1883
      protocol = "TCP"
    }
    ports {
      port     = 9001
      protocol = "TCP"
    }

    volume {
      name       = "mqtt-broker"
      mount_path = "/mosquitto"
      read_only  = "false"
      share_name = var.share_name_mqtt

      storage_account_name = var.volume_storage_account_name
      storage_account_key  = var.volume_storage_account_key
    }

    environment_variables = {
      "USERS" = "${join(",", concat(var.mqtt_users, list(var.admin_username)))}"
    }

  }

  # MQTT to Event Hub Connector
  container {
    name   = "connector"
    image  = "chesapeaketechnology/mqtt-azure-event-hub-connector:0.1.3"
    cpu    = "1"
    memory = "1.5"

    volume {
      name       = "config"
      mount_path = "/mqtt-azure-connector/config"
      read_only  = "true"
      share_name = var.share_name_connector_config

      storage_account_name = var.volume_storage_account_name
      storage_account_key  = var.volume_storage_account_key
    }

    volume {
      name       = "log"
      mount_path = "/mqtt-azure-connector/log"
      read_only  = "false"
      share_name = var.share_name_connector_log

      storage_account_name = var.volume_storage_account_name
      storage_account_key  = var.volume_storage_account_key
    }
  }

  # Consul gateway
  container {
    name   = "mqttconsulgateway"
    image  = "consul"
    cpu    = "0.25"
    memory = "1"

    volume {
      name       = "consul-config"
      mount_path = "/consul/config"
      read_only  = "false"
      share_name = var.share_name_mqttconsulgateway

      storage_account_name = var.volume_storage_account_name
      storage_account_key  = var.volume_storage_account_key
    }

    ports {
      port     = 8500
      protocol = "TCP"
    }

    ports {
      port     = 8600
      protocol = "TCP"
    }

    environment_variables = {
      "CONSUL_LOCAL_CONFIG"   = "{\"disable_update_check\": true}"
      "CONSUL_BIND_INTERFACE" = "eth0"
    }
  }

  # mqtt-exporter
  container {
    name   = "mqttexporter"
    image  = "chesapeaketechnology/mosquitto-exporter:0.1.0"
    cpu    = "0.25"
    memory = "1"

    ports {
      port     = 9234
      protocol = "TCP"
    }

    environment_variables = {
      "BROKER_ENDPOINT" = "tcp://127.0.0.1:1883"
      "BIND_ADDRESS"    = "0.0.0.0:9234"
      "MQTT_USER"       = var.admin_username
    }
  }
}



## BROKER CONFIG MERGE

# Mosquitto MQTT Broker Config
resource "local_file" "mosquitto_config_file" {
  content = templatefile("${path.module}/mosquitto.conf.tmpl",
    {
      future_use = "sample_var"
  })
  filename = "${path.module}/mosquitto.conf"
}

resource "null_resource" "upload_mosquitto_config_file" {

  depends_on = [local_file.mosquitto_config_file]

  provisioner "local-exec" {

    command = "az storage file upload --share-name ${var.mqtt_broker_share_name} --account-name ${var.storage_account_name} --account-key ${var.storage_account_key} --source ${local_file.mosquitto_config_file.filename}  --path config/mosquitto.conf"
  }
}

# MQTT Connector
resource "local_file" "mosquitto_connector_file" {
  content = templatefile("${path.module}/mqtt-connector.conf.tmpl",
    {
      mqtt_server               = "tcp://${azurerm_container_group.datasci_mqtt.ip_address}:1883"
      mqtt_topics               = join(",", var.mqtt_topics)
      mqtt_admin                = var.mqtt_admin
      mqtt_eventhubs_connection = var.namespace_connection_string
      mqtt_eventhubs_batch_size = var.mqtt_eventhubs_batch_size
      mqtt_scheduled_interval   = var.mqtt_scheduled_interval
  })
  filename = "${path.module}/mqtt-connector.conf"
}

resource "null_resource" "upload_mosquitto_connector_file" {

  depends_on = [local_file.mosquitto_connector_file]

  provisioner "local-exec" {

    command = "az storage file upload --share-name ${var.mqtt_config_share_name} --account-name ${var.storage_account_name} --account-key ${var.storage_account_key} --source ${local_file.mosquitto_connector_file.filename}"
  }
}

# Consul
resource "local_file" "consul_config_file" {
  content = templatefile("${path.module}/config.json.tmpl",
    {
      container_address = azurerm_container_group.datasci_mqtt.ip_address
      consul_server     = var.consul_server
  })
  filename = "${path.module}/config.json"
}

resource "null_resource" "upload_consul_config_file" {

  depends_on = [local_file.consul_config_file]

  provisioner "local-exec" {

    command = "az storage file upload --share-name ${var.consul_config_share_name} --account-name ${var.storage_account_name} --account-key ${var.storage_account_key} --source ${local_file.consul_config_file.filename}"
  }
}

# Logging Directory
resource "null_resource" "create_log_dir" {

  provisioner "local-exec" {

    command = "az storage directory create --share-name ${var.mqtt_broker_share_name} --account-name ${var.storage_account_name} --account-key ${var.storage_account_key} --name log"
  }
}
