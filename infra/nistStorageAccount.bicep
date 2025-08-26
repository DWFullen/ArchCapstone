param storageAccountName string
param systemTopics_zus1iotnisttestsbxv2sa_d146e609_f83b_49c4_8f5d_c8f01a9bad69_name string = 'zus1iotnisttestsbxv2sa-d146e609-f83b-49c4-8f5d-c8f01a9bad69'
param location string
//Private Endpoint Parameters
param privateEndpointName string
param StorageAccountSubnetName string
param StorageAccountSubnetId string
/* 
param privateEndpoints_zus1_iot_nisttest_sbx_v2_pe_name string = 'zus1-iot-nisttest-sbx-v2-pe'
param virtualNetworks_zus1_iot_nisttest_sbx_v2_vnet_name string = 'zus1-iot-nisttest-sbx-v2-vnet'
param networkSecurityGroups_zus1_iot_nisttest_sbx_v2_nsg_name string = 'zus1-iot-nisttest-sbx-v2-nsg'
param virtualNetworks_zus1_iot_automation_sbx_vnet_externalid string = '/subscriptions/5e75bd1d-92d0-464c-809f-0992c3cf0ebe/resourceGroups/zus1-iot-automation-sbx-v2-rg/providers/Microsoft.Network/virtualNetworks/zus1-iot-automation-sbx-vnet' 
*/


param AgencyNameTag string = 'Agency-Name'
param BillingCodeTag string = 'Billing-Code'
param EnvironmentTierTag string = 'Environment-Tier'
param ApplicationNameTag string = 'Application-Name'
param ResourceOwnerTag string = 'Resource-Owner'
param InformationIdTag string = 'InformationId'
param ProcurementIdTag string = 'ProcurementId'

param AgencyNameTagValue string
param BillingCodeTagValue string
param EnvironmentTierTagValue string
param ApplicationNameTagValue string
param ResourceOwnerTagValue string
param InformationIdTagValue string
param ProcurementIdTagValue string

resource storageAccountName_resource 'Microsoft.Storage/storageAccounts@2024-01-01' = {
  name: storageAccountName
  location: location
  tags: {
    '${AgencyNameTag}': AgencyNameTagValue
    '${BillingCodeTag}': BillingCodeTagValue
    '${EnvironmentTierTag}': EnvironmentTierTagValue
    '${ApplicationNameTag}': ApplicationNameTagValue
    '${ResourceOwnerTag}': ResourceOwnerTagValue
    '${InformationIdTag}': InformationIdTagValue
    '${ProcurementIdTag}': ProcurementIdTagValue
  }
  sku: {
    name: 'Standard_LRS'
    tier: 'Standard'
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
          tenantId: '2199bfba-a409-4f13-b0c4-18b45933d88d'
          resourceId: '/subscriptions/f8d01a59-c415-4364-95a4-babff4c37b0f/providers/Microsoft.Security/datascanners/storageDataScanner'
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

resource systemTopics_zus1iotnisttestsbxv2sa_d146e609_f83b_49c4_8f5d_c8f01a9bad69_name_resource 'Microsoft.EventGrid/systemTopics@2025-02-15' = {
  name: systemTopics_zus1iotnisttestsbxv2sa_d146e609_f83b_49c4_8f5d_c8f01a9bad69_name
  location: location
  tags: {
    '${AgencyNameTag}': AgencyNameTagValue
    '${BillingCodeTag}': BillingCodeTagValue
    '${EnvironmentTierTag}': EnvironmentTierTagValue
    '${ApplicationNameTag}': ApplicationNameTagValue
    '${ResourceOwnerTag}': ResourceOwnerTagValue
    '${InformationIdTag}': InformationIdTagValue
    '${ProcurementIdTag}': ProcurementIdTagValue
  }
  properties: {
    source: storageAccountName_resource.id
    topicType: 'microsoft.storage.storageaccounts'
  }
}

resource systemTopics_zus1iotnisttestsbxv2sa_d146e609_f83b_49c4_8f5d_c8f01a9bad69_name_StorageAntimalwareSubscription 'Microsoft.EventGrid/systemTopics/eventSubscriptions@2025-02-15' = {
  parent: systemTopics_zus1iotnisttestsbxv2sa_d146e609_f83b_49c4_8f5d_c8f01a9bad69_name_resource
  name: 'StorageAntimalwareSubscription'
  properties: {
    destination: {
      properties: {
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

resource storageAccountName_default 'Microsoft.Storage/storageAccounts/blobServices@2024-01-01' = {
  parent: storageAccountName_resource
  name: 'default'
  sku: {
    name: 'Standard_LRS'
    tier: 'Standard'
  }
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

resource Microsoft_Storage_storageAccounts_fileServices_storageAccountName_default 'Microsoft.Storage/storageAccounts/fileServices@2024-01-01' = {
  parent: storageAccountName_resource
  name: 'default'
  sku: {
    name: 'Standard_LRS'
    tier: 'Standard'
  }
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

resource storageAccountName_storageAccountName_d00a04e4_1e14_4195_9812_688cefccf1d5 'Microsoft.Storage/storageAccounts/privateEndpointConnections@2024-01-01' = {
  parent: storageAccountName_resource
  name: '${storageAccountName}.d00a04e4-1e14-4195-9812-688cefccf1d5'
  properties: {
    privateEndpoint: {}
    privateLinkServiceConnectionState: {
      status: 'Approved'
      description: 'Auto-Approved'
      actionRequired: 'None'
    }
  }
  // dependsOn: [virtualNetworks_zus1_iot_nisttest_sbx_v2_vnet_name_zus1_iot_nisttest_sbx_v2_snet]
}

resource Microsoft_Storage_storageAccounts_queueServices_storageAccountName_default 'Microsoft.Storage/storageAccounts/queueServices@2024-01-01' = {
  parent: storageAccountName_resource
  name: 'default'
  properties: {
    cors: {
      corsRules: []
    }
  }
}

resource Microsoft_Storage_storageAccounts_tableServices_storageAccountName_default 'Microsoft.Storage/storageAccounts/tableServices@2024-01-01' = {
  parent: storageAccountName_resource
  name: 'default'
  properties: {
    cors: {
      corsRules: []
    }
  }
}

resource storageAccountName_default_zus1iotnisttestsbxv2cr 'Microsoft.Storage/storageAccounts/blobServices/containers@2024-01-01' = {
  parent: storageAccountName_default
  name: 'zus1iotnisttestsbxv2cr'
  properties: {
    immutableStorageWithVersioning: {
      enabled: false
    }
    defaultEncryptionScope: '$account-encryption-key'
    denyEncryptionScopeOverride: false
    publicAccess: 'None'
  }

}

resource privateEndpoints_zus1_iot_nisttest_sbx_v2_pe_name_resource 'Microsoft.Network/privateEndpoints@2024-05-01' = {
  name: privateEndpointName
  location: location
  tags: {
    '${AgencyNameTag}': AgencyNameTagValue
    '${BillingCodeTag}': BillingCodeTagValue
    '${EnvironmentTierTag}': EnvironmentTierTagValue
    '${ApplicationNameTag}': ApplicationNameTagValue
    '${ResourceOwnerTag}': ResourceOwnerTagValue
    '${InformationIdTag}': InformationIdTagValue
    '${ProcurementIdTag}': ProcurementIdTagValue
  }
  properties: {
    privateLinkServiceConnections: [
      {
        name: StorageAccountSubnetName//'${privateEndpoints_zus1_iot_nisttest_sbx_v2_pe_name}_ff3140d5-2f1e-470a-833b-b0ab7410c019'
        id: resourceId('Microsoft.Network/privateLinkServiceConnections', privateEndpointName)
        properties: {
          privateLinkServiceId: resourceId('Microsoft.Storage/storageAccounts',storageAccountName)
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
    customNetworkInterfaceName: '${privateEndpointName}-nic'
    subnet: {
      id: StorageAccountSubnetId//'${virtualNetworks_zus1_iot_automation_sbx_vnet_externalid}/subnets/zus1-iot-automation-sbx-v2-aa-pe-sn'
    }
    ipConfigurations: []
    customDnsConfigs: []
  }
}


//________________________________________________________________________________Where the light does not reach________________________________________________________________________________

/* resource virtualNetworks_zus1_iot_nisttest_sbx_v2_vnet_name_resource 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: virtualNetworks_zus1_iot_nisttest_sbx_v2_vnet_name
  location: location
  tags: {
    '${AgencyNameTag}': AgencyNameValue
    '${BillingCodeTag}': BillingCodeTagValue
    '${EnvironmentTierTag}': EnvironmentTierValue
    '${ApplicationNameTag}': ApplicationNameValue
    '${ResourceOwnerTag}': ResourceOwnerValue
    '${InformationIdTag}': InformationIdValue
    '${ProcurementIdTag}': ProcurementIdValue
  }
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    encryption: {
      enabled: true
      enforcement: 'AllowUnencrypted'
    }
    privateEndpointVNetPolicies: 'Disabled'
    subnets: [
      {
        name: 'zus1-iot-nisttest-sbx-v2-snet'
        id: virtualNetworks_zus1_iot_nisttest_sbx_v2_vnet_name_zus1_iot_nisttest_sbx_v2_snet.id
        properties: {
          addressPrefixes: [
            '10.0.0.0/24'
          ]
          networkSecurityGroup: {
            id: networkSecurityGroups_zus1_iot_nisttest_sbx_v2_nsg_name_resource.id
          }
          serviceEndpoints: [
            {
              service: 'Microsoft.Storage'
              locations: [
                location
                'westus'
                'westus3'
              ]
            }
            {
              service: 'Microsoft.ContainerRegistry'
              locations: [
                '*'
              ]
            }
            {
              service: 'Microsoft.Web'
              locations: [
                '*'
              ]
            }
          ]
          delegations: []
          privateEndpointNetworkPolicies: 'NetworkSecurityGroupEnabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
        type: 'Microsoft.Network/virtualNetworks/subnets'
      }
    ]
    virtualNetworkPeerings: []
    enableDdosProtection: false
  }
}
 */

 /* resource virtualNetworks_zus1_iot_nisttest_sbx_v2_vnet_name_zus1_iot_nisttest_sbx_v2_snet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' = {
  name: '${virtualNetworks_zus1_iot_nisttest_sbx_v2_vnet_name}/zus1-iot-nisttest-sbx-v2-snet'
  properties: {
    addressPrefixes: [
      '10.0.0.0/24'
    ]
    networkSecurityGroup: {
      id: networkSecurityGroups_zus1_iot_nisttest_sbx_v2_nsg_name_resource.id
    }
    serviceEndpoints: [
      {
        service: 'Microsoft.Storage'
        locations: [
          location
          'westus'
          'westus3'
        ]
      }
      {
        service: 'Microsoft.ContainerRegistry'
        locations: [
          '*'
        ]
      }
      {
        service: 'Microsoft.Web'
        locations: [
          '*'
        ]
      }
    ]
    delegations: []
    privateEndpointNetworkPolicies: 'NetworkSecurityGroupEnabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
  }
  dependsOn: [
    virtualNetworks_zus1_iot_nisttest_sbx_v2_vnet_name_resource 
  ]
}
 */

 /*
 resource privateEndpoints_zus1_iot_nisttest_sbx_v2_pe_name_resource 'Microsoft.Network/privateEndpoints@2024-05-01' = {
  name: privateEndpoints_zus1_iot_nisttest_sbx_v2_pe_name
  location: location
  tags: {
    '${AgencyNameTag}': AgencyNameValue
    '${BillingCodeTag}': BillingCodeTagValue
    '${EnvironmentTierTag}': EnvironmentTierValue
    '${ApplicationNameTag}': ApplicationNameValue
    '${ResourceOwnerTag}': ResourceOwnerValue
    '${InformationIdTag}': InformationIdValue
    '${ProcurementIdTag}': ProcurementIdValue
  }
  properties: {
    privateLinkServiceConnections: [
      {
        name: '${privateEndpoints_zus1_iot_nisttest_sbx_v2_pe_name}_ff3140d5-2f1e-470a-833b-b0ab7410c019'
        //id: '${privateEndpoints_zus1_iot_nisttest_sbx_v2_pe_name_resource.id}/privateLinkServiceConnections/${privateEndpoints_zus1_iot_nisttest_sbx_v2_pe_name}_ff3140d5-2f1e-470a-833b-b0ab7410c019'
        properties: {
          privateLinkServiceId: storageAccountName_resource.id
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
    subnet: {
      id: '${virtualNetworks_zus1_iot_automation_sbx_vnet_externalid}/subnets/zus1-iot-automation-sbx-v2-aa-pe-sn'
    }
    ipConfigurations: []
    customDnsConfigs: [
      {
        //fqdn: environment()
        ipAddresses: [
          '172.21.248.6'
        ]
      }
    ]
  }
}
 */

 /* 
 resource networkSecurityGroups_zus1_iot_nisttest_sbx_v2_nsg_name_resource 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: networkSecurityGroups_zus1_iot_nisttest_sbx_v2_nsg_name
  location: location
  tags: {
    '${AgencyNameTag}': AgencyNameValue
    '${BillingCodeTag}': BillingCodeTagValue
    '${EnvironmentTierTag}': EnvironmentTierValue
    '${ApplicationNameTag}': ApplicationNameValue
    '${ResourceOwnerTag}': ResourceOwnerValue
    '${InformationIdTag}': InformationIdValue
    '${ProcurementIdTag}': ProcurementIdValue
  }
  properties: {
    securityRules: []
  }
}
 */
