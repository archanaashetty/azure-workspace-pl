output "workspace_url" {
  value       = azurerm_databricks_workspace.dp_workspace.workspace_url
  description = "Databricks workspace URL (Private Link / private DNS must resolve from your client)."
}

output "workspace_id" {
  value       = azurerm_databricks_workspace.dp_workspace.workspace_id
  description = "Databricks workspace ID (GUID)."
}

output "resource_group_name" {
  value       = local.dp_rg_name
  description = "Workload resource group name."
}

output "resource_group_id" {
  value       = local.dp_rg_id
  description = "Workload resource group ID."
}

output "vnet_name" {
  value       = data.azurerm_virtual_network.this.name
  description = "Target virtual network name."
}

output "vnet_id" {
  value       = data.azurerm_virtual_network.this.id
  description = "Target virtual network ID."
}

output "subnet_public_id" {
  value       = azurerm_subnet.databricks_host.id
  description = "Databricks host (public delegation) subnet ID — /22 created by this stack."
}

output "subnet_private_id" {
  value       = azurerm_subnet.databricks_container.id
  description = "Databricks container (private delegation) subnet ID — /22 created by this stack."
}

output "subnet_privatelink_id" {
  value       = azurerm_subnet.private_endpoints.id
  description = "Private endpoint subnet ID (CIDR size set by subnet_cidr_private_endpoints)."
}

output "nat_gateway_id" {
  value       = azurerm_nat_gateway.databricks.id
  description = "NAT gateway attached to host and container subnets for outbound connectivity."
}

output "network_security_group_id" {
  value       = azurerm_network_security_group.databricks.id
  description = "NSG attached to Databricks host and container subnets."
}

output "ncc_id" {
  value       = databricks_mws_network_connectivity_config.ncc.network_connectivity_config_id
  description = "Network Connectivity Config ID created at account level."
}
