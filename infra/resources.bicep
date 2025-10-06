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
// Removed unused parameter 'principalId'
var abbrs = loadJsonContent('./abbreviations.json')
var resourceToken = uniqueString(subscription().id, resourceGroup().id, location)

// Virtual  Network ##############################################################################################################################################################################################################################
resource vnet 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: '${zLocation}-${azureSubscription}-${applicationName}-${devEnvironmentName}-${applicationVersion}-${abbrs.networkVirtualNetworks}'
  location: location
  properties: {
    addressSpace: { addressPrefixes: ['10.0.0.0/16'] }
    subnets: [
      {
        name: '${zLocation}-${azureSubscription}-${applicationName}-${devEnvironmentName}-${applicationVersion}-${abbrs.storageBlobContainers}-${abbrs.networkVirtualNetworksSubnets}'
        properties: { addressPrefix: '10.0.0.0/24' }
      }
      {
        name: '${zLocation}-${azureSubscription}-${applicationName}-${devEnvironmentName}-${applicationVersion}-${abbrs.webSitesFunctions}-${abbrs.networkVirtualNetworksSubnets}'
        properties: { addressPrefix: '10.0.1.0/24' }
      }
    ]
  }
}

//output storagePrivateEndpointSubnetResourceId string = '${vnet.id}/subnets/${vnet.properties.subnets[0].name}'

// Monitor application with Azure Monitor #######################################################################################################################################################################################################
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

// Container registry ############################################################################################################################################################################################################################
// Deterministic, compliant ACR name (min 5 chars, global uniqueness)
var containerRegistryName = toLower('acr${take(uniqueString(subscription().id, resourceGroup().id), 16)}')
module containerRegistry 'br/public:avm/res/container-registry/registry:0.1.1' = {
  name: 'registry'
  params: {
    name: containerRegistryName
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

// Container apps environment #####################################################################################################################################################################################################################
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
    scaleMaxReplicas: 1
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
output MANAGED_IDENTITY_PRINCIPAL_ID string = myBlazorAppIdentity.outputs.principalId
output MY_BLAZOR_APP_FQDN string = myBlazorApp.outputs.fqdn
output FUNCTION_APP_HOSTNAME string = functionApp.outputs.defaultHostname

//Nist 800-53 rev 5 compliant storage account #####################################################################################################################################################################################################

var storageAccountNameBase = '${zLocation}${azureSubscription}${applicationName}${devEnvironmentName}${applicationVersion}${abbrs.storageStorageAccounts}'
var storageAccountName = length(storageAccountNameBase) >= 3
  ? toLower(storageAccountNameBase)
  : toLower('st${take(uniqueString(resourceGroup().id), 13)}')

// Move these parameters somewhere else !!!!!!!!!!!!
//Private Endpoint Parameters !!!!!!!!!!!!!!!!!!!!!!
param privateEndpointName string
param storagePrivateEndpointName string
param functionAppPrivateEndpointName string //!!!!!!
param storageSubnetName string
// Move these parameters somewhere else !!!!!!!!!!!!

resource storageAccount 'Microsoft.Storage/storageAccounts@2024-01-01' = {
  // Deterministic, compliant storage account name (min 3 chars, <= 24, lowercase, alphanumeric)
  name: toLower('st${take(uniqueString(subscription().id, resourceGroup().id), 18)}')
  location: location
  tags: union(tags, {
    azdServiceName: 'nist-storage-account'
    zLocation: zLocation
    azSubscriptionName: azureSubscription
    applicationName: applicationName
    devEnvironmentName: devEnvironmentName
    applicationVersion: applicationVersion
  })
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    dnsEndpointType: 'Standard'
    allowedCopyScope: 'PrivateLink'
    defaultToOAuthAuthentication: true
    publicNetworkAccess: 'Disabled'
    allowCrossTenantReplication: false
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    allowSharedKeyAccess: true
    largeFileSharesState: 'Enabled'
    networkAcls: {
      resourceAccessRules: [
        {
          tenantId: subscription().tenantId
          resourceId: resourceId('Microsoft.Security/datascanners', 'storageDataScanner')
        }
      ]
      bypass: 'AzureServices'
      virtualNetworkRules: []
      ipRules: []
      defaultAction: 'Deny'
    }
    supportsHttpsTrafficOnly: true
    encryption: {
      requireInfrastructureEncryption: true
      services: {
        file: {
          keyType: 'Account'
          enabled: true
        }
        blob: {
          keyType: 'Account'
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
    accessTier: 'Hot'
  }
}

output storageStaticWebsiteHostname string = storageAccount.properties.primaryEndpoints.web

//Event Grid resource used to live here. Moved to Bicep Graveyard in docs.

resource storageAccountBlobService 'Microsoft.Storage/storageAccounts/blobServices@2024-01-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
    containerDeleteRetentionPolicy: {
      enabled: true
      days: 7
    }
    cors: {
      corsRules: []
    }
    deleteRetentionPolicy: {
      allowPermanentDelete: false
      enabled: true
      days: 7
    }
  }
}

resource storageAccountFileService 'Microsoft.Storage/storageAccounts/fileServices@2024-01-01' = {
  parent: storageAccount
  name: 'default'
  // Removed invalid sku block
  properties: {
    protocolSettings: {
      smb: {}
    }
    cors: {
      corsRules: []
    }
    shareDeleteRetentionPolicy: {
      enabled: true
      days: 7
    }
  }
}

resource storageAccountQueueService 'Microsoft.Storage/storageAccounts/queueServices@2024-01-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
    cors: {
      corsRules: []
    }
  }
}

resource storageAccountTableService 'Microsoft.Storage/storageAccounts/tableServices@2024-01-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
    cors: {
      corsRules: []
    }
  }
}

resource storageAccountBlobContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2024-01-01' = {
  parent: storageAccountBlobService
  name: '${zLocation}-${azureSubscription}-${applicationName}-${devEnvironmentName}-${applicationVersion}-${abbrs.storageBlobContainers}'
  properties: {
    immutableStorageWithVersioning: {
      enabled: false
    }
    defaultEncryptionScope: '$account-encryption-key'
    denyEncryptionScopeOverride: false
    publicAccess: 'None'
  }
}

resource nistStoragePrivateEndpoint 'Microsoft.Network/privateEndpoints@2024-05-01' = {
  name: '${zLocation}${azureSubscription}${applicationName}${devEnvironmentName}${applicationVersion}${abbrs.privateEndpoint}'
  location: location
  tags: union(tags, {
    azdServiceName: 'nist-storage-private-endpoint'
    zLocation: zLocation
    azSubscription: azureSubscription
    applicationName: applicationName
    devEnvironmentName: devEnvironmentName
    applicationVersion: applicationVersion
  })
  properties: {
    privateLinkServiceConnections: [
      {
        name: storageSubnetName
        id: resourceId('Microsoft.Network/privateLinkServiceConnections', storagePrivateEndpointName)
        properties: {
          privateLinkServiceId: resourceId('Microsoft.Storage/storageAccounts', storageAccountName)
          groupIds: [
            'blob'
          ]
          privateLinkServiceConnectionState: {
            status: 'Approved'
            description: 'Auto-Approved'
            actionsRequired: 'None'
          }
        }
      }
    ]
    manualPrivateLinkServiceConnections: []
    customNetworkInterfaceName: '${privateEndpointName}nic'
    subnet: {
      id: '${vnet.id}/subnets/${vnet.properties.subnets[0].name}' //find a way to call this by subnet name rather than index reference
    }
    ipConfigurations: []
    customDnsConfigs: []
  }
}

output storageAccountId string = storageAccount.id

// Function App #####################################################################################################################################################################################################

var functionPlanName = toLower('${zLocation}-${azureSubscription}-${applicationName}-${devEnvironmentName}-${applicationVersion}-${abbrs.webServerFarms}${abbrs.webSitesFunctions}')
var functionAppName = toLower('${zLocation}-${azureSubscription}-${applicationName}-${devEnvironmentName}-${applicationVersion}-${abbrs.webSitesFunctions}')

module appServicePlan 'br/public:avm/res/web/serverfarm:0.1.1' = {
  name: 'appserviceplan'
  params: {
    name: !empty(functionPlanName) ? functionPlanName : '${abbrs.webServerFarms}${resourceToken}'
    sku: {
      name: 'FC1'
      tier: 'FlexConsumption'
    }
    reserved: true
    location: location
    tags: tags
    zoneRedundant: false
  }
}

module functionApp 'br/public:avm/res/web/site:0.16.0' = {
  name: functionAppName
  params: {
    kind: 'functionapp,linux'
    name: functionAppName
    location: location
    tags: union(tags, { 'azd-service-name': 'api' })
    serverFarmResourceId: appServicePlan.outputs.resourceId
    managedIdentities: {
      systemAssigned: true
    }
    functionAppConfig: {
      deployment: {
        storage: {
          type: 'blobContainer'
          value: '${storageAccount.properties.primaryEndpoints.blob}${functionAppName}'
          authentication: {
            type: 'SystemAssignedIdentity'
          }
        }
      }
      scaleAndConcurrency: {
        maximumInstanceCount: 100
        instanceMemoryMB: 512
      }
      runtime: {
        name: 'dotnet-isolated'
        version: '8.0'
      }
    }
    siteConfig: {
      alwaysOn: false
    }
    configs: [
      {
        name: 'appsettings'
        properties: {
          AzureWebJobsStorage__credential: 'managedidentity'
          AzureWebJobsStorage__blobServiceUri: 'https://${storageAccount.name}.blob.${environment().suffixes.storage}'
          AzureWebJobsStorage__queueServiceUri: 'https://${storageAccount.name}.queue.${environment().suffixes.storage}'
          AzureWebJobsStorage__tableServiceUri: 'https://${storageAccount.name}.table.${environment().suffixes.storage}'
          APPLICATIONINSIGHTS_CONNECTION_STRING: monitoring.outputs.applicationInsightsConnectionString
          APPLICATIONINSIGHTS_AUTHENTICATION_STRING: 'Authorization=AAD'
        }
      }
    ]
  }
}

output functionAppPrincipalId string = functionApp.outputs.?systemAssignedMIPrincipalId ?? ''

resource functionAppPrivateEndpoint 'Microsoft.Network/privateEndpoints@2024-05-01' = {
  name: '${zLocation}${azureSubscription}${applicationName}${devEnvironmentName}${applicationVersion}${abbrs.privateEndpoint}-func'
  location: location
  tags: union(tags, {
    azdServiceName: 'functionapp-private-endpoint'
    zLocation: zLocation
    azSubscription: azureSubscription
    applicationName: applicationName
    devEnvironmentName: devEnvironmentName
    applicationVersion: applicationVersion
  })
  properties: {
    privateLinkServiceConnections: [
      {
        name: functionAppName
        id: resourceId('Microsoft.Network/privateLinkServiceConnections', functionAppPrivateEndpointName)
        properties: {
          privateLinkServiceId: functionApp.outputs.resourceId
          groupIds: [
            'sites'
          ]
          privateLinkServiceConnectionState: {
            status: 'Approved'
            description: 'Auto-Approved'
            actionsRequired: 'None'
          }
        }
      }
    ]
    manualPrivateLinkServiceConnections: []
    customNetworkInterfaceName: '${functionAppName}-nic'
    subnet: {
      id: '${vnet.id}/subnets/${vnet.properties.subnets[1].name}' //find a way to call this by subnet name rather than index reference
    }
    ipConfigurations: []
    customDnsConfigs: []
  }
}

// Azure Communication Services #####################################################################################################################################################################################################
var azureCommunicationServicesName = toLower('${zLocation}-${azureSubscription}-${applicationName}-${devEnvironmentName}-${applicationVersion}-${abbrs.azureCommunicationServices}')
param dataLocation string = 'United States'

resource azureCommunicationServices 'Microsoft.Communication/communicationServices@2025-05-01' = {
  name: azureCommunicationServicesName
  location: 'global' //This is the only valid location for Communication Services
  tags: union(tags, {
    azdServiceName: 'acs'
    zLocation: zLocation
    azSubscription: azureSubscription
    applicationName: applicationName
    devEnvironmentName: devEnvironmentName
    applicationVersion: applicationVersion
  })
  identity: {
    type: 'SystemAssigned' // or 'UserAssigned' if you want to use a managed identity
    // userAssignedIdentities: { '/subscriptions/<subId>/resourceGroups/<rg>/providers/Microsoft.ManagedIdentity/userAssignedIdentities/<identityName>': {} }
  }
  properties: {
    dataLocation: dataLocation
    disableLocalAuth: true // recommended for security
    linkedDomains: [] // add custom domains if needed, update this later when we apply our custom domains to the container app
    publicNetworkAccess: 'Disabled' // or 'Disabled' for private endpoint only
  }
}

output AZURE_COMMUNICATION_SERVICES_NAME string = azureCommunicationServices.name

// Azure Key Vault #####################################################################################################################################################################################################

resource keyVault 'Microsoft.KeyVault/vaults@2024-12-01-preview' = {
  name: '${zLocation}${azureSubscription}${applicationName}${devEnvironmentName}${applicationVersion}${abbrs.keyVaultVaults}'
  location: location
  tags: union(tags, {
    azdServiceName: 'keyvault'
    zLocation: zLocation
    azSubscription: azureSubscription
    applicationName: applicationName
    devEnvironmentName: devEnvironmentName
    applicationVersion: applicationVersion
  })
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    accessPolicies: []
  }
}

output AZURE_KEY_VAULT_NAME string = keyVault.name
output keyVaultUri string = keyVault.properties.vaultUri

resource acsConnectionStringSecret 'Microsoft.KeyVault/vaults/secrets@2024-12-01-preview' = {
  parent: keyVault
  name: 'ACS-ConnectionString'
  properties: {
    value: azureCommunicationServices.listKeys().primaryConnectionString
  }
}

@secure()
param BTCPAY_API_KEY string

@secure()
param BTCPAY_API_ID string

resource btcpayApiKeySecret 'Microsoft.KeyVault/vaults/secrets@2024-12-01-preview' = {
  parent: keyVault
  name: 'BTCPayApiKey'
  properties: {
    value: BTCPAY_API_KEY
  }
}

resource btcpayApiIdSecret 'Microsoft.KeyVault/vaults/secrets@2024-12-01-preview' = {
  parent: keyVault
  name: 'BTCPayApiId'
  properties: {
    value: BTCPAY_API_ID
  }
}

// Front Door removed; now deployed via separate module.
