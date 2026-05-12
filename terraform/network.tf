# Subnets, NSG, and NAT inside the customer-provided VNet (Databricks Solutions reference pattern).
# https://github.com/databricks-solutions/technical-services-solutions/blob/main/workspace-setup/terraform-examples/azure/azure-privatelink-classic/tf/network.tf

locals {
  # IPv4-only containment check (no cidrcontains — compatible with all Terraform 1.x builds).
  _vnet_address_spaces = data.azurerm_virtual_network.this.address_space

  databricks_host_cidr_in_vnet = anytrue([
    for space in local._vnet_address_spaces :
    length(split(".", cidrhost(space, 0))) == 4 && length(split(".", cidrhost(var.subnet_cidr_databricks_host, 0))) == 4
    && tonumber(split("/", var.subnet_cidr_databricks_host)[1]) >= tonumber(split("/", space)[1])
    && floor(
      (tonumber(split(".", cidrhost(var.subnet_cidr_databricks_host, 0))[0]) * 16777216
        + tonumber(split(".", cidrhost(var.subnet_cidr_databricks_host, 0))[1]) * 65536
        + tonumber(split(".", cidrhost(var.subnet_cidr_databricks_host, 0))[2]) * 256
        + tonumber(split(".", cidrhost(var.subnet_cidr_databricks_host, 0))[3]))
      / pow(2, 32 - tonumber(split("/", space)[1]))
    ) == floor(
      (tonumber(split(".", cidrhost(space, 0))[0]) * 16777216
        + tonumber(split(".", cidrhost(space, 0))[1]) * 65536
        + tonumber(split(".", cidrhost(space, 0))[2]) * 256
        + tonumber(split(".", cidrhost(space, 0))[3]))
      / pow(2, 32 - tonumber(split("/", space)[1]))
    )
  ])

  databricks_container_cidr_in_vnet = anytrue([
    for space in local._vnet_address_spaces :
    length(split(".", cidrhost(space, 0))) == 4 && length(split(".", cidrhost(var.subnet_cidr_databricks_container, 0))) == 4
    && tonumber(split("/", var.subnet_cidr_databricks_container)[1]) >= tonumber(split("/", space)[1])
    && floor(
      (tonumber(split(".", cidrhost(var.subnet_cidr_databricks_container, 0))[0]) * 16777216
        + tonumber(split(".", cidrhost(var.subnet_cidr_databricks_container, 0))[1]) * 65536
        + tonumber(split(".", cidrhost(var.subnet_cidr_databricks_container, 0))[2]) * 256
        + tonumber(split(".", cidrhost(var.subnet_cidr_databricks_container, 0))[3]))
      / pow(2, 32 - tonumber(split("/", space)[1]))
    ) == floor(
      (tonumber(split(".", cidrhost(space, 0))[0]) * 16777216
        + tonumber(split(".", cidrhost(space, 0))[1]) * 65536
        + tonumber(split(".", cidrhost(space, 0))[2]) * 256
        + tonumber(split(".", cidrhost(space, 0))[3]))
      / pow(2, 32 - tonumber(split("/", space)[1]))
    )
  ])

  private_endpoints_cidr_in_vnet = anytrue([
    for space in local._vnet_address_spaces :
    length(split(".", cidrhost(space, 0))) == 4 && length(split(".", cidrhost(var.subnet_cidr_private_endpoints, 0))) == 4
    && tonumber(split("/", var.subnet_cidr_private_endpoints)[1]) >= tonumber(split("/", space)[1])
    && floor(
      (tonumber(split(".", cidrhost(var.subnet_cidr_private_endpoints, 0))[0]) * 16777216
        + tonumber(split(".", cidrhost(var.subnet_cidr_private_endpoints, 0))[1]) * 65536
        + tonumber(split(".", cidrhost(var.subnet_cidr_private_endpoints, 0))[2]) * 256
        + tonumber(split(".", cidrhost(var.subnet_cidr_private_endpoints, 0))[3]))
      / pow(2, 32 - tonumber(split("/", space)[1]))
    ) == floor(
      (tonumber(split(".", cidrhost(space, 0))[0]) * 16777216
        + tonumber(split(".", cidrhost(space, 0))[1]) * 65536
        + tonumber(split(".", cidrhost(space, 0))[2]) * 256
        + tonumber(split(".", cidrhost(space, 0))[3]))
      / pow(2, 32 - tonumber(split("/", space)[1]))
    )
  ])
}

resource "azurerm_public_ip" "databricks_nat" {
  name                = "pip-${local.prefix}-dbx-nat"
  location            = local.dp_rg_location
  resource_group_name = local.dp_rg_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.tags
}

resource "azurerm_nat_gateway" "databricks" {
  name                    = "ng-${local.prefix}-dbx-nat"
  location                = local.dp_rg_location
  resource_group_name     = local.dp_rg_name
  sku_name                = "Standard"
  idle_timeout_in_minutes = 10
  tags                    = local.tags
}

resource "azurerm_nat_gateway_public_ip_association" "databricks" {
  nat_gateway_id       = azurerm_nat_gateway.databricks.id
  public_ip_address_id = azurerm_public_ip.databricks_nat.id
}

resource "azurerm_network_security_group" "databricks" {
  name                = "nsg-${local.prefix}-dbx"
  location            = local.dp_rg_location
  resource_group_name = local.dp_rg_name
  tags                = local.tags
}

resource "azurerm_network_security_rule" "databricks_aad" {
  name                        = "nsgsr-${local.prefix}-dbx-aad"
  priority                    = 200
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "VirtualNetwork"
  destination_address_prefix  = "AzureActiveDirectory"
  resource_group_name         = local.dp_rg_name
  network_security_group_name = azurerm_network_security_group.databricks.name
}

resource "azurerm_network_security_rule" "databricks_frontdoor" {
  name                        = "nsgsr-${local.prefix}-dbx-afd"
  priority                    = 201
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "VirtualNetwork"
  destination_address_prefix  = "AzureFrontDoor.Frontend"
  resource_group_name         = local.dp_rg_name
  network_security_group_name = azurerm_network_security_group.databricks.name
}

resource "azurerm_subnet" "databricks_host" {
  name                 = "snet-${local.prefix}-dbx-host"
  resource_group_name  = var.virtual_network_resource_group_name
  virtual_network_name = var.virtual_network_name
  address_prefixes     = [var.subnet_cidr_databricks_host]

  delegation {
    name = "databricks"
    service_delegation {
      name = "Microsoft.Databricks/workspaces"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
        "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action",
      ]
    }
  }

  service_endpoints = var.subnets_service_endpoints

  lifecycle {
    precondition {
      condition     = local.databricks_host_cidr_in_vnet
      error_message = "The subnet_cidr_databricks_host CIDR must fall within the virtual network IPv4 address space."
    }
  }
}

resource "azurerm_subnet" "databricks_container" {
  name                 = "snet-${local.prefix}-dbx-container"
  resource_group_name  = var.virtual_network_resource_group_name
  virtual_network_name = var.virtual_network_name
  address_prefixes     = [var.subnet_cidr_databricks_container]

  private_endpoint_network_policies = "Enabled"

  delegation {
    name = "databricks"
    service_delegation {
      name = "Microsoft.Databricks/workspaces"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
        "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action",
      ]
    }
  }

  service_endpoints = var.subnets_service_endpoints

  lifecycle {
    precondition {
      condition     = local.databricks_container_cidr_in_vnet
      error_message = "The subnet_cidr_databricks_container CIDR must fall within the virtual network IPv4 address space."
    }
  }
}

resource "azurerm_subnet" "private_endpoints" {
  name                 = "snet-${local.prefix}-dbx-pe"
  resource_group_name  = var.virtual_network_resource_group_name
  virtual_network_name = var.virtual_network_name
  address_prefixes     = [var.subnet_cidr_private_endpoints]

  private_endpoint_network_policies = "Enabled"

  lifecycle {
    precondition {
      condition     = local.private_endpoints_cidr_in_vnet
      error_message = "The subnet_cidr_private_endpoints CIDR must fall within the virtual network IPv4 address space."
    }
  }
}

resource "azurerm_subnet_network_security_group_association" "databricks_host" {
  subnet_id                 = azurerm_subnet.databricks_host.id
  network_security_group_id = azurerm_network_security_group.databricks.id
}

resource "azurerm_subnet_network_security_group_association" "databricks_container" {
  subnet_id                 = azurerm_subnet.databricks_container.id
  network_security_group_id = azurerm_network_security_group.databricks.id
}

resource "azurerm_subnet_nat_gateway_association" "databricks_host" {
  subnet_id      = azurerm_subnet.databricks_host.id
  nat_gateway_id = azurerm_nat_gateway.databricks.id
}

resource "azurerm_subnet_nat_gateway_association" "databricks_container" {
  subnet_id      = azurerm_subnet.databricks_container.id
  nat_gateway_id = azurerm_nat_gateway.databricks.id
}
