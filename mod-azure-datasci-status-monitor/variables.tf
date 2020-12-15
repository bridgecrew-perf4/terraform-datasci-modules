variable "cluster_name" {
  type        = string
  description = "Name of the parent cluster"
}

variable "resource_group_name" {
  type        = string
  description = "Azure resource group in which to deploy"
}

variable "environment" {
  type        = string
  description = "Current Environment to provision within"
}

variable "location" {
  type        = string
  description = "Location to provision within"
}

variable "network_profile_id" {
  type        = string
  description = "Name of the network profile in which to create the container"
}

variable "storage_account_name" {
  type = string
}

variable "storage_account_key" {
  type = string
}

# variable "worker_node_ips" {
#   type        = string
#   description = "List of worker nodes private IPs"
# }

# variable "mqtt_server_ip" {
#   type = string
#   description = "MQTT server private IP address"
# }

# variable "reverse_proxy_ip" {
#   type = string
#   description = "NGINX server private IP address"
# }

variable "consul_server_ip" {
  type        = string
  description = "Consul server private IP address"
}

variable "default_tags" {
  type        = map(string)
  description = "Collection of default tags to apply to all resources"
}
