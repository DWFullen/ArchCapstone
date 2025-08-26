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


// For refrence, needs to be modified
targetScope = 'subscription'
// RBAC Assignment Main Bicep template used for applying permissions to resources for principals. Usage described below. Administration commands included with templates.

//Set parameters for Principals(Users), Permissions, and Target Resources here.

//You must use the Object ID here.
param Principal1 string = '<principle1>' //FSSA Azure CAE Contributor-Prod
param Principal2 string = '<principle2>' //FSSA Azure CAE Resource Policy Contributor-Prod
param Principal3 string = '<principle3>' //FSSA Azure CAE User Access Administrator-Prod

param Permission1 string = '<permission1>' //Contributor
param Permission2 string = '<permission2>' //Resource Policy Contributor
param Permission3 string = '<permission3>' //User Access Administrator

//You must use the role definition here. It can be retrieved with: az role definition list --name "roleName" --query "[].{name:name, id:id}"
param resource1 string = '<resource1>'
param resource2 string = '<resource2>'
param resource3 string = '<resource3>'

//Logical Maps needed for each principal. Within each principal's map you can set up permissions with multiple rbac objects for each Role and Target Resource required.
param RBACUser1Map object = {
  rbac1:{
  roleDefinitionID: Permission1
  principalId: Principal1
  resourceGroup: resource1
  }
  rbac2:{
    roleDefinitionID: Permission2
    principalId: Principal1
    resourceGroup: resource1
    }
}

param RBACUser2Map object = {
  rbac1:{
  roleDefinitionID: Permission1
  principalId: Principal2
  resourceGroup: resource1
  }
  rbac2:{
    roleDefinitionID: Permission1
    principalId: Principal2
    resourceGroup: resource2
    }
}

param RBACUser3Map object = {
  rbac1:{
  roleDefinitionID: Permission1
  principalId: Principal3
  resourceGroup: resource1
  }
}

//****************************************************RESOURCES**********************************************************************
//A seperate module is required for each principal. Change the RBACUserXMap in the for loops of each module to change what principal's RBACMap is being pulled from.
module rbac1 './RBACAssignment.bicep' = [for rbac in items(RBACUser1Map): {
  name: guid(subscription().id, rbac.value.principalId, rbac.value.roleDefinitionID)
  scope: resourceGroup(rbac.value.resourceGroup)
  params:{
    roleDefinitionID: rbac.value.roleDefinitionID
    principalId: rbac.value.principalId
  }
}]

module rbac2 './RBACAssignment.bicep' = [for rbac in items(RBACUser2Map): {
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
