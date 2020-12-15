variable "location" {
  type        = string
  description = "Region to provision resources in"
  default     = "eastus2"
}

variable "cluster_name" {
  type        = string
  description = "Name to use for the data science culster being created"
  default     = "default"
}

variable "resource_group_name" {
  description = "Resource Group Name"
  type        = string
  default     = "rgdefault"
}

variable "network_subnet_data_id" {
  description = "Data Network Subnet Id"
  type        = string
  default     = "networkid"
}

variable "network_public_ip_list" {
  description = "Public IPs"
  type        = list(string)
  default     = ["default1", "default2"]
}

variable "network_public_fqdn_list" {
  description = "Public IP FQDNs"
  type        = list(string)
  default     = ["default1", "default2"]
}


variable "container_template_deploy_name" {
  description = "Container Template Deployment Name"
  type        = string
  default     = "containername"
}

variable "environment" {
  type        = string
  description = "Current Environment to provision within"
  default     = "dev"
}

variable "default_tags" {
  type        = map(string)
  description = "Collection of default tags to apply to all resources"
}

variable "admin_username" {
  type        = string
  description = "Admin user"
  default     = "locadmin"
}

variable "node_count" {
  type        = number
  description = "Number of Virtual Machine nodes to provision"
  default     = 1
}

variable "ansible_pwfile" {
  type        = string
  description = "Path to file holding ansible vault password"
  default     = "/path/to/file"
}

variable "storage_account_boot_storage_primary_blob_endpoint" {
  type        = string
  description = "Primary Boot Storage"
  default     = "default"
}

variable "storage_account_facts_primary_dfs_endpoint" {
  type        = string
  description = "Storage Account Primary DFS"
  default     = "default"
}

variable "vm_ssh_pubkey" {
  description = "Input for SSH Public Key"
  default     = ""
}

variable "vm_ssh_privkey" {
  description = "VM SSH Private Key for Ansible"
  type        = string
  default     = ""
}

variable "automation_principal_appid" {
  description = "Azure Access for Ansible Automation"
  type        = string
  default     = ""
}

variable "automation_principal_password" {
  description = "Azure Access for Ansible Automation"
  type        = string
  default     = ""
}

variable "automation_principal_tenant" {
  description = "Azure Access for Ansible Automation"
  type        = string
  default     = ""
}

variable "automation_principal_subscription" {
  description = "Azure Access for Ansible Automation"
  type        = string
  default     = ""
}

variable "ans_role" {
  description = "Ansible role for automated cnfiguration management"
  default     = "datascinode"
}
