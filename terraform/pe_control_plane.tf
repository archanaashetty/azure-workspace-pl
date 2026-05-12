# Control-plane Private Link targets (End-to-end): UI/API + browser authentication (SSO callbacks).
# Reference: https://github.com/databricks-solutions/technical-services-solutions/.../tf/pe_backend.tf
# Browser auth PE: https://learn.microsoft.com/azure/databricks/security/network/front-end/front-end-private-connect

resource "azurerm_private_endpoint" "dp_dpcp_ui" {
  name                = "pep-${local.prefix}-dp-dpcp-ui"
  location            = local.dp_rg_location
  resource_group_name = local.dp_rg_name
  subnet_id           = azurerm_subnet.private_endpoints.id
  tags                = local.tags

  private_service_connection {
    name                           = "ple-${local.prefix}-dp-dpcp-ui"
    private_connection_resource_id = azurerm_databricks_workspace.dp_workspace.id
    is_manual_connection           = false
    subresource_names              = ["databricks_ui_api"]
  }

  private_dns_zone_group {
    name                 = "pdnsgrp-${local.prefix}-dp-dpcp-ui"
    private_dns_zone_ids = [azurerm_private_dns_zone.control_plane.id]
  }

  depends_on = [
    azurerm_private_dns_zone_virtual_network_link.control_plane,
    azurerm_databricks_workspace.dp_workspace,
  ]
}

resource "azurerm_private_endpoint" "dp_dpcp_browser" {
  count = var.enable_browser_authentication_private_endpoint ? 1 : 0

  name                = "pep-${local.prefix}-dp-dpcp-browser"
  location            = local.dp_rg_location
  resource_group_name = local.dp_rg_name
  subnet_id           = azurerm_subnet.private_endpoints.id
  tags                = merge(local.tags, { purpose = "browser_authentication" })

  private_service_connection {
    name                           = "ple-${local.prefix}-dp-dpcp-browser"
    private_connection_resource_id = azurerm_databricks_workspace.dp_workspace.id
    is_manual_connection           = false
    subresource_names              = ["browser_authentication"]
  }

  private_dns_zone_group {
    name                 = "pdnsgrp-${local.prefix}-dp-dpcp-browser"
    private_dns_zone_ids = [azurerm_private_dns_zone.control_plane.id]
  }

  depends_on = [
    azurerm_private_dns_zone_virtual_network_link.control_plane,
    azurerm_databricks_workspace.dp_workspace,
  ]
}
