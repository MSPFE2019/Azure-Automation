function Connect-AzAutomationGccTenant {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TenantId,

        [string]$SubscriptionId,

        [switch]$UseManagedIdentity,

        [string]$AutomationConnectionName = 'AzureRunAsConnection',

        [ValidateSet('AzureUSGovernment')]
        [string]$Environment = 'AzureUSGovernment'
    )

    if ($UseManagedIdentity) {
        Connect-AzAccount -Identity -Environment $Environment -Tenant $TenantId | Out-Null
        if ($SubscriptionId) {
            Set-AzContext -SubscriptionId $SubscriptionId -Tenant $TenantId | Out-Null
        }
        return
    }

    $connection = Get-AutomationConnection -Name $AutomationConnectionName
    if (-not $connection) {
        throw "Automation connection '$AutomationConnectionName' was not found."
    }

    if (-not $connection.ApplicationId -or -not $connection.CertificateThumbprint -or -not $connection.TenantId) {
        throw "Automation connection '$AutomationConnectionName' is missing one or more required properties: ApplicationId, CertificateThumbprint, TenantId."
    }

    Connect-AzAccount `
        -ServicePrincipal `
        -Environment $Environment `
        -TenantId $connection.TenantId `
        -ApplicationId $connection.ApplicationId `
        -CertificateThumbprint $connection.CertificateThumbprint | Out-Null

    $targetSubscriptionId = if ($SubscriptionId) { $SubscriptionId } else { $connection.SubscriptionId }
    if ($targetSubscriptionId) {
        Set-AzContext -SubscriptionId $targetSubscriptionId -Tenant $connection.TenantId | Out-Null
    }
}
