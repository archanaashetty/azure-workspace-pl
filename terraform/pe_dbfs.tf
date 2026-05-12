# DBFS private endpoints — same pattern as upstream pe_dbfs.tf

resource "azurerm_private_endpoint" "dp_dbfspe_dfs" {
  name                = "pep-${local.prefix}-dp-dbfs-dfs"
  location            = local.dp_rg_location
  resource_group_name = local.dp_rg_name
  subnet_id           = azurerm_subnet.private_endpoints.id
  tags                = local.tags

  private_service_connection {
    name                           = "ple-${local.prefix}-dp-dbfs-dfs"
    private_connection_resource_id = "${azurerm_databricks_workspace.dp_workspace.managed_resource_group_id}/providers/Microsoft.Storage/storageAccounts/${local.dbfsname}"
    is_manual_connection           = false
    subresource_names              = ["dfs"]
  }

  private_dns_zone_group {
    name                 = "pdnsgrp-${local.prefix}-dp-dfs"
    private_dns_zone_ids = [azurerm_private_dns_zone.dbfs_dfs.id]
  }

  depends_on = [
    azurerm_private_dns_zone_virtual_network_link.dbfs_dfs,
    azurerm_databricks_workspace.dp_workspace,
  ]
}

resource "azurerm_private_endpoint" "dp_dbfspe_blob" {
  name                = "pep-${local.prefix}-dp-dbfs-blob"
  location            = local.dp_rg_location
  resource_group_name = local.dp_rg_name
  subnet_id           = azurerm_subnet.private_endpoints.id
  tags                = local.tags

  private_service_connection {
    name                           = "ple-${local.prefix}-dp-dbfs-blob"
    private_connection_resource_id = "${azurerm_databricks_workspace.dp_workspace.managed_resource_group_id}/providers/Microsoft.Storage/storageAccounts/${local.dbfsname}"
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }

  private_dns_zone_group {
    name                 = "pdnsgrp-${local.prefix}-dp-blob"
    private_dns_zone_ids = [azurerm_private_dns_zone.dbfs_blob.id]
  }

  depends_on = [
    azurerm_private_dns_zone_virtual_network_link.dbfs_blob,
    azurerm_databricks_workspace.dp_workspace,
  ]
}
