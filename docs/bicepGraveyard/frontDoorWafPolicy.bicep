param frontdoorwebapplicationfirewallpolicies_zus1rcrcwebsitedevv1wafp_name string = 'zus1rcrcwebsitedevv1wafp'

resource frontdoorwebapplicationfirewallpolicies_zus1rcrcwebsitedevv1wafp_name_resource 'Microsoft.Network/frontdoorwebapplicationfirewallpolicies@2025-03-01' = {
  name: frontdoorwebapplicationfirewallpolicies_zus1rcrcwebsitedevv1wafp_name
  location: 'Global'
  sku: {
    name: 'Standard_AzureFrontDoor'
  }
  properties: {
    policySettings: {
      enabledState: 'Enabled'
      mode: 'Detection'
      requestBodyCheck: 'Enabled'
    }
    customRules: {
      rules: []
    }
    managedRules: {
      managedRuleSets: []
    }
  }
}
