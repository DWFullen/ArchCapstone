Resource References for Project:
https://k8slens.dev/
https://hub.docker.com/
https://app.docker.com/
https://docs.docker.com/get-started/workshop/



Key Azure Services:
Azure Virtual Network
Azure Kubernetes Service
Azure Container Registry
Azure Load Balancer
Azure Storage Account
Azure Container Instances

Core Components & Actions:

Blazor Application Development:

Create and develop a Blazor WebAssembly or Server application.
Local testing.

We will be using WebAssembly because the application will be made up of static
files which makes them highly portable and lightweight which is what we want
since we are using Nginx to serve those files.

Dockerization:

Create a Dockerfile to containerize the Blazor application.
Build and locally test the Docker image.
Azure Container Registry (ACR):

Create an ACR instance.
Push the Docker image to ACR.
Azure Kubernetes Service (AKS):

Create an AKS cluster.
Connect to the AKS cluster.
Kubernetes Deployment:

Create a Kubernetes deployment to run the Dockerized Blazor application.
Apply the deployment to the AKS cluster.
Kubernetes Service (Load Balancer):

Create a Kubernetes service of type LoadBalancer to expose the application.
Apply the service to the AKS cluster.
Application Access:

Retrieve the external IP of the LoadBalancer service.
Access the Blazor application via the browser.
Monitoring and Scaling (Optional but Recommended):

Implement Azure Monitor for Containers.
Implement manual scaling of the deployment.
Implement Horizontal Pod Autoscaling (HPA).