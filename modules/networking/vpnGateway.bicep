// modules/networking/vpnGateway.bicep
// VPN Gateway for Site-to-Site hybrid connectivity

@description('VPN Gateway name')
param vpnGatewayName string

@description('Azure region')
param location string = resourceGroup().location

@description('Environment name')
@allowed(['dev', 'prod'])
param environment string

@description('Gateway subnet ID - must be GatewaySubnet')
param gatewaySubnetId string

@description('VPN Gateway SKU')
@allowed([
  'VpnGw1'
  'VpnGw2'
  'VpnGw3'
])
param gatewaySku string = environment == 'prod' ? 'VpnGw2' : 'VpnGw1'

@description('Enable BGP')
param enableBgp bool = true

@description('BGP ASN - must be different from on-premises ASN')
param bgpAsn int = 65515

var publicIpName = 'pip-${vpnGatewayName}'
var commonTags = {
  environment: environment
  project: 'iac-study'
  managedBy: 'bicep'
}

// Public IP for VPN Gateway
resource vpnPublicIp 'Microsoft.Network/publicIPAddresses@2023-05-01' = {
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

// VPN Gateway
resource vpnGateway 'Microsoft.Network/virtualNetworkGateways@2023-05-01' = {
  name: vpnGatewayName
  location: location
  tags: commonTags
  properties: {
    gatewayType: 'Vpn'
    vpnType: 'RouteBased'        // modern standard - supports IKEv2
    sku: {
      name: gatewaySku
      tier: gatewaySku
    }
    enableBgp: enableBgp
    bgpSettings: {
      asn: bgpAsn
    }
    ipConfigurations: [
      {
        name: 'vnetGatewayConfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: gatewaySubnetId
          }
          publicIPAddress: {
            id: vpnPublicIp.id
          }
        }
      }
    ]
  }
}

output vpnGatewayId string = vpnGateway.id
output vpnGatewayName string = vpnGateway.name
output vpnGatewayPublicIp string = vpnPublicIp.properties.ipAddress
output bgpPeeringAddress string = vpnGateway.properties.bgpSettings.bgpPeeringAddress
