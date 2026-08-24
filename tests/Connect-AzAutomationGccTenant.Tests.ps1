$ErrorActionPreference = 'Stop'

. "$PSScriptRoot/../runbooks/Connect-AzAutomationGccTenant.ps1"

function Assert-True {
    param(
        [Parameter(Mandatory = $true)]
        [bool]$Condition,
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

$global:ConnectCalls = @()
$global:ContextCalls = @()

function Connect-AzAccount {
    param(
        [switch]$Identity,
        [switch]$ServicePrincipal,
        [string]$Environment,
        [string]$Tenant,
        [string]$TenantId,
        [string]$ApplicationId,
        [string]$CertificateThumbprint
    )

    $global:ConnectCalls += [pscustomobject]@{
        Identity = $Identity.IsPresent
        ServicePrincipal = $ServicePrincipal.IsPresent
        Environment = $Environment
        Tenant = $Tenant
        TenantId = $TenantId
        ApplicationId = $ApplicationId
        CertificateThumbprint = $CertificateThumbprint
    }
}

function Set-AzContext {
    param(
        [string]$SubscriptionId,
        [string]$Tenant
    )

    $global:ContextCalls += [pscustomobject]@{
        SubscriptionId = $SubscriptionId
        Tenant = $Tenant
    }
}

function Get-AutomationConnection {
    param([string]$Name)

    return [pscustomobject]@{
        Name = $Name
        ApplicationId = 'app-id'
        CertificateThumbprint = 'thumbprint'
        TenantId = 'tenant-from-asset'
        SubscriptionId = 'subscription-from-asset'
    }
}

Connect-AzAutomationGccTenant -TenantId 'managed-tenant' -SubscriptionId 'managed-sub' -UseManagedIdentity

Assert-True ($global:ConnectCalls.Count -eq 1) 'Expected one Connect-AzAccount call for managed identity flow.'
Assert-True ($global:ConnectCalls[0].Identity) 'Expected managed identity authentication.'
Assert-True ($global:ConnectCalls[0].Environment -eq 'AzureUSGovernment') 'Expected AzureUSGovernment environment for managed identity flow.'
Assert-True ($global:ConnectCalls[0].Tenant -eq 'managed-tenant') 'Expected Tenant to be passed in managed identity flow.'
Assert-True ($global:ContextCalls.Count -eq 1) 'Expected one Set-AzContext call for managed identity flow.'
Assert-True ($global:ContextCalls[0].SubscriptionId -eq 'managed-sub') 'Expected managed identity subscription to be set.'

$global:ConnectCalls = @()
$global:ContextCalls = @()

Connect-AzAutomationGccTenant -TenantId 'ignored-tenant'

Assert-True ($global:ConnectCalls.Count -eq 1) 'Expected one Connect-AzAccount call for run as flow.'
Assert-True ($global:ConnectCalls[0].ServicePrincipal) 'Expected service principal authentication in run as flow.'
Assert-True ($global:ConnectCalls[0].Environment -eq 'AzureUSGovernment') 'Expected AzureUSGovernment environment for run as flow.'
Assert-True ($global:ConnectCalls[0].TenantId -eq 'tenant-from-asset') 'Expected TenantId from automation connection asset.'
Assert-True ($global:ConnectCalls[0].ApplicationId -eq 'app-id') 'Expected ApplicationId from automation connection asset.'
Assert-True ($global:ConnectCalls[0].CertificateThumbprint -eq 'thumbprint') 'Expected CertificateThumbprint from automation connection asset.'
Assert-True ($global:ContextCalls.Count -eq 1) 'Expected one Set-AzContext call for run as flow.'
Assert-True ($global:ContextCalls[0].SubscriptionId -eq 'subscription-from-asset') 'Expected subscription from automation connection asset.'

Write-Host 'All connector tests passed.'
