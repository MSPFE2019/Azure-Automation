# Azure Automation Power Platform Custom Connector

This repository now provides a starter **Microsoft Power Platform custom connector** for **Azure Automation** using the Azure Resource Manager (ARM) REST API.

- OpenAPI file: `/home/runner/work/Azure-Automation/Azure-Automation/connector/openapi.json`
- Format: OpenAPI 2.0 (Swagger)
- Auth model: Microsoft Entra ID (Azure AD) OAuth 2.0 against ARM

## What this connector includes

Initial operations included in the starter connector:

1. List automation accounts in a resource group
2. Get an automation account
3. List runbooks
4. Get a runbook
5. Start a runbook (implemented as **Create Job** in Azure Automation REST API)
6. List jobs
7. Get a job
8. Stop a job

The OpenAPI uses API version `2024-10-23` and ARM endpoint `https://management.azure.com`.

## Prerequisites

1. An Azure subscription with an Automation Account.
2. Microsoft Entra app registration for OAuth 2.0.
3. RBAC rights for the signed-in user/service principal, at least on the Automation Account scope:
   - `Automation Reader` for read-only operations.
   - `Automation Operator` (or equivalent custom role permissions) to start/stop jobs.
4. Power Apps or Power Automate environment with permission to create custom connectors.

## OAuth configuration guidance

The connector declares OAuth 2.0 endpoints as tenant-aware URLs:

- Authorization: `https://login.microsoftonline.com/{tenantId}/oauth2/authorize`
- Token: `https://login.microsoftonline.com/{tenantId}/oauth2/token`
- Scope: `https://management.azure.com/user_impersonation`

Connection parameters include:

- `tenantId`
- `subscriptionId`
- `resourceGroupName`
- `automationAccountName`

> No client IDs, client secrets, tenant secrets, or personal identifiers are committed in this repository.

### App registration notes

For your Entra app registration, configure:

- Redirect URI for Power Platform custom connectors (as prompted by Power Apps/Power Automate during setup)
- Delegated permission to Azure Service Management API (`user_impersonation`)
- Admin consent where required by your tenant policies

## Import into Power Platform

1. Open **Power Apps** or **Power Automate**.
2. Go to **Custom connectors** > **New custom connector** > **Import an OpenAPI file**.
3. Upload `/home/runner/work/Azure-Automation/Azure-Automation/connector/openapi.json`.
4. In the connector security configuration, provide your app registration client ID and client secret in the platform UI (do not store them in source control).
5. Create a connection and enter the required connection parameters.
6. Test each operation from the connector test tab.

## Testing operations

Use the connector test experience to validate:

- `ListAutomationAccounts`
- `GetAutomationAccount`
- `ListRunbooks`
- `GetRunbook`
- `StartRunbook` (PUT job with body `properties.runbook.name` and optional `properties.parameters`)
- `ListJobs`
- `GetJob`
- `StopJob`

## Validation / linting

A lightweight validation script is included:

- `/home/runner/work/Azure-Automation/Azure-Automation/tests/validate_openapi.py`

Run from repository root:

```bash
python /home/runner/work/Azure-Automation/Azure-Automation/tests/validate_openapi.py
```

This checks JSON syntax and basic internal consistency (required OpenAPI sections, referenced parameters/definitions, and required operations).

## Limitations and assumptions

- This is a starter connector focused on core runbook/job scenarios.
- The connector uses ARM `2024-10-23` APIs and may need updates if Microsoft changes operation contracts.
- `StartRunbook` is represented as job creation because the stable ARM surface starts execution by creating a job.
- Some organizations may require adjusting OAuth URL behavior (for example, replacing `{tenantId}` with `common` in environments that do not allow templated tenant URLs in custom connector auth settings).
