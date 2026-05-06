// modules/networking/localNetworkGateway.bicep
// Represents the on-premises VPN device in Azure

@description('Local Network Gateway name')
param lngName string

@description('Azure region')
param location string = resourceGroup().location

@description('Environment name')
@allowed(['dev', 'prod'])
param environment string

@description('On-premises VPN device public IP')
param onPremPublicIp string

@description('On-premises address spaces')
param onPremAddressPrefixes array = [
  '192.168.0.0/24'   // example on-prem network
  '172.16.0.0/16'    // example on-prem network
]

@description('Enable BGP for this connection')
param enableBgp bool = true

@description('On-premises BGP ASN')
param onPremBgpAsn int = 65001

@description('On-premises BGP peering address')
param onPremBgpPeeringAddress string = '192.168.0.1'

var commonTags = {
  environment: environment
  project: 'iac-study'
  managedBy: 'bicep'
}

resource localNetworkGateway 'Microsoft.Network/localNetworkGateways@2023-05-01' = {
  name: lngName
  location: location
  tags: commonTags
  properties: {
    gatewayIpAddress: onPremPublicIp
    localNetworkAddressSpace: {
      addressPrefixes: onPremAddressPrefixes
    }
    bgpSettings: enableBgp ? {
      asn: onPremBgpAsn
      bgpPeeringAddress: onPremBgpPeeringAddress
    } : null
  }
}

output lngId string = localNetworkGateway.id
output lngName string = localNetworkGateway.name
