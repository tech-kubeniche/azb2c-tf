variable "resource_group_name" {
  type        = string
  description = "Provide the Azure Resource Group Name to create the Azure B2C resource under it."
}
variable "location" {
  type        = string
  description = "Provide the Location for the Azure Resource Group."
  default     = "eastus"
}
variable "domain_name" {
  type        = string
  description = "Used to define the Azure AD B2C domain URL. Must be globally unique."
}

variable "app_display_name" {
  type        = string
  description = "Provides the name for an Application Registration."
}