# Deployment Instructions

To deploy this project, follow these steps:

---

## 1. Verify Azure Login and Subscription

Check your current subscription:
```Powershell Terminal
az account show -o table
az account set -s <subscription id>
```

If you are not logged in:
```Powershell Terminal
az login
```

## Automation with Azure Developer CLI

If you want to automate these steps, use:

```Powershell Terminal
azd up
```

This abstracts the following actions:
- Provision Infrastructure: `azd provision`
- Deploy Application: `azd deploy`

Lastly, configure your CI/CD pipeline:
```Powershell Terminal
azd pipeline deploy
```

**Important Notes on azd Automation and Resource Naming:**
- The `azd-env-name` tag is critical for Azure Developer CLI (azd) automation. It allows azd to track, update, and clean up resources for your environment.
- Always include the `azd-env-name` tag on all resources managed by azd. If you change the environment name or naming scheme, update this tag everywhere (Bicep/ARM templates, azure.yaml, .env).
- For service host resources (like Container Apps), also include the `azd-service-name` tag. This helps azd manage service-specific resources.
- If you change naming conventions or environment variables, update your templates, .env file, azure.yaml, and any pipeline scripts to match. Inconsistent naming can break automation and resource management.
- Existing resources will not be renamed automatically; only new deployments will use the updated names.
- Validate all resource references, IDs, and endpoints in your pipeline and application code after making changes.

**The following is a manual workflow and replaces the automation provided by `azd provision` and `azd deploy` which were abstracted by using azd up.**
You must manually handle resource creation, app packaging, image pushing, and deployment steps if not using the azd commands.

---

## 1. Provision Infrastructure

> **Note:** If `azure.yaml` already exists in your project, you may skip `azd init`.

Initialize the Azure Developer CLI in your project:
```Powershell Terminal
azd init
```

Create a resource group:
```Powershell Terminal
az group create --name <resource-group-name> --location <location>
```

Deploy infrastructure (Bicep/ARM):
```Powershell Terminal
az deployment group create --resource-group <resource-group-name> --template-file infra/resources.bicep --parameters @infra/main.parameters.json
```
*If using Terraform, run:*
```Powershell Terminal
terraform init
terraform plan
terraform apply
```
*in your infra directory.*

---

## 2. Build and Package Application

Build the application:
```Powershell Terminal
dotnet build MyBlazorApp/MyBlazorApp.csproj -c Release
```

Publish the application:
```Powershell Terminal
dotnet publish MyBlazorApp/MyBlazorApp.csproj -c Release -o ./publish
```

Build Docker image:
```Powershell Terminal
docker build -t <acr-login-server>/myblazorapp:latest .
```

Login to Azure Container Registry:
```Powershell Terminal
az acr login --name <acr-name>
```

Push Docker image to ACR:
```Powershell Terminal
docker push <acr-login-server>/myblazorapp:latest
```

---

## 3. Deploy Application to Azure Container Apps

```Powershell Terminal
az containerapp update `
  --name <container-app-name> `
  --resource-group <resource-group-name> `
  --image <acr-login-server>/myblazorapp:latest `
  --environment-variables APPLICATIONINSIGHTS_CONNECTION_STRING=<value> AZURE_CLIENT_ID=<value> PORT=80
```
*Add other environment variables and secrets as needed.*

---

## 4. Configure Managed Identity and Role Assignments

```Powershell Terminal
az identity create --name <identity-name> --resource-group <resource-group-name>
az role assignment create --assignee <identity-principal-id> --role <role-name> --scope <resource-id>
```

---

## 5. Configure Monitoring and Storage

- Link Application Insights and Log Analytics using Azure Portal or CLI.
- Set up Storage Account containers and tables as needed.

---

## 6. Verify Deployment

- Access your app via the provided endpoint.
- Check logs in Application Insights and Log Analytics.
- Confirm resources in Azure Portal.

---

## 7. Set Up CI/CD Pipeline (Optional)

- Place workflow YAML files in `.github/workflows/`.
- Configure secrets and variables in GitHub repository settings.

---


---

