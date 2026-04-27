// modules/networking/hubVnet.bicep
// Hub VNet with shared services subnet and gateway subnet

@description('Hub VNet name')
param hubVnetName string

@description('Azure region')
param location string = resourceGroup().location

@description('Environment name')
@allowed(['dev', 'prod'])
param environment string

@description('Hub VNet address space')
param hubAddressPrefix string = '10.0.0.0/16'

@description('Gateway subnet prefix - must be named GatewaySubnet for VPN Gateway')
param gatewaySubnetPrefix string = '10.0.0.0/27'

@description('Azure Firewall subnet prefix - must be named AzureFirewallSubnet')
param firewallSubnetPrefix string = '10.0.1.0/26'

@description('Azure Bastion subnet prefix - must be named AzureBastionSubnet')
param bastionSubnetPrefix string = '10.0.2.0/26'

@description('Shared services subnet prefix')
param sharedServicesSubnetPrefix string = '10.0.3.0/24'

var commonTags = {
  environment: environment
  project: 'iac-study'
  managedBy: 'bicep'
  topology: 'hub-spoke'
}

resource hubVnet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: hubVnetName
  location: location
  tags: commonTags
  properties: {
    addressSpace: {
      addressPrefixes: [
        hubAddressPrefix
      ]
    }
    subnets: [
      {
        // Must be named exactly 'GatewaySubnet' for VPN Gateway
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: gatewaySubnetPrefix
        }
      }
      {
        // Must be named exactly 'AzureFirewallSubnet' for Azure Firewall
        name: 'AzureFirewallSubnet'
        properties: {
          addressPrefix: firewallSubnetPrefix
        }
      }
      {
        // Must be named exactly 'AzureBastionSubnet' for Azure Bastion
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: bastionSubnetPrefix
        }
      }
      {
        name: 'snet-shared-services'
        properties: {
          addressPrefix: sharedServicesSubnetPrefix
        }
      }
    ]
  }
}

output hubVnetId string = hubVnet.id
output hubVnetName string = hubVnet.name
output gatewaySubnetId string = hubVnet.properties.subnets[0].id
output firewallSubnetId string = hubVnet.properties.subnets[1].id
output bastionSubnetId string = hubVnet.properties.subnets[2].id
output sharedServicesSubnetId string = hubVnet.properties.subnets[3].id
