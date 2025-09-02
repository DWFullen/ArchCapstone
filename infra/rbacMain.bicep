// rbacMain.bicep
// This file calls the storage-access-roles.bicep module and passes the storage account resource ID and principal ID.

param storageAccountResourceId string
param principalId string

/* module storageAccessRoles './storage-access-roles.bicep' = {
  name: 'storageAccessRoles'
  params: {
    storageAccountResourceId: storageAccountResourceId
    principalId: principalId
  }
} */

// For reference, needs to be modified
targetScope = 'subscription'
// RBAC Assignment Main Bicep template used for applying permissions to resources for principals. Usage described below. Administration commands included with templates.

//Set parameters for Principals(Users), Permissions, and Target Resources here.

//You must use the Object ID here.
param Principal1 string = principalId //Example: '72f988bf-86f1-41af-91ab-2d7cd011db47' for a user in Azure AD

param Permission1 string = '/subscriptions/1af779b2-7582-4d0a-afee-4596ea7d480f/providers/Microsoft.Authorization/roleDefinitions/ba92f5b4-2d11-453d-a403-e96b0029c9fe' //Storage Blob Data Contributor
param Permission2 string = '/subscriptions/1af779b2-7582-4d0a-afee-4596ea7d480f/providers/Microsoft.Authorization/roleDefinitions/09976791-48a7-449e-bb21-39d1a415f350' //Communication Services User
param Permission3 string = '/subscriptions/1af779b2-7582-4d0a-afee-4596ea7d480f/providers/Microsoft.Authorization/roleDefinitions/4633458b-17de-408a-b874-0445c86b69e6' //Key Vault Secrets User

//You must use the role definition here. It can be retrieved with: az role definition list --name "roleName" --query "[].{name:name, id:id}"
param resource1 string // Resource group name passed from main.bicep
param resource2 string // Communication Services name passed from main.bicep
param resource3 string // Key Vault name passed from main.bicep

//Logical Maps needed for each principal. Within each principal's map you can set up permissions with multiple rbac objects for each Role and Target Resource required.
param RBACUser1Map object = {
  rbac1: {
    roleDefinitionID: Permission1
    principalId: Principal1
    resourceGroup: resource1
  }
  rbac2: {
    roleDefinitionID: Permission2
    principalId: Principal1
    resourceGroup: resource1
  }
  rbac3: {
    roleDefinitionID: Permission3
    principalId: Principal1
    resourceGroup: resource1
  }
}

/* param RBACUser2Map object = {
  rbac1: {
    roleDefinitionID: Permission2
    principalId: Principal1
    resourceGroup: resource2
  }
}

param RBACUser3Map object = {
  rbac1: {
    roleDefinitionID: Permission3
    principalId: Principal1
    resourceGroup: resource3
  }
} */

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

/* module rbac2 './rbacAssignment.bicep' = [for rbac in items(RBACUser2Map): {
  name: guid(subscription().id, rbac.value.principalId, rbac.value.roleDefinitionID)
  scope: resourceGroup(rbac.value.resourceGroup)
  params:{
    roleDefinitionID: rbac.value.roleDefinitionID
    principalId: rbac.value.principalId
  }
}]


module rbac3 './rbacAssignment.bicep' = [for rbac in items(RBACUser3Map): {
  name: guid(subscription().id, rbac.value.principalId, rbac.value.roleDefinitionID)
  scope: resourceGroup(rbac.value.resourceGroup)
  params:{
    roleDefinitionID: rbac.value.roleDefinitionID
    principalId: rbac.value.principalId
  }
}] */
