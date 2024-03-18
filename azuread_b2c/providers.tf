provider "azurerm" {
  features {}
  #client_id       = "207f5f0d-d816-4990-ab6e-c60d1627004b"
  #client_secret   = "zPi8Q~5zmoULLDlawm_eQEHZ09nGeT7GpJke2c0J"
  tenant_id       = "d0e04d1a-c235-4e82-9c8e-2c59a1c170fe"
  subscription_id = "7329e524-d61a-477f-ae2a-2ffae3114108"
}

provider "azuread" {
  tenant_id = azurerm_aadb2c_directory.azb2c_tenant.tenant_id
}