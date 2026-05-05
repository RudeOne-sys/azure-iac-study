// modules/networking/applicationGateway.bicep
// Application Gateway with WAF for web tier

@description('Application Gateway name')
param appGwName string

@description('Azure region')
param location string = resourceGroup().location

@description('Environment name')
@allowed(['dev', 'prod'])
param environment string

@description('Subnet ID for Application Gateway')
param subnetId string

@description('WAF mode - Detection in dev, Prevention in prod')
param wafMode string = environment == 'prod' ? 'Prevention' : 'Detection'

@description('App Gateway SKU - dev uses smaller size')
param skuSize string = environment == 'prod' ? 'WAF_v2' : 'WAF_v2'

@description('Capacity - dev uses 1, prod uses 2 for redundancy')
param capacity int = environment == 'prod' ? 2 : 1

var publicIpName = 'pip-${appGwName}'
var commonTags = {
  environment: environment
  project: 'iac-study'
  managedBy: 'bicep'
}

// Public IP for Application Gateway
resource publicIp 'Microsoft.Network/publicIPAddresses@2023-05-01' = {
  name: publicIpName
  location: location
  tags: commonTags
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

// WAF Policy
resource wafPolicy 'Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies@2023-05-01' = {
  name: '${appGwName}-waf-policy'
  location: location
  tags: commonTags
  properties: {
    policySettings: {
      state: 'Enabled'
      mode: wafMode
      requestBodyCheck: true
      maxRequestBodySizeInKb: 128
    }
    managedRules: {
      managedRuleSets: [
        {
          ruleSetType: 'OWASP'
          ruleSetVersion: '3.2'
        }
      ]
    }
  }
}

// Application Gateway
resource applicationGateway 'Microsoft.Network/applicationGateways@2023-05-01' = {
  name: appGwName
  location: location
  tags: commonTags
  properties: {
    sku: {
      name: skuSize
      tier: 'WAF_v2'
      capacity: capacity
    }
    firewallPolicy: {
      id: wafPolicy.id
    }
    gatewayIPConfigurations: [
      {
        name: 'appgw-ip-config'
        properties: {
          subnet: {
            id: subnetId
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'appgw-frontend-public'
        properties: {
          publicIPAddress: {
            id: publicIp.id
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'port-80'
        properties: {
          port: 80
        }
      }
      {
        name: 'port-443'
        properties: {
          port: 443
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'web-backend-pool'
        properties: {}
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'web-http-settings'
        properties: {
          port: 80
          protocol: 'Http'
          cookieBasedAffinity: 'Disabled'
          requestTimeout: 30
          probe: {
            id: resourceId('Microsoft.Network/applicationGateways/probes', appGwName, 'web-health-probe')
          }
        }
      }
    ]
    probes: [
      {
        name: 'web-health-probe'
        properties: {
          protocol: 'Http'
          host: '127.0.0.1'
          path: '/health'
          interval: 30
          timeout: 30
          unhealthyThreshold: 3
          pickHostNameFromBackendHttpSettings: false
          minServers: 0
        }
      }
    ]
    httpListeners: [
      {
        name: 'web-listener-http'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', appGwName, 'appgw-frontend-public')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', appGwName, 'port-80')
          }
          protocol: 'Http'
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'web-routing-rule'
        properties: {
          ruleType: 'Basic'
          priority: 100
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', appGwName, 'web-listener-http')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', appGwName, 'web-backend-pool')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', appGwName, 'web-http-settings')
          }
        }
      }
    ]
  }
}

output appGwId string = applicationGateway.id
output appGwName string = applicationGateway.name
output publicIpAddress string = publicIp.properties.ipAddress
output backendPoolId string = applicationGateway.properties.backendAddressPools[0].id
