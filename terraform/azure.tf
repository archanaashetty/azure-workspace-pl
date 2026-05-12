# Resource group that will hold the workspace, access connector, Private DNS zones, private endpoints, etc.
# Must already exist (customer-managed), per deployment checklist.

data "azurerm_resource_group" "workload" {
  name = var.workload_resource_group_name
}
