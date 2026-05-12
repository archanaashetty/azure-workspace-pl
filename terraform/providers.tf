# Azure auth: Azure CLI (`az login`) or ARM_* / OIDC for CI/CD.
# Databricks account provider: NCC + private endpoint rules (same pattern as upstream reference).

provider "azurerm" {
  features {}
  subscription_id = var.az_subscription
}

provider "azapi" {
}

provider "databricks" {
  alias           = "account"
  host            = "https://accounts.azuredatabricks.net"
  account_id      = var.databricks_account_id
  azure_tenant_id = data.azurerm_client_config.current.tenant_id
  # NCC rule creation can exceed default idle timeout.
  http_timeout_seconds = 300
}
