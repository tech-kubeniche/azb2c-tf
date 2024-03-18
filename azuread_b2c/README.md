# Terraform: Deploy Azure AD B2C

Use Terraform to deploy Azure AD B2C

Terraform is designed to deploy the required resources necessary to bring up an Azure AD B2C tenant to be used for Identity as a Platform (IaP). I'm following as closely as I can to [Microsoft Learning](https://learn.microsoft.com/en-us/azure/active-directory-b2c/tutorial-create-tenant).

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.9 |
| <a name="requirement_azuread"></a> [azuread](#provider_azuread) | >= 2.36.0 |
| <a name="requirement_azurerm"></a> [azurerm](#provider_azurerm) | >= 3.51.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azuread"></a> [azuread](https://registry.terraform.io/providers/hashicorp/azuread/latest) | 2.36.0 |
| <a name="provider_azurerm"></a> [azurerm](https://registry.terraform.io/providers/hashicorp/azurerm/latest) | 3.51.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azuread_application.general](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/application) | resource |
| [azuread_service_principal.general](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/service_principal) | resource |
| [azuread_service_principal.msgraph](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/service_principal) | resource |
| [azuread_service_principal_delegated_permission_grant.general](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/service_principal_delegated_permission_grant) | resource |
| [azurerm_aadb2c_directory.tutorial_tenant](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/aadb2c_directory) | resource |
| [azurerm_resource_group.azb2c_tutorial](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |
| [azuread_application_published_app_ids.well_known](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/data-sources/application_published_app_ids) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_app_display_name"></a> [app\_display\_name](#input\_app\_display\_name) | Provides the name for an Application Registration. | `string` | n/a | yes |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | Used to define the Azure AD B2C domain URL. Must be globally unique. | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->