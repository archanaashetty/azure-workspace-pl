# Aligned with: https://github.com/databricks-solutions/technical-services-solutions/tree/main/workspace-setup/terraform-examples/azure/azure-privatelink-classic
# This fork uses an EXISTING VNet with Terraform-created subnets (Databricks /22 + configurable PE subnet) and End-to-end Private Link (public_network_access_enabled = false).

terraform {
  required_version = ">= 1.3.0"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 1.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0.0, < 5.0.0"
    }
    databricks = {
      source  = "databricks/databricks"
      version = ">= 1.28.0, < 2.0.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9"
    }
  }
}
