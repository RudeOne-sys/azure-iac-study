// modules/networking/spokeVnet.bicep
// Spoke VNet with workload subnet and peering to hub

@description('Spoke VNet name')
param spokeVnetName string

@description('Azure region')
param location string = resourceGroup().location

@description('Environment name')
@allowed(['dev', 'prod'])
param environment string

@description('Spoke VNet address space')
param spokeAddressPrefix string

@description('Workload subnet prefix')
param workloadSubnetPrefix string

@description('Hub VNet resource ID for peering')
param hubVnetId string

@description('Hub VNet name for peering resource name')
param hubVnetName string

var commonTags = {
  environment: environment
  project: 'iac-study'
  managedBy: 'bicep'
  topology: 'hub-spoke'
}

resource spokeVnet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: spokeVnetName
  location: location
  tags: commonTags
  properties: {
    addressSpace: {
      addressPrefixes: [
        spokeAddressPrefix
      ]
    }
    subnets: [
      {
        name: 'snet-workload'
        properties: {
          addressPrefix: workloadSubnetPrefix
        }
      }
    ]
  }
}

// Spoke to Hub peering
resource spokeToHubPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-05-01' = {
  parent: spokeVnet
  name: 'peer-${spokeVnetName}-to-${hubVnetName}'
  properties: {
    remoteVirtualNetwork: {
      id: hubVnetId
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true    // allows traffic forwarded by hub firewall
    useRemoteGateways: false       // set to true when VPN Gateway exists in hub
  }
}

output spokeVnetId string = spokeVnet.id
output spokeVnetName string = spokeVnet.name
output workloadSubnetId string = spokeVnet.properties.subnets[0].id
output peeringName string = spokeToHubPeering.name
