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

// ---------------------------
// Parameters -AFD
// ---------------------------
@description('Azure Front Door profile name')
param afdProfileName string = 'rebelcorpo-afd'

@description('Azure Front Door endpoint name')
param afdEndpointName string = 'rebelcorpo-endpoint' //Update this to use your naming convention

@description('Custom domain to serve (must be a root or subdomain you control)')
param customDomainName string = 'rebelcorpo.com'

// @description('Container App public hostname (FQDN) to use as the default origin, e.g., myapp.<hash>.<region>.azurecontainerapps.io')
// param containerAppHostname string

//@description('Function App default hostname, e.g., myfunc.azurewebsites.net')
// param functionAppHostname string
@description('Storage Static Website hostname (no scheme), e.g., mystorage.z13.web.core.windows.net. If you are not using Static Website, you can point to a CDN-enabled blob endpoint instead.')
param storageStaticWebsiteHostname string

@description('Optional: Health probe path for origins')
param healthProbePath string = '/'

@description('Optional: Enable HTTP to HTTPS redirect at route level')
param enableHttpsOnly bool = true

@description('AFD SKU: Standard_AzureFrontDoor or Premium_AzureFrontDoor')
param afdSkuName string = 'Standard_AzureFrontDoor'

@description('Enable Azure WAF on Front Door (creates policy and associates to custom domain)')
param enableWaf bool = true

@description('Name of the WAF policy (Front Door WAF)')
param wafPolicyName string = 'rebelcorpo-afd-waf'

@description('Rate limit threshold per client IP per minute (set 0 to disable the custom rule)')
param rateLimitThreshold int = 300

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

//Nist 800-53 rev 5 compliant storage account #####################################################################################################################################################################################################

var storageAccountName = toLower('${zLocation}${azureSubscription}${applicationName}${devEnvironmentName}${applicationVersion}${abbrs.storageStorageAccounts}')

// Move these parameters somewhere else !!!!!!!!!!!!
//Private Endpoint Parameters !!!!!!!!!!!!!!!!!!!!!!
param privateEndpointName string
param storagePrivateEndpointName string
param functionAppPrivateEndpointName string //!!!!!!
param storageSubnetName string
param storageSubnetResourceId string
// Move these parameters somewhere else !!!!!!!!!!!!

resource storageAccount 'Microsoft.Storage/storageAccounts@2024-01-01' = {
  name: storageAccountName // Ignore this. This is saying that the length might be too small. It isn't.
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
var functionAppHostname = functionApp.outputs.defaultHostname

resource functionAppPrivateEndpoint 'Microsoft.Network/privateEndpoints@2024-05-01' = {
  name: '${zLocation}${azureSubscription}${applicationName}${devEnvironmentName}${applicationVersion}${abbrs.privateEndpoint}-func'
  dependsOn: [vnet]
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
output acsConnectionString string = listKeys(azureCommunicationServices.id, azureCommunicationServices.apiVersion).primaryConnectionString

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
  dependsOn: [keyVault, azureCommunicationServices]
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

//Azure Front Door #####################################################################################################################################################################################################

// Azure Front Door (Standard/Premium) - single endpoint for rebelcorpo.com
// Routes traffic to Container App (default), Function App (/api/*), Storage Static Website (/static/*)

// ---------------------------
// Resources
// ---------------------------

// AFD profile (global)
resource afdProfile 'Microsoft.Cdn/profiles@2024-02-01' = {
  name: '${zLocation}${azureSubscription}${applicationName}${devEnvironmentName}${applicationVersion}${abbrs.networkFrontDoors}'
  location: 'global'
  sku: {
    name: afdSkuName
  }
  tags: {
    app: '${applicationName}'
  }
}

// AFD endpoint (public entry point)
// Note: Child resource naming uses "parentName/childName"
resource afdEndpoint 'Microsoft.Cdn/profiles/afdEndpoints@2024-02-01' = {
  parent: afdProfile
  name: '${zLocation}${azureSubscription}${applicationName}${devEnvironmentName}${applicationVersion}${abbrs.networkFrontDoorEndpoint}'
  location: 'global'
  properties: {
    enabledState: 'Enabled'
  }
}

// Origin Groups (one per backend for independent health/probes)
resource ogContainer 'Microsoft.Cdn/profiles/originGroups@2024-02-01' = {
  parent: afdProfile
  name: 'og-container'
  properties: {
    sessionAffinityState: 'Disabled'
    healthProbeSettings: {
      probeIntervalInSeconds: 120
      probePath: healthProbePath
      probeProtocol: 'Https'
      probeRequestType: 'GET'
    }
    loadBalancingSettings: {
      sampleSize: 4
      successfulSamplesRequired: 3
      additionalLatencyInMilliseconds: 0
    }
  }
}

resource ogFunction 'Microsoft.Cdn/profiles/originGroups@2024-02-01' = {
  name: 'og-function'
  parent: afdProfile
  properties: {
    sessionAffinityState: 'Disabled'
    healthProbeSettings: {
      probeIntervalInSeconds: 120
      probePath: healthProbePath
      probeProtocol: 'Https'
      probeRequestType: 'GET'
    }
    loadBalancingSettings: {
      sampleSize: 4
      successfulSamplesRequired: 3
      additionalLatencyInMilliseconds: 0
    }
  }
}

resource ogStorage 'Microsoft.Cdn/profiles/originGroups@2024-02-01' = {
  parent: afdProfile
  name: 'og-storage'
  properties: {
    sessionAffinityState: 'Disabled'
    healthProbeSettings: {
      probeIntervalInSeconds: 120
      probePath: '/index.html'
      probeProtocol: 'Https'
      probeRequestType: 'GET'
    }
    loadBalancingSettings: {
      sampleSize: 4
      successfulSamplesRequired: 3
      additionalLatencyInMilliseconds: 0
    }
  }
}

// Origins (hostnames of your backends)
// Note: These are public origins. If you need private origins, use AFD Premium with Private Link origins.
resource originContainer 'Microsoft.Cdn/profiles/originGroups/origins@2024-02-01' = {
  name: '${afdProfile.name}/${ogContainer.name}/origin-container'
  properties: {
    hostName: myBlazorApp.outputs.fqdn //pulls output from container app module
    httpPort: 80
    httpsPort: 443
    originHostHeader: myBlazorApp.outputs.fqdn // ensure correct Host header is sent
    priority: 1
    weight: 1000
    enabledState: 'Enabled'
  }
}

resource originFunction 'Microsoft.Cdn/profiles/originGroups/origins@2024-02-01' = {
  name: '${afdProfile.name}/${ogFunction.name}/origin-function'
  properties: {
    hostName: functionAppHostname
    httpPort: 80
    httpsPort: 443
    originHostHeader: functionAppHostname
    priority: 1
    weight: 1000
    enabledState: 'Enabled'
  }
}

/* resource originStorage 'Microsoft.Cdn/profiles/originGroups/origins@2024-02-01' = {
  name: '${afdProfile.name}/${ogStorage.name}/origin-storage'
  properties: {
    hostName: storageStaticWebsiteHostname
    httpPort: 80
    httpsPort: 443
    originHostHeader: storageStaticWebsiteHostname
    priority: 1
    weight: 1000
    enabledState: 'Enabled'
  }
} */

// Custom domain for rebelcorpo.com (bind to the endpoint)
// IMPORTANT: You must add required DNS TXT/CNAME records in your DNS zone to validate and map the domain.
resource afdCustomDomain 'Microsoft.Cdn/profiles/customDomains@2024-02-01' = {
  name: '${replace(customDomainName, '.', '-')}-domain'
  parent: afdProfile
  properties: {
    hostName: customDomainName
    // Optional: Managed cert can be enabled after DNS validation completes (avoids deployment failures).
    // tlsSettings: {
    //   certificateType: 'ManagedCertificate'
    //   minimumTlsVersion: 'TLS12'
    // }
  }
}

// Front Door WAF policy (not enabled by default; this turns it on)
// Uses Microsoft Default Rule Set (OWASP) and an optional rate-limiting custom rule.
// Note: Bot Manager rules require AFD Premium (not included here).
resource wafPolicy 'Microsoft.Network/frontdoorWebApplicationFirewallPolicies@2022-05-01' = if (enableWaf) {
  name: '${zLocation}-${azureSubscription}-${applicationName}-${devEnvironmentName}-${applicationVersion}-${abbrs.networkFrontdoorWebApplicationFirewallPolicies}'
  location: 'Global'
  dependsOn: [afdProfile]
  properties: {
    policySettings: {
      enabledState: 'Enabled' // Toggle entire WAF on/off
      mode: 'Prevention' // 'Detection' to log only; 'Prevention' to block
      requestBodyCheck: 'Enabled'
    }
    managedRules: {
      managedRuleSets: [
        {
          ruleSetType: 'Microsoft_DefaultRuleSet'
          ruleSetVersion: '2.1'
        }
      ]
    }
    // Optional rate-limiting custom rule (blocks abusive IPs)
    customRules: (rateLimitThreshold > 0)
      ? {
          rules: [
            {
              name: 'RateLimitByIP'
              enabledState: 'Enabled'
              priority: 1
              ruleType: 'RateLimitRule'
              rateLimitDurationInMinutes: 1
              rateLimitThreshold: rateLimitThreshold
              matchConditions: [
                {
                  matchVariable: 'RemoteAddr'
                  operator: 'IPMatch'
                  negateCondition: false
                  matchValue: [
                    '0.0.0.0/0'
                    '::/0'
                  ]
                }
              ]
              action: 'Block'
            }
          ]
        }
      : {}
  }
}

// Associate WAF policy with your AFD custom domain (so traffic to rebelcorpo.com is protected)
resource afdSecurityPolicy 'Microsoft.Cdn/profiles/securityPolicies@2024-02-01' = if (enableWaf) {
  parent: afdProfile
  name: 'waf-security-policy'
  dependsOn: [
    afdCustomDomain
    wafPolicy
  ]
  properties: {
    parameters: {
      type: 'WebApplicationFirewall'
      wafPolicy: {
        id: wafPolicy.id
      }
      associations: [
        {
          domains: [
            {
              id: afdCustomDomain.id
            }
          ]
          // Optional: restrict to certain paths only (defaults to all)
          // patternsToMatch: [ '/*' ]
        }
      ]
    }
  }
}

// ---------------------------
// Routes (path-based), mapped to the endpoint + custom domain
// ---------------------------

// Default route to Container App: /*
// tip: Add additional domain bindings to routes via the `domains` property.
resource routeDefault 'Microsoft.Cdn/profiles/routes@2024-02-01' = {
  parent: afdProfile
  name: 'route-default'
  dependsOn: [
    afdEndpoint
    ogContainer
    afdCustomDomain
  ]
  properties: {
    // For routes, endpointName expects the short endpoint name, not "profile/endpoint"
    endpointName: afdEndpointName
    originGroup: { id: ogContainer.id }
    supportedProtocols: ['Https']
    httpsRedirect: enableHttpsOnly ? 'Enabled' : 'Disabled'
    linkToDefaultDomain: 'Disabled'
    patternsToMatch: ['/*']
    forwardingProtocol: 'MatchRequest'
    domains: [{ id: afdCustomDomain.id }]
  }
}

resource routeApi 'Microsoft.Cdn/profiles/routes@2024-02-01' = {
  parent: afdProfile
  name: 'route-api'
  dependsOn: [
    afdEndpoint
    ogContainer
    afdCustomDomain
  ]
  properties: {
    endpointName: afdEndpointName
    originGroup: { id: ogFunction.id }
    supportedProtocols: ['Https']
    httpsRedirect: enableHttpsOnly ? 'Enabled' : 'Disabled'
    linkToDefaultDomain: 'Disabled'
    patternsToMatch: ['/api/*']
    forwardingProtocol: 'MatchRequest'
    domains: [{ id: afdCustomDomain.id }]
  }
}

resource routeStatic 'Microsoft.Cdn/profiles/routes@2024-02-01' = {
  parent: afdProfile
  name: 'route-static'
  dependsOn: [
    afdEndpoint
    ogContainer
    afdCustomDomain
  ]
  properties: {
    endpointName: afdEndpointName
    originGroup: { id: ogStorage.id }
    supportedProtocols: ['Https']
    httpsRedirect: enableHttpsOnly ? 'Enabled' : 'Disabled'
    linkToDefaultDomain: 'Disabled'
    patternsToMatch: ['/static/*']
    forwardingProtocol: 'MatchRequest'
    domains: [{ id: afdCustomDomain.id }]
  }
}

// ---------------------------
// Outputs
// ---------------------------
output afdProfileId string = afdProfile.id
output afdEndpointHost string = '${afdEndpointName}.azurefd.net'
output afdCustomDomainId string = afdCustomDomain.id
