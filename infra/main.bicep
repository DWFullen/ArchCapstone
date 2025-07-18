targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the environment that can be used as part of naming resource convention')
param environmentName string
param azdEnvName string

@minLength(1)
@description('Primary location for all resources')
param location string

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

// Tags that should be applied to all resources.
// 
// Note that 'azd-service-name' tags should be applied separately to service host resources.
// Example usage:
//   tags: union(tags, { 'azd-service-name': <service name in azure.yaml> })
//
// Reminder: Review deploymentInstructions.md for automation and naming guidance to avoid breaking azd automation.
var tags = {
  'azd-env-name': azdEnvName
}

// Organize resources in a resource group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${zLocation}-${azureSubscription}-${applicationName}-${environmentName}-${applicationVersion}-rg'
  location: location
  tags: tags
}

module resources 'resources.bicep' = {
  scope: rg
  name: 'resources'
  params: {
    location: location
    tags: tags
    principalId: principalId
    myBlazorAppExists: myBlazorAppExists
    myBlazorAppDefinition: myBlazorAppDefinition
    applicationName: applicationName
    applicationVersion: applicationVersion
    azureSubscription: azureSubscription
    devEnvironmentName: devEnvironmentName
    zLocation: zLocation
  }
}

output AZURE_CONTAINER_REGISTRY_ENDPOINT string = resources.outputs.AZURE_CONTAINER_REGISTRY_ENDPOINT
output AZURE_RESOURCE_MY_BLAZOR_APP_ID string = resources.outputs.AZURE_RESOURCE_MY_BLAZOR_APP_ID
