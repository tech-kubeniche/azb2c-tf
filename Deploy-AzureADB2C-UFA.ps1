Param (
    [Parameter(Mandatory = $True)]
    [string]$AADB2C_PROVISION_CLIENT_ID,

    [Parameter(Mandatory = $True)]
    [string]$AADB2C_PROVISION_CLIENT_SECRET,

    [Parameter(Mandatory = $True)]
    [string]$AADB2C_DOMAINNAME
) 

# Set-StrictMode -Version "Latest"
# $ErrorActionPreference = "Stop"

$RootPath = Resolve-Path -Path (Join-Path $PSScriptRoot "..")
Write-Host "RootPath: $RootPath"

Import-Module (Join-Path $RootPath "\azb2c-tf\ps1_modules\functions.psm1") -Force -Verbose:$true

$context = Get-Content -Path "config.json" | ConvertFrom-Json -AsHashtable

Write-Verbose "Executing Azure AD B2C script with the following context:"
Write-Verbose ($context | Format-Table | Out-String)
Write-Host $context

try {
    $parameters = @{
        tags                  = @{ purpose = 'Azure AD B2C App' }
        azureADB2Cname        = $domainName
        azureADB2CDisplayName = $context.AzureADB2C.name
        skuName               = $context.AzureADB2C.skuName
        skuTier               = $context.AzureADB2C.skuTier
        countryCode           = $context.AzureADB2C.countryCode
        location_b2c          = $context.AzureADB2C.location
    }

    ###################################
    # Deploy Azure AD B2C User Flows, User Attributes, and branding
    ###################################
    if (-not [string]::IsNullOrEmpty($AADB2C_PROVISION_CLIENT_ID) -and -not [string]::IsNullOrEmpty($AADB2C_PROVISION_CLIENT_SECRET)) { 
        $domainName = $AADB2C_DOMAINNAME
        $clientId = $AADB2C_PROVISION_CLIENT_ID
        $clientSecret = $AADB2C_PROVISION_CLIENT_SECRET
        $scope = "https://graph.microsoft.com/.default"
        
        $body = @{
            grant_type    = "client_credentials"
            client_id     = $clientId
            client_secret = $clientSecret
            scope         = $scope
        }
        Write-Host $AADB2C_PROVISION_CLIENT_ID
        Write-Host $AADB2C_PROVISION_CLIENT_SECRET
        Write-Host "📃 Obtaining token to manage Azure AD B2C tenancy $domainName"
        $response = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$domainName/oauth2/v2.0/token" -Method POST -Body $body -SkipHttpErrorCheck -Verbose:$false
        Write-Host $response
        if ([string]::IsNullOrWhiteSpace($response)) {
            Write-Warning "⚠️  Please ensure you have followed post-deployment instructions to configure the appropriate app registration to manage this tenancy and confirm the secret has not expired. `r`n"
            throw $response.error_description
        }
        else {
            $accessToken = $response.access_token
            $secureAccessToken = ConvertTo-SecureString -String $accessToken -AsPlainText -Force
            $headers = @{
                "Authorization" = "Bearer $accessToken"
                "Content-Type"  = "application/json"
            }
        
            $tenantId = (Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/organization" -Headers $headers -Method GET -SkipHttpErrorCheck -Verbose:$false).Value.id

            if ($context.AzureADB2C.Contains('branding')) {
                $result = Set-AzADB2CBranding -accessToken $secureAccessToken -branding ($context.AzureADB2C.branding | ConvertTo-Json -Depth 100 | ConvertFrom-Json -AsHashtable) -tenantId $tenantId -tenantDomain $domainName -logoPath $logo -backgroundPath $background
                if ($result -eq $true) {
                    Write-Host "✅  Applied Azure AD B2C branding to $($domainName)`r`n"
                }
                else {
                    # Soft warning on branding because it's not mission critical
                    Write-Warning $result 
                }
            }
            
            # User Flows
            if ($context.AzureADB2C.Contains('userFlows')) {
                $result = Set-AzADB2CUserFlows -accessToken $secureAccessToken -userFlows ($context.AzureADB2C.userFlows | ConvertTo-Json -Depth 100 | ConvertFrom-Json -AsHashtable) -tenantId $tenantId -tenantDomain $domainName
                if ($result -eq $true) {
                    Write-Host "✅  Created/updated Azure AD B2C User Flow $($domainName)`r`n"
                }
                else {
                    throw $result
                }
            }

            # User Flow attributes
            if ($context.AzureADB2C.Contains('userFlowAttributes') -and $context.AzureADB2C.Contains('userFlows')) {
                foreach ($userFlow in $context.AzureADB2C.userFlows) {
                    $result = Set-AzADB2CUserFlowAttributes -accessToken $secureAccessToken -userFlow $userFlow.id -userFlowAttributes ($context.AzureADB2C.userFlowAttributes | ConvertTo-Json -Depth 100 | ConvertFrom-Json) -tenantId $tenantId -tenantDomain $domainName
                    if ($result -eq $true) {
                        Write-Host "✅  Created/updated Azure AD B2C User Flow Attributes $($domainName)/$($userFlow.id)`r`n"
                    }
                    else {
                        throw $result
                    }
                }
            }
            # Note on Application attributes
            Write-Warning "`r`n⚠️  Application claims for User Flows cannot be updated via API at this time. Please log into the Azure Active Directory Portal and modify these attributes manually.`r`n"
            
            # Azure App Registrations
            if ($context.AzureADB2C.Contains('appRegistrations')) {
                $result, $clientIds = Set-AzADB2CAppRegistrations -accessToken $secureAccessToken -appRegistrations ($context.AzureADB2C.appRegistrations | ConvertTo-Json -Depth 100 | ConvertFrom-Json -AsHashtable) -tenantId $tenantId -tenantDomain $domainName
                if ($result -eq $true) {
                    Write-Host "✅  Successfully created Azure AD B2C app registrations $($context.AzureADB2C.appRegistrations.displayName)"
                }
                else {
                    throw $clientIds
                }
            }

            
        }
    }
    else {
        $warningMessage = "⚠️ ClientId and ClientSecret for Azure AD B2C tenancy " +
        "$domainName not provided. Please ensure to follow the " +
        "post-deployment step to create the app registration " +
        "in order to correctly configure AAD B2C for this solution."

        Write-Warning $warningMessage
    }
}
catch {
    throw $_
}
