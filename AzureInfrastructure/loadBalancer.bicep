param location string = resourceGroup().location
param lbName string = 'app-lb'

resource loadBalancer 'Microsoft.Network/loadBalancers@2023-05-01' = {
  name: lbName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    frontendIPConfigurations: [
      {
        name: 'frontend-ip'
        properties: {
          publicIPAddress: {
            id: publicIP.id
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'backend-pool'
      }
    ]
  }
}

resource publicIP 'Microsoft.Network/publicIPAddresses@2023-05-01' = {
  name: '${lbName}-ip'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}
