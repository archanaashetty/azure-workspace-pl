# Reference layout: https://github.com/databricks-solutions/technical-services-solutions/tree/main/workspace-setup/terraform-examples/azure/azure-privatelink-classic
# Subnets: Databricks host/container are /22; private endpoint subnet size is configurable (see network.tf).

variable "az_subscription" {
  type        = string
  description = "Azure subscription ID where resources are deployed (required for azurerm 4.x provider)."
}

variable "resource_prefix" {
  type        = string
  description = "Prefix for Azure resource names; also used to derive DBFS storage account name (alphanumeric only, 3-24 chars)."
  default     = "databricks-workspace"
  validation {
    condition     = can(regex("^[a-z0-9-.]{1,40}$", var.resource_prefix))
    error_message = "The resource_prefix value must be 1-40 characters and contain only a-z, 0-9, hyphens, and periods."
  }
}

variable "workspace_name" {
  type        = string
  default     = null
  nullable    = true
  description = "Azure Databricks workspace resource name (3-30 chars: letters, numbers, hyphens). If null or blank, defaults to dbw-<resource_prefix>-dp."

  validation {
    condition = (
      var.workspace_name == null || trimspace(var.workspace_name) == "" ||
      can(regex("^[a-zA-Z0-9-]{3,30}$", trimspace(var.workspace_name)))
    )
    error_message = "The workspace_name value must be null or blank to use the default name, or be 3-30 characters using only letters, numbers, and hyphens."
  }
}

variable "workload_resource_group_name" {
  type        = string
  description = "Existing resource group where the workspace, DNS zones, private endpoints, NAT, and NSG are deployed. Must exist before apply."
}

variable "virtual_network_resource_group_name" {
  type        = string
  description = "Resource group containing the existing virtual network used for VNet injection, new subnets, and Private DNS VNet links."
}

variable "virtual_network_name" {
  type        = string
  description = "Existing virtual network into which new subnets are created (Databricks /22 + private endpoint subnet per variables)."
}

variable "subnet_cidr_databricks_host" {
  type        = string
  description = "/22 CIDR for the Databricks host (public) subnet. Must fit inside the VNet address_space and not overlap other subnets in this template."
  validation {
    condition     = endswith(var.subnet_cidr_databricks_host, "/22")
    error_message = "The subnet_cidr_databricks_host value must be a /22 CIDR block (for example, 10.0.0.0/22)."
  }
}

variable "subnet_cidr_databricks_container" {
  type        = string
  description = "/22 CIDR for the Databricks container (private) subnet. Must fit inside the VNet address_space and not overlap other subnets in this template."
  validation {
    condition     = endswith(var.subnet_cidr_databricks_container, "/22")
    error_message = "The subnet_cidr_databricks_container value must be a /22 CIDR block (for example, 10.0.4.0/22)."
  }
}

variable "subnet_cidr_private_endpoints" {
  type        = string
  description = "IPv4 CIDR for the private endpoint subnet (control plane, browser auth, DBFS). Prefix length is not fixed (/26 is common). No delegation. Must fit inside the VNet address_space and not overlap other subnets."
  validation {
    condition     = can(cidrhost(var.subnet_cidr_private_endpoints, 0))
    error_message = "The subnet_cidr_private_endpoints value must be a valid IPv4 CIDR block (for example, 10.0.8.0/26)."
  }
}

variable "subnets_service_endpoints" {
  type        = list(string)
  default     = []
  description = "Optional service endpoints on the Databricks host and container subnets (e.g. [\"Microsoft.Storage\"])."
}

variable "databricks_account_id" {
  type        = string
  description = "Existing Databricks account ID (Account Console URL). Required for NCC / serverless DBFS Private Link rules per upstream reference."
}

variable "metastore_id" {
  type        = string
  default     = ""
  description = "Optional Unity Catalog metastore UUID to assign via account API. Leave empty to skip."
}

variable "enable_browser_authentication_private_endpoint" {
  type        = bool
  default     = true
  description = "End-to-end Private Link: create a private endpoint for subresource browser_authentication (SSO callbacks). Recommended when public_network_access_enabled is false."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags applied to Azure resources that support tags."
}
