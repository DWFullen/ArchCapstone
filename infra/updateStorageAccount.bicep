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
