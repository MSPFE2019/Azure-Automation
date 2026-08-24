# Azure-Automation

## GCC tenant connector

Use `/home/runner/work/Azure-Automation/Azure-Automation/runbooks/Connect-AzAutomationGccTenant.ps1` to connect Azure Automation runbooks to a GCC tenant (`AzureUSGovernment`).

### Managed identity

```powershell
Connect-AzAutomationGccTenant -TenantId '<tenant-id>' -SubscriptionId '<subscription-id>' -UseManagedIdentity
```

### Run As connection asset

```powershell
Connect-AzAutomationGccTenant -TenantId '<tenant-id>'
```

The Run As flow expects an Automation connection asset named `AzureRunAsConnection` by default with `ApplicationId`, `CertificateThumbprint`, `TenantId`, and optional `SubscriptionId`.
