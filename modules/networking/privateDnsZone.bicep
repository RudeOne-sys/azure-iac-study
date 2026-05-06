// modules/networking/privateDnsZone.bicep
// Private DNS Zone with VNet link for private endpoint DNS resolution

@description('Private DNS Zone name - must match the service privatelink zone')
param zoneName string

@description('VNet ID to link this zone to')
param vnetId string

@description('VNet name for the link resource name')
param vnetName string

@description('Environment name')
@allowed(['dev', 'prod'])
param environment string

var commonTags = {
  environment: environment
  project: 'iac-study'
  managedBy: 'bicep'
}

// Private DNS Zone - note: location is always 'global' for DNS zones
resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: zoneName
  location: 'global'
  tags: commonTags
}

// VNet Link - connects the DNS zone to the VNet
resource vnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDnsZone
  name: 'link-${vnetName}'
  location: 'global'
  tags: commonTags
  properties: {
    virtualNetwork: {
      id: vnetId
    }
    registrationEnabled: false  // auto-registration is for VMs, not PaaS services
  }
}

output zoneId string = privateDnsZone.id
output zoneName string = privateDnsZone.name
