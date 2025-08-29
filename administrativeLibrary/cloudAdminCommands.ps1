#------------------------------------AZURE CLI Environment Setup-----------------------------------------------

# Connect to Azure Commercial
Get-AzEnvironment | Format-Table
Set-AzEnvironment -Name CloudName
Connect-AzAccount # confirm that you are logged in by rerunning this command if following commands do not seem to be working
Get-AzLocation | Format-Table # Command used to get region information for use with "location" parameter for resources

#------------------------------------AZURE ACCOUNT COMMANDS-----------------------------------------------

# Queries available accounts and outputs name and subscription ID only
Get-AzSubscription | Select-Object Name, Id | Format-Table

# Queries specific account and outputs name and subscription ID only in a json format
Get-AzSubscription | Where-Object {$_.Name -eq 'Agency Production - Azure Commercial'} | Select-Object Name, Id | ConvertTo-Json

# set Azure Subscription
Set-AzContext -SubscriptionId "SUBSCRIPTION_ID"

# Verify you're in correct Azure Subscription
Get-AzContext

# Lists Resource Groups in the current subscription
Get-AzResourceGroup

#------------------------------------AZURE RG COMMANDS-----------------------------------------------

# Queries for the ID of specific ResourceGroup
(Get-AzResourceGroup -Name "rgName").ResourceId

# Lists role assignments for a specific resource group
Get-AzRoleAssignment -ResourceGroupName {resourceGroup}

Remove-AzResourceGroup -Name MyResourceGroup

# PowerShell
Get-AzResourceGroupDeployment -ResourceGroupName "zus1-agency-application-v010-sbx-budget-rg"

Get-AzActivityLog -ResourceGroupName "zus1-agency-application-v010-sbx-budget-rg"

Get-AzRoleDefinition | Where-Object {$_.Name -like "*SQL*"}

#------------------------------------AZURE STORAGE ACCOUNT COMMANDS-----------------------------------------------

# Queries specific storage account and outputs ID only
(Get-AzStorageAccount -Name saName -ResourceGroupName rgName).Id

# Queries specific file share for specific storage account and outputs its information
$ctx = (Get-AzStorageAccount -Name saName -ResourceGroupName rgName).Context
Get-AzStorageShare -Name sharename -Context $ctx

# Queries user list for specific storage account and outputs its information
Get-AzStorageLocalUser -ResourceGroupName rgName -StorageAccountName saName

# WORM Policy
$policy = Set-AzRmStorageContainerImmutabilityPolicy -ResourceGroupName 'zus1-agency-nisttest-sbx-v1-rg' -StorageAccountName 'zus1agencynisttestsbxv1sa' -ContainerName 'zus1agencynisttestsbxv1cr' -ImmutabilityPeriod 2555

# Lock immutability policy
Lock-AzRmStorageContainerImmutabilityPolicy -ResourceGroupName 'zus1-agency-nisttest-sbx-v1-rg' -StorageAccountName 'zus1agencynisttestsbxv1sa' -ContainerName 'zus1agencynisttestsbxv1cr' -Etag $policy.Etag

# Verify Policy
Get-AzRmStorageContainerImmutabilityPolicy -ResourceGroupName "zus1-agency-nisttest-sbx-v1-rg" -StorageAccountName "zus1agencynisttestsbxv1sa" -ContainerName "zus1agencynisttestsbxv1cr"

#------------------------------------AZURE ACTIVE DIRECTORY COMMANDS----------------------------------------------

# Queries specific App Registration and outputs its information
Get-AzADApplication -DisplayName "<App Registration Name>" | Format-Table

# Queries specific user and outputs its object ID
(Get-AzADUser -UserPrincipalName "user@website.com").Id

# Queries specific user group and outputs its object ID
(Get-AzADGroup -DisplayName "UserGroup").Id

# Queries master role definition dictionary for specific role and outputs its name and definition
Get-AzRoleDefinition -Name "Reader" | Select-Object Name, Id

# Queries master role definition dictionary for specific role and outputs its information
Get-AzRoleDefinition -Name "RoleName"

# Assigns role to Entra Object
New-AzRoleAssignment -ObjectId "AssigneeObject/Application/UserID" `
-RoleDefinitionName "RoleDefinition" `
-Scope "ScopeDefinition"

# Outputs role assignments for specific Entra object
Get-AzRoleAssignment -ObjectId AssigneeObject/Application/UserID

# Get groups starting with Agency
Get-AzADGroup | Where-Object {$_.DisplayName -like "Agency*"} | Select-Object DisplayName, Id | Format-Table

# Get groups containing Agency (requires Microsoft.Graph module)
Get-MgGroup -Filter "contains(displayName,'Agency')" | Select-Object DisplayName, Id | Format-Table

#------------------------------------AZURE CONTAINER REGISTRY REPOSITORY COMMANDS----------------------------------------------

# Use the following commands to create a token to use for granting permissions to users
# Note: ACR token management requires Azure CLI or REST API calls - no direct PowerShell cmdlets available
# You'll need to use Invoke-RestMethod or continue using Azure CLI for these operations

#---------------------------------------------------AZURE APP SERVICE COMMANDS---------------------------------------------------

# Add CORS origin to web app
$webApp = Get-AzWebApp -ResourceGroupName DWDAPI -Name dwdapi
$webApp.SiteConfig.Cors.AllowedOrigins.Add('https://examplewebsite.com')
Set-AzWebApp -ResourceGroupName DWDAPI -Name dwdapi -SiteConfig $webApp.SiteConfig

#----------------------------------------------------------TICKET--------------------------------------------------------------------------------
#---------------------------------------------------------0000000--------------------------------------------------------------------------------

# Space used for temporary code for ticket work
