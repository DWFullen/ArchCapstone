@description('The location used for all deployed resources')
param location string = resourceGroup().location

@description('Tags that will be applied to all resources')
param tags object = {}

@description('Location code for Azure region (e.g., zus1 for East US 1)')
param zLocation string

@description('Short name or code for Azure subscription')
param azureSubscription string

@description('Application name for resource naming')
param applicationName string

@description('Environment name for resource naming (e.g., dev, uat, prod)')
param devEnvironmentName string

@description('Application version for resource naming')
param applicationVersion string

param myBlazorAppExists bool
@secure()
param myBlazorAppDefinition object

@description('Id of the user or app to assign application roles')
param principalId string

var abbrs = loadJsonContent('./abbreviations.json')
var resourceToken = uniqueString(subscription().id, resourceGroup().id, location)

// Monitor application with Azure Monitor
module monitoring 'br/public:avm/ptn/azd/monitoring:0.1.0' = {
  name: 'monitoring'
  params: {
    logAnalyticsName: '${zLocation}-${azureSubscription}-${applicationName}-${devEnvironmentName}-${applicationVersion}-${abbrs.operationalInsightsWorkspaces}'
    applicationInsightsName: '${zLocation}-${azureSubscription}-${applicationName}-${devEnvironmentName}-${applicationVersion}-${abbrs.insightsComponents}'
    applicationInsightsDashboardName: '${zLocation}-${azureSubscription}-${applicationName}-${devEnvironmentName}-${applicationVersion}-${abbrs.portalDashboards}'
    location: location
    tags: tags
  }
}

// Container registry
module containerRegistry 'br/public:avm/res/container-registry/registry:0.1.1' = {
  name: 'registry'
  params: {
    name: '${zLocation}${azureSubscription}${applicationName}${devEnvironmentName}${applicationVersion}${abbrs.containerRegistryRegistries}'
    location: location
    tags: tags
    publicNetworkAccess: 'Enabled'
    roleAssignments: [
      {
        principalId: myBlazorAppIdentity.outputs.principalId
        principalType: 'ServicePrincipal'
        roleDefinitionIdOrName: subscriptionResourceId(
          'Microsoft.Authorization/roleDefinitions',
          '7f951dda-4ed3-4680-a7ca-43fe172d538d'
        )
      }
    ]
  }
}

// Container apps environment
module containerAppsEnvironment 'br/public:avm/res/app/managed-environment:0.4.5' = {
  name: 'container-apps-environment'
  params: {
    logAnalyticsWorkspaceResourceId: monitoring.outputs.logAnalyticsWorkspaceResourceId
    name: '${zLocation}-${azureSubscription}-${applicationName}-${devEnvironmentName}-${applicationVersion}-${abbrs.appManagedEnvironments}'
    location: location
    zoneRedundant: false
  }
}

module myBlazorAppIdentity 'br/public:avm/res/managed-identity/user-assigned-identity:0.2.1' = {
  name: 'myBlazorAppidentity'
  params: {
    name: '${zLocation}-${azureSubscription}-${applicationName}-${devEnvironmentName}-${applicationVersion}-${abbrs.managedIdentityUserAssignedIdentities}'
    location: location
  }
}

module myBlazorAppFetchLatestImage './modules/fetch-container-image.bicep' = {
  name: '${zLocation}-${azureSubscription}-${applicationName}-${devEnvironmentName}-${applicationVersion}-${abbrs.containerAppImages}'
  params: {
    exists: myBlazorAppExists
    name: '${zLocation}-${azureSubscription}-${applicationName}-${devEnvironmentName}-${applicationVersion}-${abbrs.appContainerApps}'
  }
}

var myBlazorAppAppSettingsArray = filter(array(myBlazorAppDefinition.settings), i => i.name != '')
var myBlazorAppSecrets = map(filter(myBlazorAppAppSettingsArray, i => i.?secret != null), i => {
  name: i.name
  value: i.value
  secretRef: i.?secretRef ?? take(replace(replace(toLower(i.name), '_', '-'), '.', '-'), 32)
})
var myBlazorAppEnv = map(filter(myBlazorAppAppSettingsArray, i => i.?secret == null), i => {
  name: i.name
  value: i.value
})

module myBlazorApp 'br/public:avm/res/app/container-app:0.8.0' = {
  name: '${zLocation}-${azureSubscription}-${applicationName}-${devEnvironmentName}-${applicationVersion}-${abbrs.appContainerApps}'
  params: {
    name: '${zLocation}-${azureSubscription}-${applicationName}-${devEnvironmentName}-${applicationVersion}-${abbrs.appContainerApps}'
    ingressTargetPort: 8080
    scaleMinReplicas: 0
    scaleMaxReplicas: 10
    secrets: {
      secureList: union(
        [],
        map(myBlazorAppSecrets, secret => {
          name: secret.secretRef
          value: secret.value
        })
      )
    }
    containers: [
      {
        image: myBlazorAppFetchLatestImage.outputs.?containers[?0].?image ?? 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'
        name: 'main'
        resources: {
          cpu: json('0.5')
          memory: '1.0Gi'
        }
        env: union(
          [
            {
              name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
              value: monitoring.outputs.applicationInsightsConnectionString
            }
            {
              name: 'AZURE_CLIENT_ID'
              value: myBlazorAppIdentity.outputs.clientId
            }
            {
              name: 'PORT'
              value: '8080'
            }
          ],
          myBlazorAppEnv,
          map(myBlazorAppSecrets, secret => {
            name: secret.name
            secretRef: secret.secretRef
          })
        )
      }
    ]
    managedIdentities: {
      systemAssigned: false
      userAssignedResourceIds: [myBlazorAppIdentity.outputs.resourceId]
    }
    registries: [
      {
        server: containerRegistry.outputs.loginServer
        identity: myBlazorAppIdentity.outputs.resourceId
      }
    ]
    environmentResourceId: containerAppsEnvironment.outputs.resourceId
    location: location
    tags: union(tags, { 'azd-service-name': 'my-blazor-app' })
  }
}
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = containerRegistry.outputs.loginServer
output AZURE_RESOURCE_MY_BLAZOR_APP_ID string = myBlazorApp.outputs.resourceId
