// storage-access-roles.bicep
// Assign Storage Blob Data Contributor role to the container app's managed identity

targetScope = 'resourceGroup'

/* param storageAccountResourceId string
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
 */

// For reference, needs to be modified
@description('Specifies the role definition ID used in the role assignment.')
param roleDefinitionID string

@description('Specifies the principal ID assigned to the role.')
param principalId string

var roleAssignmentName= guid(resourceGroup().id, principalId, roleDefinitionID)

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: roleAssignmentName
  properties: {
    roleDefinitionId: roleDefinitionID
    principalId: principalId
    principalType: 'User'
  }
}
