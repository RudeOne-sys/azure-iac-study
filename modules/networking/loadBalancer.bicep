// modules/networking/loadBalancer.bicep
// Internal Azure Load Balancer for app tier

@description('Load balancer name')
param lbName string

@description('Azure region')
param location string = resourceGroup().location

@description('Environment name')
@allowed(['dev', 'prod'])
param environment string

@description('Subnet ID for internal frontend IP')
param subnetId string

@description('Backend port for app tier')
param backendPort int = 8080

var commonTags = {
  environment: environment
  project: 'iac-study'
  managedBy: 'bicep'
}

resource loadBalancer 'Microsoft.Network/loadBalancers@2023-05-01' = {
  name: lbName
  location: location
  tags: commonTags
  sku: {
    name: 'Standard'  // Standard SKU required for zone redundancy and availability zones
    tier: 'Regional'
  }
  properties: {
    frontendIPConfigurations: [
      {
        name: 'frontend-internal'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnetId
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'app-backend-pool'
      }
    ]
    probes: [
      {
        name: 'app-health-probe'
        properties: {
          protocol: 'Http'
          port: backendPort
          requestPath: '/health'
          intervalInSeconds: 15
          numberOfProbes: 2
        }
      }
    ]
    loadBalancingRules: [
      {
        name: 'app-lb-rule'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', lbName, 'frontend-internal')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', lbName, 'app-backend-pool')
          }
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', lbName, 'app-health-probe')
          }
          protocol: 'Tcp'
          frontendPort: backendPort
          backendPort: backendPort
          enableFloatingIP: false
          idleTimeoutInMinutes: 4
          loadDistribution: 'Default'  // round-robin
        }
      }
    ]
  }
}

output lbId string = loadBalancer.id
output lbName string = loadBalancer.name
output backendPoolId string = loadBalancer.properties.backendAddressPools[0].id
output frontendIp string = loadBalancer.properties.frontendIPConfigurations[0].properties.privateIPAddress
