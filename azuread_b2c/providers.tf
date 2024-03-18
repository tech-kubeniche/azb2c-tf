provider "azurerm" {
  features {}
}

provider "azuread" {
  tenant_id = azurerm_aadb2c_directory.azb2c_tenant.tenant_id
}