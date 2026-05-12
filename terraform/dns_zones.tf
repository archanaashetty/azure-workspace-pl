# Same zone layout as upstream reference; zones are linked to the customer EXISTING VNet.

resource "azurerm_private_dns_zone" "control_plane" {
  name                = "privatelink.azuredatabricks.net"
  resource_group_name = local.dp_rg_name
  tags                = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "control_plane" {
  name                  = "lnk-${local.prefix}-dp-control-plane"
  resource_group_name   = local.dp_rg_name
  private_dns_zone_name = azurerm_private_dns_zone.control_plane.name
  virtual_network_id    = data.azurerm_virtual_network.this.id
  registration_enabled  = false
  tags                  = local.tags
}

resource "azurerm_private_dns_zone" "dbfs_dfs" {
  name                = "privatelink.dfs.core.windows.net"
  resource_group_name = local.dp_rg_name
  tags                = local.tags
}

resource "azurerm_private_dns_zone" "dbfs_blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = local.dp_rg_name
  tags                = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "dbfs_dfs" {
  name                  = "lnk-${local.prefix}-dp-dbfs-dfs"
  resource_group_name   = local.dp_rg_name
  private_dns_zone_name = azurerm_private_dns_zone.dbfs_dfs.name
  virtual_network_id    = data.azurerm_virtual_network.this.id
  registration_enabled  = false
  tags                  = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "dbfs_blob" {
  name                  = "lnk-${local.prefix}-dp-dbfs-blob"
  resource_group_name   = local.dp_rg_name
  private_dns_zone_name = azurerm_private_dns_zone.dbfs_blob.name
  virtual_network_id    = data.azurerm_virtual_network.this.id
  registration_enabled  = false
  tags                  = local.tags
}
