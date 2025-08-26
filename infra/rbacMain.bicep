// rbacMain.bicep
// This file calls the storage-access-roles.bicep module and passes the storage account resource ID and principal ID.

param storageAccountResourceId string
param principalId string

module storageAccessRoles './storage-access-roles.bicep' = {
  name: 'storageAccessRoles'
  params: {
    storageAccountResourceId: storageAccountResourceId
    principalId: principalId
  }
}
