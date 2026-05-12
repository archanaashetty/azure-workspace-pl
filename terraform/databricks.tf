# -----------------------------------------------------------------------------
# Deployment checklist (customer requirements) — map to Terraform:
# - Existing Databricks account: var.databricks_account_id (no account creation here).
# - Premium: sku = premium.
# - Isolated + End-to-end Private Link: public_network_access_enabled = false + UI + browser auth PEs.
# - No custom DNS: Azure Private DNS zones in dns_zones.tf (privatelink.*), linked to existing VNet.
# - No IP ACL: do not configure workspace IP access lists in this template.
# - No CMK: customer_managed_key_enabled = false.
# - UK Cyber Essentials Plus: enable in Account/Workspace per Microsoft docs if licensed; Terraform support
#   may require azapi preview API — confirm with your Databricks/CSM before relying on automation.
# -----------------------------------------------------------------------------

resource "azurerm_databricks_access_connector" "dbfs" {
  name                = "dbac-${local.prefix}-dbfs"
  resource_group_name = local.dp_rg_name
  location            = local.dp_rg_location
  tags                = local.tags

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_databricks_workspace" "dp_workspace" {
  name                = local.workspace_name_effective
  resource_group_name = local.dp_rg_name
  location            = local.dp_rg_location
  sku                 = "premium"
  tags                = local.tags

  # End-to-end Private Link: disable public access to the workspace control plane / UI entrypoints.
  public_network_access_enabled = false

  network_security_group_rules_required = "NoAzureDatabricksRules"

  # Checklist: CMK not required.
  customer_managed_key_enabled = false

  managed_resource_group_name      = "mrg-dbw-${local.prefix}-dp"
  default_storage_firewall_enabled = true
  access_connector_id              = azurerm_databricks_access_connector.dbfs.id

  custom_parameters {
    virtual_network_id                                   = data.azurerm_virtual_network.this.id
    public_subnet_name                                   = azurerm_subnet.databricks_host.name
    private_subnet_name                                  = azurerm_subnet.databricks_container.name
    public_subnet_network_security_group_association_id  = local.public_subnet_network_security_group_association_id
    private_subnet_network_security_group_association_id = local.private_subnet_network_security_group_association_id
    storage_account_name                                 = local.dbfsname
  }

  depends_on = [
    azurerm_subnet_network_security_group_association.databricks_host,
    azurerm_subnet_network_security_group_association.databricks_container,
    azurerm_subnet_nat_gateway_association.databricks_host,
    azurerm_subnet_nat_gateway_association.databricks_container,
    databricks_mws_network_connectivity_config.ncc,
  ]

  lifecycle {
    precondition {
      condition     = local.vnet_id_from_dbx_public_subnet == data.azurerm_virtual_network.this.id && local.vnet_id_from_dbx_private_subnet == data.azurerm_virtual_network.this.id
      error_message = "The Databricks public and private subnets must belong to the virtual network specified by virtual_network_name and virtual_network_resource_group_name."
    }
    precondition {
      condition     = local.vnet_id_from_pe_subnet == data.azurerm_virtual_network.this.id
      error_message = "The private endpoints subnet must be in the same virtual network as the Databricks delegation subnets."
    }
    precondition {
      condition     = data.azurerm_resource_group.workload.location == data.azurerm_virtual_network.this.location
      error_message = "The workload resource group must be in the same Azure region as the target virtual network for location alignment."
    }
  }
}

resource "databricks_metastore_assignment" "dp_workspace" {
  count = length(trimspace(var.metastore_id)) > 0 ? 1 : 0

  provider     = databricks.account
  workspace_id = azurerm_databricks_workspace.dp_workspace.workspace_id
  metastore_id = var.metastore_id
  depends_on   = [azurerm_databricks_workspace.dp_workspace]
}
