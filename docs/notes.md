# Compute and Billing Structures
Is my app using Workload Profiles(v2) or Consumption-Only(v1)

## Summary of Container Services

### Azure Container Apps
- **Best for:** General-purpose workloads, microservices, event-driven architectures, and apps needing Kubernetes-like scaling without cluster management.
- **Use when:** You want managed scaling, built-in Dapr/KEDA/event-driven features, and don't need direct Kubernetes API access. Great for web APIs, background jobs, and microservices.

### Azure Container Instances (ACI)
- **Best for:** Simple, single-container workloads, quick jobs, or when you need ephemeral compute without orchestration.
- **Use when:** You need to run a container quickly, without infrastructure management, scaling, or load balancing. Good for batch jobs, testing, or lightweight tasks.

### Azure Kubernetes Service (AKS)
- **Best for:** Full control over Kubernetes clusters, advanced orchestration, and direct API access.
- **Use when:** You need custom Kubernetes features, complex orchestration, or integration with other Azure services at the cluster level. Ideal for large-scale, multi-container, enterprise-grade solutions.

## When to Use Each Type

| Service                  | Use Case Example                                                                 | When to Choose                                                                                   |
|--------------------------|----------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------|
| Container Apps           | Microservices, APIs, event-driven jobs, background processing                    | Managed scaling, built-in features, no cluster management, no need for direct K8s API            |
| Container Instances      | Batch jobs, quick tests, simple workloads, ephemeral compute                     | Fast startup, no orchestration, no scaling, minimal management                                   |
| Kubernetes Service (AKS) | Enterprise apps, custom orchestration, advanced networking, direct K8s API usage | Full control, custom integrations, complex deployments, need for Kubernetes ecosystem features    |

## Storage Mounts in Container Apps

- **Container-scoped storage:** Use for temporary data needed only during container lifetime (e.g., cache).
- **Replica-scoped storage:** Use for sharing ephemeral data between containers in the same replica (e.g., logs for sidecar processing).
- **Azure Files:** Use for persistent, shared storage accessible by multiple containers and external systems.

## Questions Answered

- **How do containers communicate?** In Container Apps, containers in the same environment can communicate via FQDN, app name, or Dapr URLs. Traffic stays internal.
- **What about scaling?** Container Apps and AKS support scaling; ACI does not.
- **Do I need Kubernetes knowledge for Container Apps?** No, it's abstracted away.

## Expansion

- **Container Apps** are ideal for most modern cloud-native apps unless you need deep Kubernetes customization.
- **ACI** is best for simple, short-lived tasks or when you want minimal setup.
- **AKS** is for advanced users needing full Kubernetes power.

## Real-World Scenarios

### Azure Container Apps
- **E-commerce API:** Host a scalable REST API for an online store, handling spikes in traffic during sales events.
- **Background Processing:** Run scheduled jobs for order processing, inventory updates, or sending notifications.
- **Event-driven Microservices:** Process messages from Azure Service Bus or Event Grid, such as updating user profiles after a purchase.
- **Real-time Analytics:** Aggregate and analyze telemetry data from IoT devices, scaling out as needed.

### Azure Container Instances (ACI)
- **Data Transformation:** Run a container to convert uploaded files (e.g., CSV to JSON) and store results in Azure Blob Storage.
- **Batch Image Processing:** Quickly process batches of images for resizing or watermarking, then shut down.
- **Test Automation:** Spin up containers to run integration tests on new code commits, then dispose of them.
- **Scheduled Tasks:** Perform nightly database backups or report generation without maintaining infrastructure.

### Azure Kubernetes Service (AKS)
- **Enterprise SaaS Platform:** Deploy a multi-tenant SaaS application with complex networking, custom ingress, and persistent storage.
- **Machine Learning Pipelines:** Orchestrate distributed training jobs and model deployments using Kubernetes operators.
- **Hybrid Cloud Integration:** Connect on-premises systems with cloud workloads, using custom networking and security policies.
- **Financial Services:** Run high-availability trading platforms with strict compliance, monitoring, and disaster recovery requirements.

Summary added to commit history.