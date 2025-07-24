# Next Steps after `azd init`

## Table of Contents

1. [Next Steps](#next-steps)
2. [What was added](#what-was-added)
3. [Billing](#billing)
4. [Troubleshooting](#troubleshooting)
5. [Improvements and Recommendations](#improvements-and-recommendations)

## Next Steps

### Provision infrastructure and deploy application code

Run `azd up` to provision your infrastructure and deploy to Azure (or run `azd provision` then `azd deploy` to accomplish the tasks separately). Visit the service endpoints listed to see your application up-and-running!

To troubleshoot any issues, see [troubleshooting](#troubleshooting).

### Configure environment variables for running services

Configure environment variables for running services by updating `settings` in [main.parameters.json](./infra/main.parameters.json).

### Configure CI/CD pipeline

Run `azd pipeline config` to configure the deployment pipeline to connect securely to Azure. 

- Deploying with `GitHub Actions`: Select `GitHub` when prompted for a provider. If your project lacks the `azure-dev.yml` file, accept the prompt to add it and proceed with pipeline configuration.

- Deploying with `Azure DevOps Pipeline`: Select `Azure DevOps` when prompted for a provider. If your project lacks the `azure-dev.yml` file, accept the prompt to add it and proceed with pipeline configuration.

## What was added

### Infrastructure configuration

To describe the infrastructure and application, `azure.yaml` along with Infrastructure as Code files using Bicep were added with the following directory structure:

```yaml
- azure.yaml        # azd project configuration
- infra/            # Infrastructure-as-code Bicep files
  - main.bicep      # Subscription level resources
  - resources.bicep # Primary resource group resources
  - modules/        # Library modules
```

The resources declared in [resources.bicep](./infra/resources.bicep) are provisioned when running `azd up` or `azd provision`.
This includes:


- Azure Container App to host the 'my-blazor-app' service.

More information about [Bicep](https://aka.ms/bicep) language.

### Build from source (no Dockerfile)

#### Build with Buildpacks using Oryx

If your project does not contain a Dockerfile, we will use [Buildpacks](https://buildpacks.io/) using [Oryx](https://github.com/microsoft/Oryx/blob/main/doc/README.md) to create an image for the services in `azure.yaml` and get your containerized app onto Azure.

To produce and run the docker image locally:

1. Run `azd package` to build the image.
2. Copy the *Image Tag* shown.
3. Run `docker run -it <Image Tag>` to run the image locally.

#### Exposed port

Oryx will automatically set `PORT` to a default value of `80` (port `8080` for Java). Additionally, it will auto-configure supported web servers such as `gunicorn` and `ASP .NET Core` to listen to the target `PORT`. If your application already listens to the port specified by the `PORT` variable, the application will work out-of-the-box. Otherwise, you may need to perform one of the steps below:

1. Update your application code or configuration to listen to the port specified by the `PORT` variable
1. (Alternatively) Search for `targetPort` in a .bicep file under the `infra/app` folder, and update the variable to match the port used by the application.

## Billing

Visit the *Cost Management + Billing* page in Azure Portal to track current spend. For more information about how you're billed, and how you can monitor the costs incurred in your Azure subscriptions, visit [billing overview](https://learn.microsoft.com/azure/developer/intro/azure-developer-billing).

## Troubleshooting

Q: I visited the service endpoint listed, and I'm seeing a blank page, a generic welcome page, or an error page.

A: Your service may have failed to start, or it may be missing some configuration settings. To investigate further:

1. Run `azd show`. Click on the link under "View in Azure Portal" to open the resource group in Azure Portal.
2. Navigate to the specific Container App service that is failing to deploy.
3. Click on the failing revision under "Revisions with Issues".
4. Review "Status details" for more information about the type of failure.
5. Observe the log outputs from Console log stream and System log stream to identify any errors.
6. If logs are written to disk, use *Console* in the navigation to connect to a shell within the running container.

For more troubleshooting information, visit [Container Apps troubleshooting](https://learn.microsoft.com/azure/container-apps/troubleshooting). 

## Improvements and Recommendations - added 7/24/25

### Culture
- Foster better collaboration between development and operations teams by documenting shared responsibilities.
- Implement blameless post-mortems for incidents to encourage transparency and learning.
- Create runbooks that are accessible and executable by all team members.

### Automation
- Enhance CI/CD pipelines to automate testing, deployment, and security scans.
- Adopt Infrastructure as Code (IaC) tools like Terraform or Bicep for consistent infrastructure provisioning.
- Automate repetitive operational tasks, such as log analysis and scaling configurations.

### Lean Practices
- Break down large features into smaller, manageable chunks for faster delivery.
- Focus on delivering value iteratively by adopting a minimal viable product (MVP) approach.
- Identify and remove bottlenecks in the development and delivery pipeline.

### Measurement
- Set up dashboards to monitor key metrics like deployment frequency, lead time for changes, and mean time to recovery.
- Implement robust logging and monitoring solutions to track application and infrastructure performance.
- Use metrics to validate changes and identify areas for optimization.

### Sharing
- Document processes, architectural decisions, and runbooks in a shared repository.
- Promote knowledge sharing through internal meetups and workshops.
- Encourage cross-functional teams to work closely together to foster mutual understanding.

### Security
- Review and tighten permissions for federated credentials and secrets used in pipelines.
- Integrate security scans (SAST, DAST, SCA) into the CI/CD pipeline.
- Implement role-based access control (RBAC) for Azure resources.

### Future Enhancements
- Explore adding a User Acceptance Testing (UAT) stage to the pipeline for pre-production validation.
- Periodically review and clean up unused resources in dev and prod environments to optimize costs.
- Automate testing for infrastructure provisioning and application deployment.

---
These recommendations align with the DevOps core principles and aim to improve the reliability, scalability, and efficiency of the software delivery pipeline.

### Additional information

For additional information about setting up your `azd` project, visit our official [docs](https://learn.microsoft.com/azure/developer/azure-developer-cli/make-azd-compatible?pivots=azd-convert).
