@description('Name of the Azure Communication Services resource')
param azureCommunicationServicesName string

@description('Location for the ACS resource')
param location string = resourceGroup().location

@description('Data location for ACS (e.g., United States)')
param dataLocation string = 'United States'

resource azureCommunicationServices 'Microsoft.Communication/communicationServices@2025-05-01' = {
  name: azureCommunicationServicesName
  location: resourceGroup().location
  tags: {
    environment: 'dev'
    application: 'yourAppName'
  }
  identity: {
    type: 'SystemAssigned' // or 'UserAssigned' if you want to use a managed identity
    // userAssignedIdentities: { '/subscriptions/<subId>/resourceGroups/<rg>/providers/Microsoft.ManagedIdentity/userAssignedIdentities/<identityName>': {} }
  }
  properties: {
    dataLocation: dataLocation
    disableLocalAuth: true // recommended for security
    linkedDomains: [] // add custom domains if needed, update this later when we apply our custom domains to the container app
    publicNetworkAccess: 'Enabled' // or 'Disabled' for private endpoint only
  }
}
