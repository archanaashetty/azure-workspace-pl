# Locals mirror upstream naming: https://github.com/databricks-solutions/technical-services-solutions/.../azure-privatelink-classic/tf/main.tf

locals {
  prefix   = var.resource_prefix
  dbfsname = "dbfs${substr(join("", regexall("[a-z0-9]", lower(var.resource_prefix))), 0, 20)}"
  tags     = var.tags

  # Optional explicit workspace name; otherwise same pattern as upstream (dbw-<prefix>-dp).
  workspace_name_effective = trimspace(try(var.workspace_name, "")) != "" ? trimspace(var.workspace_name) : "dbw-${local.prefix}-dp"

  dp_rg_name     = data.azurerm_resource_group.workload.name
  dp_rg_id       = data.azurerm_resource_group.workload.id
  dp_rg_location = data.azurerm_resource_group.workload.location

  # Parent VNet ARM ID derived from subnet resource IDs (azurerm 4.x subnet data source has no virtual_network_id attribute).
  vnet_id_from_dbx_public_subnet  = "/${join("/", slice(split("/", trimprefix(azurerm_subnet.databricks_host.id, "/")), 0, 8))}"
  vnet_id_from_dbx_private_subnet = "/${join("/", slice(split("/", trimprefix(azurerm_subnet.databricks_container.id, "/")), 0, 8))}"
  vnet_id_from_pe_subnet          = "/${join("/", slice(split("/", trimprefix(azurerm_subnet.private_endpoints.id, "/")), 0, 8))}"

  # Databricks custom_parameters expect the subnet–NSG association resource IDs (see azurerm_subnet_network_security_group_association).
  public_subnet_network_security_group_association_id  = azurerm_subnet_network_security_group_association.databricks_host.id
  private_subnet_network_security_group_association_id = azurerm_subnet_network_security_group_association.databricks_container.id
}
