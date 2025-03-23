param location string = resourceGroup().location
param clusterName string = 'aks-cluster'

resource aks 'Microsoft.ContainerService/managedClusters@2023-07-01' = {
  name: clusterName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    dnsPrefix: clusterName
    agentPoolProfiles: [
      {
        name: 'agentpool'
        count: 1
        vmSize: 'Standard_DS2_v2'
        mode: 'System'
      }
    ]
  }
}
