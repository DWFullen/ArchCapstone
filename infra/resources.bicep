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

// Virtual  Network
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
    ]
  }
}

//output storagePrivateEndpointSubnetResourceId string = '${vnet.id}/subnets/${vnet.properties.subnets[0].name}'

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

//Nist 800-53 rev 5 compliant storage account #####################################################################################################################################################################################################

var storageAccountName = toLower('${zLocation}${azureSubscription}${applicationName}${devEnvironmentName}${applicationVersion}${abbrs.storageStorageAccounts}')
// Removed unused parameter for system topic name
//param location string
//Private Endpoint Parameters
param privateEndpointName string
param storagePrivateEndpointName string
param storageSubnetName string
param storageSubnetResourceId string
/* 
param privateEndpoints_zus1_iot_nisttest_sbx_v2_pe_name string = 'zus1-iot-nisttest-sbx-v2-pe'
param virtualNetworks_zus1_iot_nisttest_sbx_v2_vnet_name string = 'zus1-iot-nisttest-sbx-v2-vnet'
param networkSecurityGroups_zus1_iot_nisttest_sbx_v2_nsg_name string = 'zus1-iot-nisttest-sbx-v2-nsg'
param virtualNetworks_zus1_iot_automation_sbx_vnet_externalid string = '/subscriptions/5e75bd1d-92d0-464c-809f-0992c3cf0ebe/resourceGroups/zus1-iot-automation-sbx-v2-rg/providers/Microsoft.Network/virtualNetworks/zus1-iot-automation-sbx-vnet' 
*/

resource storageAccount 'Microsoft.Storage/storageAccounts@2024-01-01' = {
  name: storageAccountName
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
    // Removed tier property (read-only)
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

/* resource eventGridSystemTopic 'Microsoft.EventGrid/systemTopics@2025-02-15' = {
  name: '${zLocation}-${azureSubscription}-${applicationName}-${devEnvironmentName}-${applicationVersion}-${abbrs.eventGridDomainsTopics}'
  location: location
  tags: union(tags, {
    azdServiceName: 'nist-eventgrid-systemtopic'
    zLocation: zLocation
    azSubscription: azureSubscription
    applicationName: applicationName
    devEnvironmentName: devEnvironmentName
    applicationVersion: applicationVersion
  })
  properties: {
    source: storageAccount.id
    topicType: 'microsoft.storage.storageaccounts'
  }
}
 */
/* resource eventGridSystemTopicAntimalwareSubscription 'Microsoft.EventGrid/systemTopics/eventSubscriptions@2025-02-15' = {
  parent: eventGridSystemTopic
  name: '${zLocation}-${azureSubscription}-${applicationName}-${devEnvironmentName}-${applicationVersion}-${abbrs.antiMalwareSubscription}'
  properties: {
    destination: {
      properties: {
        //endpointUrl: 'https://your-storage-event-handler-endpoint' // Replace with your Azure Function or Logic App endpoint
        maxEventsPerBatch: 1
        preferredBatchSizeInKilobytes: 64
        //azureActiveDirectoryTenantId: '33e01921-4d64-4f8c-a055-5bdaffd5e33d'
        //azureActiveDirectoryApplicationIdOrUri: 'f1f8da5f-609a-401d-85b2-d498116b7265'
      }
      endpointType: 'WebHook'
    }
    filter: {
      includedEventTypes: [
        'Microsoft.Storage.BlobCreated'
      ]
      advancedFilters: [
        {
          values: [
            'BlockBlob'
          ]
          operatorType: 'StringContains'
          key: 'data.blobType'
        }
      ]
    }
    eventDeliverySchema: 'EventGridSchema'
    retryPolicy: {
      maxDeliveryAttempts: 30
      eventTimeToLiveInMinutes: 1440
    }
  }
}
 */
resource storageAccountBlobService 'Microsoft.Storage/storageAccounts/blobServices@2024-01-01' = {
  parent: storageAccount
  name: 'default'
  // Removed invalid sku block
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
  dependsOn: [vnet]
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

//Additional Resources

//Storage Account
/* module storageAccount 'br/public:avm/res/storage/storage-account:0.5.0' = {
  name: 'storageAccount'
  params: {
    name: toLower('${zLocation}${azureSubscription}${applicationName}${devEnvironmentName}${applicationVersion}${abbrs.storageAccounts}')
    location: location
    tags: tags
    sku: 'Standard_LRS'
    kind: 'StorageV2'
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'
    enableHierarchicalNamespace: false
    roleAssignments: [
      {
        principalId: myBlazorAppIdentity.outputs.principalId
        principalType: 'ServicePrincipal'
        roleDefinitionIdOrName: subscriptionResourceId(
          'Microsoft.Authorization/roleDefinitions',
          'ba92f5b4-2d11-453d-a403-e96b0029c9fe' // Storage Blob Data Contributor
        )
      }
    ]
  }
}
 */

/* // Storage Account for file storage and serving
resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: '${uniqueString(resourceGroup().id)}storage'
  location: resourceGroup().location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    supportsHttpsTrafficOnly: true
  }
}

// Event Grid Topic for eventing
resource eventGridTopic 'Microsoft.EventGrid/topics@2023-06-01-preview' = {
  name: '${uniqueString(resourceGroup().id)}eventgrid'
  location: resourceGroup().location
  properties: {
    inputSchema: 'EventGridSchema'
  }
}

// Event Grid Subscription to Storage Account (integration point)
resource eventGridSubscription 'Microsoft.EventGrid/eventSubscriptions@2023-06-01-preview' = {
  name: 'storage-file-requested'
  scope: storageAccount.id
  properties: {
    destination: {
      endpointType: 'WebHook'
      properties: {
        // TODO: Replace with your Azure Function or Logic App endpoint for sending email
        endpointUrl: 'https://your-email-function-endpoint'
      }
    }
    filter: {
      includedEventTypes: [
        'Microsoft.Storage.BlobCreated'
        // Add other event types as needed
      ]
    }
  }
}

// TODO: Assign access to container app (managed identity or connection string)
// TODO: Integrate with Azure Front Door in future for global routing and CDN
 */
