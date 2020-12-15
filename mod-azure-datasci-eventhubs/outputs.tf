# Moved to a more hacked, but cross cloud FQN
# output "namespace_fqn" {
#   description = "fully qualified namesapce for event hub"
#   value = join(".", [azurerm_eventhub_namespace.eventhubs.name, "servicebus.uscloudapi.net"])
# }

output "topic_primary_key" {
  description = "primary access key for the topic"
  value       = values(azurerm_eventhub_authorization_rule.eventhub_auth_rule)[*].primary_key
}

output "topic_secondary_key" {
  description = "secondary access key for the topic"
  value       = values(azurerm_eventhub_authorization_rule.eventhub_auth_rule)[*].secondary_key
}

output "topic_shared_access_policy_name" {
  description = "The shared access policy name for accessing the topic"
  value       = values(azurerm_eventhub_authorization_rule.eventhub_auth_rule)[*].name
}

output "namespace_fqn" {
  description = "fully qualified namesapce for event hub"
  value       = element(split("/", element(split(";", azurerm_eventhub_namespace.eventhubs.default_primary_connection_string), 0)), 2)
}

output "namespace_connection_string" {
  description = "Connection string to the eventhub namespace"
  value       = azurerm_eventhub_namespace.eventhubs.default_primary_connection_string
}
