// deployments/privateEndpoints.bicep
// Deploys Private Endpoints for Storage and Key Vault with DNS

@description('Environment name')
@allowed(['dev', 'prod'])
param environment string

@description('Azure region')
param location string = resourceGroup().location

@description('Storage Account resource ID')
param storageAccountResourceId string

@description('Spoke VNet name for endpoint placement')
param spokeVnetName string

@description('Hub VNet ID for DNS zone linking')
param hubVnetId string

@description('Hub VNet name')
param hubVnetName string

// Naming
var blobPeName = 'pe-blob-${environment}'
var blobDnsZoneName = 'privatelink.blob.${az.environment().suffixes.storage}'

// Reference existing spoke VNet
resource spokeVnet 'Microsoft.Network/virtualNetworks@2023-05-01' existing = {
  name: spokeVnetName
}

var workloadSubnetId = '${spokeVnet.id}/subnets/snet-workload'

// Deploy Private DNS Zone for Blob Storage
module blobDnsZone '../modules/networking/privateDnsZone.bicep' = {
  name: 'blobDnsZoneDeployment-${uniqueString(resourceGroup().id)}'
  params: {
    zoneName: blobDnsZoneName
    vnetId: hubVnetId
    vnetName: hubVnetName
    environment: environment
  }
}

// Also link DNS zone to spoke VNet
module blobDnsZoneSpokeLink '../modules/networking/privateDnsZone.bicep' = {
  name: 'blobDnsZoneSpokeDeployment-${uniqueString(resourceGroup().id)}'
  params: {
    zoneName: blobDnsZoneName
    vnetId: spokeVnet.id
    vnetName: spokeVnetName
    environment: environment
  }
  dependsOn: [blobDnsZone]
}

// Deploy Private Endpoint for Storage Blob
module blobPrivateEndpoint '../modules/networking/privateEndpoint.bicep' = {
  name: 'blobPeDeployment-${uniqueString(resourceGroup().id)}'
  params: {
    privateEndpointName: blobPeName
    location: location
    environment: environment
    serviceResourceId: storageAccountResourceId
    groupId: 'blob'
    subnetId: workloadSubnetId
    privateDnsZoneId: blobDnsZone.outputs.zoneId
  }
}

output blobPrivateEndpointId string = blobPrivateEndpoint.outputs.privateEndpointId
output blobDnsZoneId string = blobDnsZone.outputs.zoneId
