# Compute and Billing Structures
Is my app using Workload Profiles(v2) or Consumption-Only(v1)

# Comparing with other Options

## Azure Container Apps
### Distinctive Features
Optimized for General Purpose
Powered by Kubernetes, Dapr, KEDA, and envoy
Supports Kubernetes-style apps and microservices
Scale based on traffic and pulling from event sources like queues, including scale to zero, thus supporting Event-Driven Architectures
Supports on-demand, scheduled, and event Driven Jobs
Provides  certificates, revisions, scale, and environments

Does not allow access to Kubernetes APIs


## Azure Container Instances
### Distinctive Features
Single pod of Hyper-V isolated containers on demand
Scale, load balancing, and certificates aren't provided with ACI containers
Azure Kubernetes Service can layer orchestration and scale on top of ACI through virtual nodes

Use Azure Container Instances f you need a less "opinionated" building block that doesn't align with the scenarios Azure Container Apps is optimizing for.

## Azure Kubernetes Service
### Distinctive Features
Fully Managed Kubernetes
Direct access to the Kubernetes API
Full Cluster resides in your subscription

# Communicate between containers
Application code can call other container apps in the same environment using one of the following methods:

Default fully qualified domain name (FQDN)
A custom domain name
The container app name, for instance http://<APP_NAME> for internal requests
A Dapr URL

When you call another container in the same environment using the FQDN or app name, the network traffic never leaves the environment.

# Storage Mounts in Azure Container Apps
Storage type	Description	Persistence	Usage example
Container-scoped storage	Ephemeral storage available to a running container	Data is available until container shuts down	Writing a local app cache.
Replica-scoped storage	Ephemeral storage for sharing files between containers in the same replica	Data is available until replica shuts down	The main app container writing log files that a sidecar container processes.
Azure Files	Permanent storage	Data is persisted to Azure Files	Writing files to a file share to make data accessible by other systems.