# Data Providers block
data "azuread_client_config" "current" {}
data "azuread_application_published_app_ids" "well_known" {}

# Resource group to contain Azure Resources built by Terraform
resource "azurerm_resource_group" "azb2c_rg" {
  name     = var.resource_group_name
  location = var.location
}

# Builds out the Azure AD B2c Tenant
# Warning! Once the tenant is built, it must be MANUALLY deleted
# https://learn.microsoft.com/en-us/azure/active-directory-b2c/tutorial-create-tenant
resource "azurerm_aadb2c_directory" "azb2c_tenant" {
  resource_group_name     = azurerm_resource_group.azb2c_rg.name
  display_name            = "b2c-aadb2c-us"
  domain_name             = var.domain_name
  country_code            = "US"
  data_residency_location = "United States"
  sku_name                = "PremiumP2"
}

# Create an Application Registration used for application login in Azure B2C Directory
# https://learn.microsoft.com/en-us/azure/active-directory-b2c/tutorial-register-applications?tabs=app-reg-ga
resource "azuread_application" "general" {
  display_name    = var.app_display_name
  identifier_uris = ["api://testit22"]
  #logo_image       = filebase64("/path/to/logo.png")
  owners           = [data.azuread_client_config.current.object_id]
  sign_in_audience = "AzureADMultipleOrgs"
  web {
    redirect_uris = ["https://jwt.ms/"]
    implicit_grant {
      access_token_issuance_enabled = true
      id_token_issuance_enabled     = true
    }
  }

  required_resource_access {
    resource_app_id = data.azuread_application_published_app_ids.well_known.result.MicrosoftGraph

    resource_access {
      id   = azuread_service_principal.msgraph.app_role_ids["IdentityUserFlow.ReadWrite.All"]
      type = "Scope"
    }

    resource_access {
      id   = azuread_service_principal.msgraph.app_role_ids["Organization.ReadWrite.All"]
      type = "Scope"
    }

    resource_access {
      id   = azuread_service_principal.msgraph.app_role_ids["Application.Read.All"]
      type = "Scope"
    }

    resource_access {
      id   = azuread_service_principal.msgraph.app_role_ids["Application.ReadWrite.All"]
      type = "Scope"
    }

    resource_access {
      id   = azuread_service_principal.msgraph.app_role_ids["Policy.ReadWrite.ConditionalAccess"]
      type = "Scope"
    }
    
    resource_access {
      id   = azuread_service_principal.msgraph.oauth2_permission_scope_ids["offline_access"]
      type = "Scope"
    }

    resource_access {
      id   = azuread_service_principal.msgraph.oauth2_permission_scope_ids["openid"]
      type = "Scope"
    }
  }

  depends_on = [ azurerm_aadb2c_directory.azb2c_tenant ]
}

# Required to get the Application's Object ID for Granting Admin Consent
resource "azuread_service_principal" "msgraph" {
  client_id    = data.azuread_application_published_app_ids.well_known.result.MicrosoftGraph
  use_existing = true
}

# Required to get the new Application Registration's Object Id
resource "azuread_service_principal" "general" {
  client_id = azuread_application.general.client_id
}

# Grant Admin Consent for OpenID and Offline Access to the 
# Application Registered.
resource "azuread_service_principal_delegated_permission_grant" "general" {
  service_principal_object_id = azuread_service_principal.general.object_id
  resource_service_principal_object_id = azuread_service_principal.msgraph.object_id
  claim_values = [ "openid", "offline_access" ]
}

## Azure AD B2C App registration client secret generation

resource "time_rotating" "general" {
  rotation_days = 365
}

resource "azuread_application_password" "general" {
  application_id  = azuread_application.general.id
  rotate_when_changed = {
    rotation = time_rotating.general.id
  }
}

resource "azuread_conditional_access_policy" "general" {
  display_name = var.cap_policy_name
  state        = var.cap_state

  conditions {
    client_app_types    = ["all"]
    sign_in_risk_levels = ["medium"]
    user_risk_levels    = ["medium"]

    applications {
      included_applications = ["All"]
      excluded_applications = []
    }

    locations {
      included_locations = ["All"]
      excluded_locations = ["AllTrusted"]
    }

    platforms {
      included_platforms = ["all"]
      excluded_platforms = ["unknownFutureValue"]
    }

    users {
      included_users = ["All"]
      excluded_users = ["GuestsOrExternalUsers"]
    }
  }

  grant_controls {
    operator          = "OR"
    built_in_controls = ["mfa"]
  }

}