# Azure Infrastructure for Containerized Applications

## 1. Core Components

### **Container Registry**
- Stores Docker images.
- Blazor app image is pushed here and pulled for deployment.

**References:**
  - [Introduction to Azure Container Registry](https://learn.microsoft.com/en-us/azure/container-registry/container-registry-intro)
  - [Quickstart: Create a container registry by using a Bicep file](https://learn.microsoft.com/en-us/azure/container-registry/container-registry-get-started-bicep)

### **Container Apps Environment**
- Secure, isolated environment for running Azure Container Apps.
- Handles networking, scaling, and monitoring.
- Acts as the “host” for containerized workloads.

**References:**
  - [Quickstart: Deploy to Azure Container Apps using Visual Studio Code](https://learn.microsoft.com/en-us/azure/container-apps/deploy-visual-studio-code)
  - [Select the right code-to-cloud path for Azure Container Apps](https://learn.microsoft.com/en-us/azure/container-apps/code-to-cloud-options)

### **Managed Identity**
- Azure identity assigned to your app.
- Enables secure, passwordless access to Azure resources (e.g., pulling images, accessing storage).
- Eliminates secrets in code.

**References:**
  - [Overview for developers: Managed identities for Azure resources](https://learn.microsoft.com/en-us/entra/identity/managed-identities-azure-resources/overview-for-developers)
  - [Use Azure Resources Extension in Visual Studio Code for Managed Identities](https://learn.microsoft.com/en-us/entra/identity/managed-identities-azure-resources/azure-resources-extension-managed-identities)

### **Fetch Container Image Resource**
- Bicep module checks if the container image exists in the registry and fetches the latest version.
- Ensures deployment uses the most up-to-date image.

**References:**
  - [ContainerAppContainer.Image Property (Azure SDK)](https://learn.microsoft.com/en-us/dotnet/api/azure.provisioning.appcontainers.containerappcontainer.image)
  - [Create Bicep files with Visual Studio Code](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/visual-studio-code)

### **Container App**
- Azure resource that runs the containerized Blazor app.
- Handles scaling, networking, and environment variables.
- Connects to Container Apps Environment for orchestration.

**References:**
  - [Quickstart: Deploy to Azure Container Apps using Visual Studio Code](https://learn.microsoft.com/en-us/azure/container-apps/deploy-visual-studio-code)
  - [Select the right code-to-cloud path for Azure Container Apps](https://learn.microsoft.com/en-us/azure/container-apps/code-to-cloud-options)

### **Monitoring Module**
- Deploys Log Analytics workspace, Application Insights, and an Azure Portal dashboard for observability.
- Centralizes monitoring setup and provides telemetry, logging, and performance data for diagnostics.
- Outputs connection strings and resource IDs for use by other resources (e.g., Container Apps, Environment).

**References:**
  - [Azure Monitor Insights overview](https://learn.microsoft.com/en-us/azure/azure-monitor/visualize/insights-overview)
  - [Overview of Log Analytics in Azure Monitor](https://learn.microsoft.com/en-us/azure/azure-monitor/logs/log-analytics-overview)
  - [Application Insights overview](https://learn.microsoft.com/en-us/azure/azure-monitor/app/app-insights-overview)

## 2. Blazor Wasm

- .NET Web Application using Blazor.
- Front-end application compiled to WebAssembly.
- Served as static files from the container.

**References:**
  - [Host and deploy ASP.NET Core standalone Blazor WebAssembly with Azure Static Web Apps](https://learn.microsoft.com/en-us/aspnet/core/blazor/host-and-deploy/webassembly/azure-static-web-apps)
  - [Tooling for ASP.NET Core Blazor](https://learn.microsoft.com/en-us/aspnet/core/blazor/tooling)

## 3. Docker

- Used to build, test, and run the Blazor app locally as a container.
- Ensures consistent local and Azure environments.
- Build the image, run locally, and push to Azure Container Registry for deployment.

**References:**
  - [Overview of Docker remote development on Windows](https://learn.microsoft.com/en-us/windows/dev-environment/docker/overview)
  - [Leveraging containers and orchestrators](https://learn.microsoft.com/en-us/dotnet/architecture/cloud-native/leverage-containers-orchestrators)

---

# Azure Well-Architected Framework Review

## 1. Reliability

**Strengths**
- Azure-managed services (Container Apps, Storage, ACR) with high availability.
- Log Analytics and Application Insights for monitoring and alerting.
- Infrastructure as Code (Bicep) enables repeatable deployments and disaster recovery.

**Areas to Improve**
- Consider geo-redundant storage for critical data.
- Implement health probes and auto-restart for containers.
- Document recovery procedures and backup strategies.

---

## 2. Security

**Strengths**
- Managed identities for secure resource access (no secrets in code).
- Role assignments restrict access.
- Application Insights and Log Analytics for threat detection.

**Areas to Improve**
- Enable diagnostic logging for all resources.
- Use Key Vault for secrets and connection strings.
- Regularly review and update role assignments and access policies.
- Consider network security (VNET integration, private endpoints).

---

## 3. Cost Optimization

**Strengths**
- Consumption-based services (Container Apps, Storage) that scale with usage.
- Manual and automated deployment options for efficient resource management.

**Areas to Improve**
- Set up budgets and cost alerts in Azure Cost Management.
- Review resource SKU choices (e.g., Storage redundancy, Container App scaling limits).
- Clean up unused resources and containers regularly.

---

## 4. Operational Excellence

**Strengths**
- CI/CD pipeline setup (GitHub Actions) for safe, repeatable deployments.
- Monitoring and logging via Application Insights and Log Analytics.
- Infrastructure as Code enables version control and change tracking.

**Areas to Improve**
- Automate rollbacks and blue/green deployments for safer releases.
- Expand monitoring to include custom metrics and alerts.
- Document operational runbooks and escalation paths.

---

## 5. Performance Efficiency

**Strengths**
- Container Apps can scale horizontally based on load.
- Docker-based deployment allows for fast startup and efficient resource use.

**Areas to Improve**
- Implement load testing and performance monitoring.
- Review scaling rules and resource limits for Container Apps.
- Optimize application code and container images for faster response times.

---

## Summary Table

| Pillar                 | Strengths                                   | Areas to Improve                          |
|------------------------|---------------------------------------------|-------------------------------------------|
| Reliability            | Managed services, monitoring, IaC           | Geo-redundancy, health probes, recovery docs |
| Security               | Managed identity, RBAC, monitoring          | Key Vault, diagnostics, network security  |
| Cost Optimization      | Consumption-based, efficient deployment     | Budgets, SKU review, resource cleanup     |
| Operational Excellence | CI/CD, monitoring, IaC                      | Rollbacks, custom alerts, runbooks        |
| Performance Efficiency | Horizontal scaling, Docker efficiency       | Load testing, scaling rules, code optimization |

---

## Component Purpose/Role

| Component                  | Purpose/Role                                                                 |
|----------------------------|------------------------------------------------------------------------------|
| Monitoring Module          | Sets up Log Analytics, Application Insights, and dashboard for observability  |
| Container Registry         | Stores container images for deployment                                       |
| Container Apps Environment | Hosts and manages container apps, networking, scaling, monitoring           |
| Managed Identity           | Secure access to Azure resources, no secrets needed                         |
| Fetch Container Image      | Gets the latest image from registry for deployment                           |
| Container App              | Runs your Blazor app as a container in Azure                                |
| Blazor Wasm                | .NET web app, compiled to WebAssembly, served from the container             |
| Docker                     | Builds, tests, and runs containers locally and prepares images for Azure     |

---

## Next Steps

- Review each area for improvement and prioritize based on business needs.
- Use Azure Advisor and Cost Management for ongoing recommendations.
- Regularly revisit the Well-Architected Framework as your solution evolves.

---

