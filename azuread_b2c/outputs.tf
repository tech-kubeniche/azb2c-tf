output "client_id" {
  value       = azuread_application.general.client_id
  description = "The Client ID of the application."
}

output "object_id" {
  value       = azuread_application.general.object_id
  description = "The object ID of the application."
}

output "password" {
  value       = azuread_application_password.general.value
  sensitive   = true
  description = "The password for the application."
}

output "azb2c_domain_name" {
  value       = azurerm_aadb2c_directory.azb2c_tenant.domain_name
  sensitive   = true
  description = "The full domain name of the azure b2c tenant."
}