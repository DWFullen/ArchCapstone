// storage-access-roles.bicep
// Assign Storage Blob Data Contributor role to the container app's managed identity

targetScope = 'resourceGroup'

param storageAccountResourceId string
param principalId string

resource storageBlobContributorRole 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(storageAccountResourceId, principalId, 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')
  scope: storageAccountResourceId
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
    )
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}
