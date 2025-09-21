// Azure Front Door (Standard/Premium) - single endpoint for rebelcorpo.com
// Routes traffic to Container App (default), Function App (/api/*), Storage Static Website (/static/*)

// ---------------------------
// Parameters
// ---------------------------
@description('Azure Front Door profile name')
param afdProfileName string = 'rebelcorpo-afd'

@description('Azure Front Door endpoint name')
param afdEndpointName string = 'rebelcorpo-endpoint'

@description('Custom domain to serve (must be a root or subdomain you control)')
param customDomainName string = 'rebelcorpo.com'

@description('Container App public hostname (FQDN) to use as the default origin, e.g., myapp.<hash>.<region>.azurecontainerapps.io')
param containerAppHostname string

@description('Function App default hostname, e.g., myfunc.azurewebsites.net')
param functionAppHostname string

@description('Storage Static Website hostname (no scheme), e.g., mystorage.z13.web.core.windows.net. If you are not using Static Website, you can point to a CDN-enabled blob endpoint instead.')
param storageStaticWebsiteHostname string

@description('Optional: Health probe path for origins')
param healthProbePath string = '/'

@description('Optional: Enable HTTP to HTTPS redirect at route level')
param enableHttpsOnly bool = true

@description('AFD SKU: Standard_AzureFrontDoor or Premium_AzureFrontDoor')
param afdSkuName string = 'Standard_AzureFrontDoor'

@description('Enable Azure WAF on Front Door (creates policy and associates to custom domain)')
param enableWaf bool = true

@description('Name of the WAF policy (Front Door WAF)')
param wafPolicyName string = 'rebelcorpo-afd-waf'

@description('Rate limit threshold per client IP per minute (set 0 to disable the custom rule)')
param rateLimitThreshold int = 300

// ---------------------------
// Resources
// ---------------------------

// AFD profile (global)
resource afdProfile 'Microsoft.Cdn/profiles@2024-02-01' = {
  name: afdProfileName
  location: 'global'
  sku: {
    name: afdSkuName
  }
  tags: {
    app: 'rebelcorpo'
    component: 'frontdoor'
  }
}

// AFD endpoint (public entry point)
// Note: Child resource naming uses "parentName/childName"
resource afdEndpoint 'Microsoft.Cdn/profiles/afdEndpoints@2024-02-01' = {
  parent: afdProfile
  name: afdEndpointName
  location: 'global'
  properties: {
    enabledState: 'Enabled'
  }
}

// Origin Groups (one per backend for independent health/probes)
resource ogContainer 'Microsoft.Cdn/profiles/originGroups@2024-02-01' = {
  parent: afdProfile
  name: 'og-container'
  properties: {
    sessionAffinityState: 'Disabled'
    healthProbeSettings: {
      probeIntervalInSeconds: 120
      probePath: healthProbePath
      probeProtocol: 'Https'
      probeRequestType: 'GET'
    }
    loadBalancingSettings: {
      sampleSize: 4
      successfulSamplesRequired: 3
      additionalLatencyInMilliseconds: 0
    }
  }
}

resource ogFunction 'Microsoft.Cdn/profiles/originGroups@2024-02-01' = {
  name: 'og-function'
  parent: afdProfile
  properties: {
    sessionAffinityState: 'Disabled'
    healthProbeSettings: {
      probeIntervalInSeconds: 120
      probePath: healthProbePath
      probeProtocol: 'Https'
      probeRequestType: 'GET'
    }
    loadBalancingSettings: {
      sampleSize: 4
      successfulSamplesRequired: 3
      additionalLatencyInMilliseconds: 0
    }
  }
}

resource ogStorage 'Microsoft.Cdn/profiles/originGroups@2024-02-01' = {
  parent: afdProfile
  name: 'og-storage'
  properties: {
    sessionAffinityState: 'Disabled'
    healthProbeSettings: {
      probeIntervalInSeconds: 120
      probePath: '/index.html'
      probeProtocol: 'Https'
      probeRequestType: 'GET'
    }
    loadBalancingSettings: {
      sampleSize: 4
      successfulSamplesRequired: 3
      additionalLatencyInMilliseconds: 0
    }
  }
}

// Origins (hostnames of your backends)
// Note: These are public origins. If you need private origins, use AFD Premium with Private Link origins.
resource originContainer 'Microsoft.Cdn/profiles/originGroups/origins@2024-02-01' = {
  name: '${afdProfile.name}/${ogContainer.name}/origin-container'
  properties: {
    hostName: containerAppHostname
    httpPort: 80
    httpsPort: 443
    originHostHeader: containerAppHostname // ensure correct Host header is sent
    priority: 1
    weight: 1000
    enabledState: 'Enabled'
  }
}

resource originFunction 'Microsoft.Cdn/profiles/originGroups/origins@2024-02-01' = {
  name: '${afdProfile.name}/${ogFunction.name}/origin-function'
  properties: {
    hostName: functionAppHostname
    httpPort: 80
    httpsPort: 443
    originHostHeader: functionAppHostname
    priority: 1
    weight: 1000
    enabledState: 'Enabled'
  }
}

resource originStorage 'Microsoft.Cdn/profiles/originGroups/origins@2024-02-01' = {
  name: '${afdProfile.name}/${ogStorage.name}/origin-storage'
  properties: {
    hostName: storageStaticWebsiteHostname
    httpPort: 80
    httpsPort: 443
    originHostHeader: storageStaticWebsiteHostname
    priority: 1
    weight: 1000
    enabledState: 'Enabled'
  }
}

// Custom domain for rebelcorpo.com (bind to the endpoint)
// IMPORTANT: You must add required DNS TXT/CNAME records in your DNS zone to validate and map the domain.
resource afdCustomDomain 'Microsoft.Cdn/profiles/customDomains@2024-02-01' = {
  name: '${replace(customDomainName, '.', '-')}-domain'
  parent: afdProfile
  properties: {
    hostName: customDomainName
    // Optional: Managed cert can be enabled after DNS validation completes (avoids deployment failures).
    // tlsSettings: {
    //   certificateType: 'ManagedCertificate'
    //   minimumTlsVersion: 'TLS12'
    // }
  }
}

// Front Door WAF policy (not enabled by default; this turns it on)
// Uses Microsoft Default Rule Set (OWASP) and an optional rate-limiting custom rule.
// Note: Bot Manager rules require AFD Premium (not included here).
resource wafPolicy 'Microsoft.Network/frontdoorWebApplicationFirewallPolicies@2022-05-01' = if (enableWaf) {
  name: wafPolicyName
  location: 'Global'
  properties: {
    policySettings: {
      enabledState: 'Enabled' // Toggle entire WAF on/off
      mode: 'Prevention' // 'Detection' to log only; 'Prevention' to block
      requestBodyCheck: 'Enabled'
    }
    managedRules: {
      managedRuleSets: [
        {
          ruleSetType: 'Microsoft_DefaultRuleSet'
          ruleSetVersion: '2.1'
        }
      ]
    }
    // Optional rate-limiting custom rule (blocks abusive IPs)
    customRules: (rateLimitThreshold > 0)
      ? {
          rules: [
            {
              name: 'RateLimitByIP'
              enabledState: 'Enabled'
              priority: 1
              ruleType: 'RateLimitRule'
              rateLimitDurationInMinutes: 1
              rateLimitThreshold: rateLimitThreshold
              matchConditions: [
                {
                  matchVariable: 'RemoteAddr'
                  operator: 'IPMatch'
                  negateCondition: false
                  matchValue: [
                    '0.0.0.0/0'
                    '::/0'
                  ]
                }
              ]
              action: 'Block'
            }
          ]
        }
      : {}
  }
}

// Associate WAF policy with your AFD custom domain (so traffic to rebelcorpo.com is protected)
resource afdSecurityPolicy 'Microsoft.Cdn/profiles/securityPolicies@2024-02-01' = if (enableWaf) {
  parent: afdProfile
  name: 'waf-security-policy'
  properties: {
    parameters: {
      type: 'WebApplicationFirewall'
      wafPolicy: {
        id: wafPolicy.id
      }
      associations: [
        {
          domains: [
            {
              id: afdCustomDomain.id
            }
          ]
          // Optional: restrict to certain paths only (defaults to all)
          // patternsToMatch: [ '/*' ]
        }
      ]
    }
  }
}

// ---------------------------
// Routes (path-based), mapped to the endpoint + custom domain
// ---------------------------

// Default route to Container App: /*
// tip: Add additional domain bindings to routes via the `domains` property.
resource routeDefault 'Microsoft.Cdn/profiles/routes@2024-02-01' = {
  parent: afdProfile
  name: 'route-default'
  properties: {
    // For routes, endpointName expects the short endpoint name, not "profile/endpoint"
    endpointName: afdEndpointName
    originGroup: { id: ogContainer.id }
    supportedProtocols: ['Https']
    httpsRedirect: enableHttpsOnly ? 'Enabled' : 'Disabled'
    linkToDefaultDomain: 'Disabled'
    patternsToMatch: ['/*']
    forwardingProtocol: 'MatchRequest'
    domains: [{ id: afdCustomDomain.id }]
  }
}

resource routeApi 'Microsoft.Cdn/profiles/routes@2024-02-01' = {
  parent: afdProfile
  name: 'route-api'
  properties: {
    endpointName: afdEndpointName
    originGroup: { id: ogFunction.id }
    supportedProtocols: ['Https']
    httpsRedirect: enableHttpsOnly ? 'Enabled' : 'Disabled'
    linkToDefaultDomain: 'Disabled'
    patternsToMatch: ['/api/*']
    forwardingProtocol: 'MatchRequest'
    domains: [{ id: afdCustomDomain.id }]
  }
}

resource routeStatic 'Microsoft.Cdn/profiles/routes@2024-02-01' = {
  parent: afdProfile
  name: 'route-static'
  properties: {
    endpointName: afdEndpointName
    originGroup: { id: ogStorage.id }
    supportedProtocols: ['Https']
    httpsRedirect: enableHttpsOnly ? 'Enabled' : 'Disabled'
    linkToDefaultDomain: 'Disabled'
    patternsToMatch: ['/static/*']
    forwardingProtocol: 'MatchRequest'
    domains: [{ id: afdCustomDomain.id }]
  }
}

// ---------------------------
// Outputs
// ---------------------------
output afdProfileId string = afdProfile.id
output afdEndpointHost string = '${afdEndpointName}.azurefd.net'
output afdCustomDomainId string = afdCustomDomain.id
