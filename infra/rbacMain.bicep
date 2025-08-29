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

// For reference, needs to be modified
targetScope = 'subscription'
// RBAC Assignment Main Bicep template used for applying permissions to resources for principals. Usage described below. Administration commands included with templates.

//Set parameters for Principals(Users), Permissions, and Target Resources here.

//You must use the Object ID here.
param Principal1 string = '<principle1>' //FSSA Azure CAE Contributor-Prod

param Permission1 string = '<permission1>' //Contributor

//You must use the role definition here. It can be retrieved with: az role definition list --name "roleName" --query "[].{name:name, id:id}"
param resource1 string = '<resource1>'

//Logical Maps needed for each principal. Within each principal's map you can set up permissions with multiple rbac objects for each Role and Target Resource required.
param RBACUser1Map object = {
  rbac1: {
    roleDefinitionID: Permission1
    principalId: Principal1
    resourceGroup: resource1
  }
}

//****************************************************RESOURCES**********************************************************************
//A separate module is required for each principal. Change the RBACUserXMap in the for loops of each module to change what principal's RBACMap is being pulled from.
module rbac1 './rbacAssignment.bicep' = [
  for rbac in items(RBACUser1Map): {
    name: guid(subscription().id, rbac.value.principalId, rbac.value.roleDefinitionID)
    scope: resourceGroup(rbac.value.resourceGroup)
    params: {
      roleDefinitionID: rbac.value.roleDefinitionID
      principalId: rbac.value.principalId
    }
  }
]

/* module rbac2 './RBACAssignment.bicep' = [for rbac in items(RBACUser2Map): {
  name: guid(subscription().id, rbac.value.principalId, rbac.value.roleDefinitionID)
  scope: resourceGroup(rbac.value.resourceGroup)
  params:{
    roleDefinitionID: rbac.value.roleDefinitionID
    principalId: rbac.value.principalId
  }
}]

module rbac3 './RBACAssignment.bicep' = [for rbac in items(RBACUser3Map): {
  name: guid(subscription().id, rbac.value.principalId, rbac.value.roleDefinitionID)
  scope: resourceGroup(rbac.value.resourceGroup)
  params:{
    roleDefinitionID: rbac.value.roleDefinitionID
    principalId: rbac.value.principalId
  }
}]
 */
