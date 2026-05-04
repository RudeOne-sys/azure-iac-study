// modules/networking/publicIp.bicep
// Standard SKU public IP for Azure Firewall

@description('Public IP name')
param publicIpName string

@description('Azure region')
param location string = resourceGroup().location

@description('Environment name')
@allowed(['dev', 'prod'])
param environment string

@description('Purpose of this public IP')
param purpose string

var commonTags = {
  environment: environment
  project: 'iac-study'
  managedBy: 'bicep'
  purpose: purpose
}

resource publicIp 'Microsoft.Network/publicIPAddresses@2023-05-01' = {
  name: publicIpName
  location: location
  tags: commonTags
  sku: {
    name: 'Standard'   // Azure Firewall requires Standard SKU
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'  // Must be Static for Standard SKU
    publicIPAddressVersion: 'IPv4'
  }
}

output publicIpId string = publicIp.id
output publicIpAddress string = publicIp.properties.ipAddress
output publicIpName string = publicIp.name
