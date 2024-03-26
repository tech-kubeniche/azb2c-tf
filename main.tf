
provider "azurerm" {
  features {}
}

module "azuread_b2c" {
  source              = "./azuread_b2c"
  app_display_name    = var.app_display_name
  domain_name         = var.domain_name
  resource_group_name = var.resource_group_name
  location            = var.location
  cap_policy_name     = var.cap_policy_name
  cap_state           = var.cap_state
}


resource "null_resource" "configure_user_flows" {

  depends_on = [module.azuread_b2c]
  # Install Chocolatey
  provisioner "local-exec" {
    interpreter = ["C:\\Program Files\\PowerShell\\7\\pwsh.exe", "-Command"]
    command     = ".\\Deploy-AzureADB2C-UFA.ps1 -AADB2C_PROVISION_CLIENT_ID ${module.azuread_b2c.client_id} -AADB2C_PROVISION_CLIENT_SECRET ${module.azuread_b2c.password} -AADB2C_DOMAINNAME ${module.azuread_b2c.azb2c_domain_name}"
  }
}