variable "cluster_name" {
  type        = string
  description = "Name of the parent cluster"
  default     = "cluster_name"
}

variable "environment" {
  type        = string
  description = "Current Environment to provision within"
  default     = "environment"
}

variable "resource_group_name" {
  description = "Resource Group Name"
  default     = "resource_group"
}

variable "location" {
  description = "Resource Group Location"
  default     = "rg-location"
}

variable "network_profile_id" {
  type        = string
  description = "Name of the network profile"
  default     = "network_profile_id"
}

variable "default_tags" {
  type        = map(string)
  description = "Collection of default tags to apply to all resources"
  default     = { "tag1" : "value" }
}

variable "admin_username" {
  type        = string
  description = "Admin user"
  default     = "admin_username"
}

variable "volume_storage_account_name" {
  type        = string
  description = "Storage account for container volume"
  default     = "volume_storage_account_name"
}

variable "volume_storage_account_key" {
  type        = string
  description = "Storage Account key for container volume"
  default     = "volume_storage_account_key"
}

variable "mqtt_users" {
  type        = list(any)
  description = "MQTT User list"
  default     = ["user1", "user2"]
}

variable "share_name_mqtt" {
  type        = string
  description = "Container volume share name"
  default     = "share_name_mqtt"
}

variable "share_name_connector_config" {
  type        = string
  description = "Container volume share name"
  default     = "share_name_connector_config"
}

variable "share_name_connector_log" {
  type        = string
  description = "Container volume share name"
  default     = "share_name_connector_log"
}

variable "share_name_mqttconsulgateway" {
  type        = string
  description = "Container volume share name"
  default     = "share_name_mqttconsulgateway"
}

variable "storage_account_name" {
  type        = string
  description = "storage_account_name"
}

variable "storage_account_key" {
  type        = string
  description = "storage_account_key"
}

variable "mqtt_broker_share_name" {
  type        = string
  description = "mqtt_broker_share_name"
}

variable "mqtt_config_share_name" {
  type        = string
  description = "mqtt_config_share_name"
}

variable "consul_config_share_name" {
  type        = string
  description = "consul_config_share_name"
}

variable "mqtt_admin" {
  type        = string
  description = "mqtt_admin"
}

variable "namespace_connection_string" {
  type        = string
  description = "namespace_connection_string"
}

variable "mqtt_topics" {
  type        = list(string)
  description = "mqtt_topics"
}

variable "mqtt_eventhubs_batch_size" {
  type        = string
  description = "mqtt_eventhubs_batch_size"
}
variable "mqtt_scheduled_interval" {
  type        = string
  description = "mqtt_scheduled_interval"
}
variable "consul_server" {
  type        = string
  description = "consul_server"
}
