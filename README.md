# Azure Databricks — isolated workspace with Private Link

Terraform that deploys an **Azure Databricks Premium** workspace into an **existing virtual network**, with **end-to-end Private Link** (workspace public network access disabled), **two /22 subnets** for Databricks (host and container), a **separate private endpoint subnet** whose **prefix length you choose** (for example `/26`), **NAT** and **NSG** for the Databricks subnets, **private DNS zones**, **private endpoints** (control plane UI/API, optional browser authentication, DBFS blob/dfs), and **account-level Network Connectivity Config (NCC)** with automatic approval of serverless private endpoint connections on the workspace root storage account.

The layout and behaviour are adapted from the Databricks Solutions example [azure-privatelink-classic](https://github.com/databricks-solutions/technical-services-solutions/tree/main/workspace-setup/terraform-examples/azure/azure-privatelink-classic) (existing VNet variant, E2E Private Link, no customer-managed keys in this template).

Repository: [https://github.com/archanaashetty/azure-workspace-pl](https://github.com/archanaashetty/azure-workspace-pl)

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) **>= 1.3**
- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) and a signed-in identity (`az login`), or equivalent **service principal** / OIDC variables for CI/CD
- **Azure subscription** access: **Contributor** or **Owner** at **subscription** scope is strongly recommended (Databricks creates a managed resource group; subscription-level permissions avoid surprise failures)
- An **existing** Databricks **account** and **account admin** access for account APIs (NCC, optional metastore assignment)
- An **existing** resource group for **workload** resources (workspace, DNS zones, private endpoints, NAT, NSG), in the **same region** as the target VNet
- An **existing** virtual network with enough **unused, non-overlapping** address space for **two /22** ranges (Databricks) plus your chosen **private endpoint** subnet CIDR (often **`/26`** for a dedicated PE subnet; any valid size that fits is allowed)

## What this stack creates

| Area | Resources |
|------|-------------|
| **Network** (in your VNet’s resource group) | Two **`/22`** subnets for Databricks **host** and **container**, plus one **configurable-size** subnet for **private endpoints**; **NSG** + outbound rules (Azure AD, Azure Front Door); **NAT gateway** + public IP on the two Databricks subnets |
| **Workload RG** | Databricks **workspace** (Premium, VNet-injected, public network access **off**, storage firewall + access connector), **private DNS zones** + VNet links, **private endpoints**, **NCC** rules and **azapi** approval of storage private endpoint connections |
| **Account** (via Databricks provider) | **NCC**, optional **Unity Catalog metastore** assignment |

Subnets are validated at plan/apply time to sit inside the VNet `address_space`. **You** must pick **non-overlapping** CIDRs: two **`/22`** blocks for Databricks and one block for private endpoints (any valid IPv4 CIDR that fits your design; `/26` is a common size for a dedicated private endpoint subnet).

## Quick start

1. **Clone** this repository.

   ```bash
   git clone https://github.com/archanaashetty/azure-workspace-pl.git
   cd azure-workspace-pl/terraform
   ```

2. **Authenticate** to Azure (interactive example).

   ```bash
   az login
   az account set --subscription "<your-subscription-id>"
   ```

3. **Configure variables** by copying the example file and editing real values.

   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

   Do **not** commit `terraform.tfvars` (it can hold sensitive IDs). It is listed in `.gitignore`.

4. **Initialize** and **apply** Terraform.

   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

5. **Read outputs** after a successful apply.

   ```bash
   terraform output
   terraform output -raw workspace_url
   ```

## Input variables

| Variable | Required | Description |
|----------|----------|-------------|
| `az_subscription` | Yes | Azure subscription ID (used by the `azurerm` 4.x provider). |
| `workload_resource_group_name` | Yes | Existing RG where the workspace, DNS, PEs, NAT, and NSG are created. **Region must match the VNet.** |
| `virtual_network_resource_group_name` | Yes | RG that contains the target VNet. |
| `virtual_network_name` | Yes | Existing VNet name; subnets and DNS links target this VNet. |
| `subnet_cidr_databricks_host` | Yes | `/22` CIDR for the Databricks **host** subnet (delegated). |
| `subnet_cidr_databricks_container` | Yes | `/22` CIDR for the Databricks **container** subnet (delegated). |
| `subnet_cidr_private_endpoints` | Yes | IPv4 CIDR for the **private endpoint** subnet only (not delegated); prefix length is **not** required to be `/22` (e.g. `10.0.8.0/26`). |
| `databricks_account_id` | Yes | Databricks account ID (from `https://accounts.azuredatabricks.net/accounts/<id>`). |
| `resource_prefix` | No (default `databricks-workspace`) | Prefix for names; also drives the derived DBFS storage account name. |
| `subnets_service_endpoints` | No | Optional list of service endpoints on the two Databricks subnets (e.g. `["Microsoft.Storage"]`). |
| `metastore_id` | No | Unity Catalog metastore UUID to assign to the workspace; leave `""` to skip. |
| `enable_browser_authentication_private_endpoint` | No (default `true`) | Extra private endpoint for `browser_authentication` (recommended for SSO with public access disabled). |
| `tags` | No | Map of tags for supported Azure resources. |

See `terraform.tfvars.example` for a filled-out skeleton.

## Repository layout

```text
terraform/
  versions.tf          # Terraform and provider pins
  providers.tf         # azurerm, azapi, databricks (account)
  azure.tf             # Data source: workload resource group
  data.tf              # Client config + target VNet
  main.tf              # Shared locals (prefix, DBFS name, association IDs)
  network.tf           # Databricks /22 subnets, PE subnet, NSG, NAT
  databricks.tf        # Access connector + workspace
  dns_zones.tf         # Private DNS zones + VNet links
  pe_control_plane.tf  # Private endpoints: databricks_ui_api + browser_authentication
  pe_dbfs.tf           # Private endpoints: DBFS dfs + blob
  ncc.tf               # NCC, rules, sleep, azapi PE approvals
  variables.tf
  outputs.tf
  terraform.tfvars.example
  .gitignore
```

## Post-deployment checks

- Open the workspace only from a path that can resolve **private DNS** for `privatelink.azuredatabricks.net` and reach the private endpoints (jump box, VPN, etc.).
- As in the [upstream README](https://github.com/databricks-solutions/technical-services-solutions/blob/main/workspace-setup/terraform-examples/azure/azure-privatelink-classic/README.md), validating with a **classic** (non–high-concurrency) cluster reaching **Running** is a strong signal that VNet injection, egress, and Private Link paths are behaving as expected.

## Destroy

```bash
terraform destroy
```

Destruction can take several minutes. Ensure nothing else depends on the same subnets, NSG, NAT, or DNS zones. NCC is tied to the workspace; follow destroy ordering Terraform computes (re-run `terraform destroy` if a partial destroy leaves dependencies).

## References

- [Databricks Solutions — azure-privatelink-classic](https://github.com/databricks-solutions/technical-services-solutions/tree/main/workspace-setup/terraform-examples/azure/azure-privatelink-classic)
- [Configure a workspace with Private Link (classic) — Azure Databricks](https://learn.microsoft.com/azure/databricks/security/network/classic/private-link)
- [Terraform azurerm_databricks_workspace](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/databricks_workspace)
- [Terraform databricks provider (account)](https://registry.terraform.io/providers/databricks/databricks/latest/docs)

## Disclaimer

This repository is a **field-style template**, not a formally supported Databricks product. Review against your security and compliance requirements before production use.
