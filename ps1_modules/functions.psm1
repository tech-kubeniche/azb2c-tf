function Get-AzResourceIdIfExists(
  [Parameter(Mandatory = $true)]
  [string] $ResourceGroup,

  [Parameter(Mandatory = $true)]
  [string] $ResourceType,

  [Parameter(Mandatory = $true)]
  [string] $ResourceName
) {
  # Get the Azure resource
  $resource = Get-AzResource -ResourceGroupName $ResourceGroup -ResourceType $ResourceType -ResourceName $ResourceName -ErrorAction SilentlyContinue

  if ($resource) {
    # Return true to indicate that the resource was found
    return $resource.ResourceId
  }
  else {
    return $null
  }

}

function Set-AzADB2CUserFlows(
  [Parameter(Mandatory = $true)]
  [hashtable]$userFlows, 

  [Parameter(Mandatory = $true)]
  [securestring]$accessToken, 

  [Parameter(Mandatory = $true)]
  [string]$tenantDomain,

  [Parameter(Mandatory = $true)]
  [string]$tenantId
) {

  $plainaccessToken = ConvertFrom-SecureString -SecureString $accessToken -AsPlainText

  $headers = @{
    "Authorization" = "Bearer $($plainaccessToken)"
    "Content-Type"  = "application/json"
  }

  Write-Host "Applying Azure AD B2C user flows to $tenantDomain"
  $userFlowsCurrently = (Invoke-RestMethod -Uri "https://graph.microsoft.com/beta/identity/b2cUserFlows" -Headers $headers -Method GET -SkipHttpErrorCheck -Verbose:$false).value
  $userFlowsContent = $userFlows | ConvertTo-Json -Depth 100
  if ($userFlowsContent) {
    if (Test-Json $userFlowsContent) {
      $userFlowsObject = $userFlowsContent | ConvertFrom-Json -AsHashtable
      $userFlowsObject | ForEach-Object {

        if ($userFlowsCurrently.id -contains $_.id) {
          # Already exists, updating
          Write-Host "Updating $($_.id) as it already exists."

          # Remove All Keys not supported in patch
          $_.Remove("userFlowType")
          $_.Remove("userFlowTypeVersion")
          $_.Remove("apiConnectorConfiguration")
          $_.Remove("singleSignOnSessionConfiguration")
          $_.Remove("passwordComplexityConfiguration")

          $userFlowUpdate = Invoke-RestMethod -Uri "https://graph.microsoft.com/beta/identity/b2cUserFlows/$($_.id)" -Headers $headers -Method PATCH -Body ($_ | ConvertTo-Json) -SkipHttpErrorCheck -Verbose:$false
          if ($userFlowUpdate.PSObject.Properties['error']) {
            return $userFlowUpdate.error
          }
          else { 
            return $true
          }
        }
        else {
          # Is new, creating
          Write-Host "Creating $($_.id)"
          $userFlowNew = Invoke-RestMethod -Uri "https://graph.microsoft.com/beta/identity/b2cUserFlows" -Headers $headers -Method POST -Body ($_ | ConvertTo-Json) -SkipHttpErrorCheck -Verbose:$false
          if ($userFlowNew.PSObject.Properties['error']) {
            return $userFlowNew.error
          }
          else { 
            return $true
            "✅  Successfully created Azure AD B2C User Flow $($context.AzureADB2C.domainName)`r`n"
          }
        }
      }
    }
    else {
      return "Invalid JSON. Please correct this before trying again."
    }
  }
}

function Set-AzADB2CAppRegistrations(
  [Parameter(Mandatory = $true)]
  [hashtable]$appRegistrations, 

  [Parameter(Mandatory = $true)]
  [securestring]$accessToken, 

  [Parameter(Mandatory = $true)]
  [string]$tenantDomain,

  [Parameter(Mandatory = $true)]
  [string]$tenantId
) {

  $plainaccessToken = ConvertFrom-SecureString -SecureString $accessToken -AsPlainText

  $headers = @{
    "Authorization" = "Bearer $($plainaccessToken)"
    "Content-Type"  = "application/json"
  }
  $appRegistrationsCurrently = (Invoke-RestMethod -Uri "https://graph.microsoft.com/beta/applications" -Headers $headers -Method GET -SkipHttpErrorCheck -Verbose:$false).value
  $appRegistrationsContent = $appRegistrations | ConvertTo-Json -Depth 100
  if ($appRegistrationsContent) {
    if (Test-Json $appRegistrationsContent) {
      $appRegistrationsObject = $appRegistrationsContent | ConvertFrom-Json -AsHashtable
      $clientIds = @()
      $appRegistrationsObject | ForEach-Object {
        if ($appRegistrationsCurrently.displayName -contains $_.displayName) {
          Write-Host "📃  Azure AD B2C app registration $($_.displayName) already exists, updating it's configuration for idempotency."
          $value = $_.displayName
          $appId = ($appRegistrationsCurrently | Where-Object { $_.displayName -eq $value }).id
          $appRegistrationUpdate = Invoke-RestMethod -Uri "https://graph.microsoft.com/beta/applications/$appId" -Headers $headers -Method PATCH -Body ($_ | ConvertTo-Json -Depth 100) -SkipHttpErrorCheck -Verbose:$false
          if ($appRegistrationUpdate.PSObject.Properties['error']) {
            return $false, $appRegistrationUpdate.error
          }
          else {
            $clientIds += $appId
          }
        }
        else {
          Write-Host "📃  Azure AD B2C app registration $($_.displayName) does not exist. Creating new app registration."
          $appRegistration = Invoke-RestMethod -Uri "https://graph.microsoft.com/beta/applications" -Headers $headers -Method POST -Body ($_ | ConvertTo-Json -Depth 100) -SkipHttpErrorCheck -Verbose:$false
          if ($appRegistration.PSObject.Properties['error']) {
            return $false, $appRegistration.error
          }
          else {
            $clientIds += $appRegistration.id
          }
        }
      }
      return $true, $clientIds
    }
    else {
      return "Invalid JSON. Please correct this before trying again."
    }
  }
}
function Set-AzADB2CBranding(
  [Parameter(Mandatory = $true)]
  [hashtable]$branding, 

  [Parameter(Mandatory = $true)]
  [securestring]$accessToken, 

  [Parameter(Mandatory = $true)]
  [string]$tenantDomain,

  [Parameter(Mandatory = $false)]
  [string]$logoPath,

  [Parameter(Mandatory = $false)]
  [string]$backgroundPath,

  [Parameter(Mandatory = $true)]
  [string]$tenantId
) {

  $plainaccessToken = ConvertFrom-SecureString -SecureString $accessToken -AsPlainText

  $headers = @{
    "Authorization" = "Bearer $($plainaccessToken)"
    "Content-Type"  = "application/json"
  }

  # Branding 
  Write-Host "Applying Azure AD B2C branding to $tenantDomain"

  $brandingContent = $branding | ConvertTo-Json -Depth 100
  if ($brandingContent) {
    if (Test-Json $brandingContent) {
      
      $imageHeaders = @{
        "Authorization"   = "Bearer $($plainaccessToken)"
        "Content-Type"    = "image/jpeg"
        "Accept-Language" = "en"
      }
      
      if (Test-Path -Path $logoPath) {
        Write-Host "Updating logo with $logoPath"
        $brandingLogo = Invoke-WebRequest -uri "https://graph.microsoft.com/v1.0/organization/$tenantId/branding/localizations/0/bannerLogo" -Method Put -Infile $logoPath -ContentType 'image/jpg' -Headers $imageHeaders -Verbose:$false
      }
      else { 
        Write-Host "No logo at $logoPath. Skipping..."
      }
      if (Test-Path -Path $backgroundPath) {
        Write-Host "Updating background with $backgroundPath"
        $brandingBackground = Invoke-WebRequest -uri "https://graph.microsoft.com/v1.0/organization/$tenantId/branding/localizations/0/backgroundImage" -Method Put -Infile $backgroundPath -ContentType 'image/jpg' -Headers $imageHeaders -Verbose:$false
      }
      else {
        Write-Host "No background at $backgroundPath. Skipping..."
      }

      $brandingResult = Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/organization/$tenantId/branding" -Headers $headers -Method PATCH -Body $brandingContent -SkipHttpErrorCheck -Verbose:$false
      if ($brandingResult.PSObject.Properties['error'] -or ($brandingLogo.StatusCode -ne "204") -or ($brandingBackground.StatusCode -ne "204")) {
        return '⚠️  Branding was not applied correctly. Please manually set in Azure Active Directory B2C Portal'
      }
      else {
        return $true
      }
    }
    else {
      return  "$brandingFile is not valid JSON. Please correct this before trying again."
    }
  }
}
function Set-AzADB2CUserFlowAttributes(
  [Parameter(Mandatory = $true)]
  [object[]]$userFlowAttributes, 

  [Parameter(Mandatory = $true)]
  [securestring]$accessToken, 

  [Parameter(Mandatory = $true)]
  [string]$tenantDomain,

  [Parameter(Mandatory = $true)]
  [string]$tenantId,

  [Parameter(Mandatory = $true)]
  [string]$userFlow
) {
  $plainaccessToken = ConvertFrom-SecureString -SecureString $accessToken -AsPlainText

  $headers = @{
    "Authorization" = "Bearer $($plainaccessToken)"
    "Content-Type"  = "application/json"
  }
  # User Flow attributes
  Write-Host "Applying Azure AD B2C user flows attributes to $tenantDomain/$userFlow"
  $userFlowsAttributesCurrentlyIds = (Invoke-RestMethod -Uri "https://graph.microsoft.com/beta/identity/b2cUserFlows/$userFlow/userAttributeAssignments?" -Headers $headers -Method GET -SkipHttpErrorCheck -Verbose:$false).value.id      
  $userFlowsAttributesContent = $userFlowAttributes | ConvertTo-Json -Depth 100
  if ($userFlowsAttributesContent) {
    if (Test-Json $userFlowsAttributesContent) {
      $userFlowsAttributesObject = $userFlowsAttributesContent | ConvertFrom-Json -AsHashtable
      $userFlowsAttributesObject | ForEach-Object {

        if ($userFlowsAttributesCurrentlyIds -contains $_.userAttribute.id) {
          Write-Host "📃  Azure AD B2C User Flow attribute $($_.userAttribute.id) already exists in $userFlow"
        }
        else {
          $userFlowAttribute = Invoke-RestMethod -Uri "https://graph.microsoft.com/beta/identity/b2cUserFlows/$userFlow/userAttributeAssignments" -Headers $headers -Method POST -Body ($_ | ConvertTo-Json) -SkipHttpErrorCheck -Verbose:$false
          if ($userFlowAttribute.PSObject.Properties['error']) {
            return $userFlowAttribute.error
          }
        }     
      }
      return $true
    }
    else {
      return "Invalid JSON. Please correct this before trying again."
    }
  }
}

Export-ModuleMember -Function * -Verbose:$true