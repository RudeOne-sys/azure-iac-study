// modules/networking/hubPeering.bicep
// Hub side of the peering - must be created separately from spoke side

@description('Hub VNet name')
param hubVnetName string

@description('Spoke VNet name for peering name')
param spokeVnetName string

@description('Spoke VNet resource ID')
param spokeVnetId string

// Reference existing hub VNet
resource hubVnet 'Microsoft.Network/virtualNetworks@2023-05-01' existing = {
  name: hubVnetName
}

// Hub to Spoke peering
resource hubToSpokePeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-05-01' = {
  parent: hubVnet
  name: 'peer-${hubVnetName}-to-${spokeVnetName}'
  properties: {
    remoteVirtualNetwork: {
      id: spokeVnetId
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: true     // hub shares its VPN Gateway with spokes
  }
}

output peeringName string = hubToSpokePeering.name
