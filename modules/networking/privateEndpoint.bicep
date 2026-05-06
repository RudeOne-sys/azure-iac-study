// modules/networking/privateEndpoint.bicep
// Private Endpoint with automatic DNS registration

@description('Private Endpoint name')
param privateEndpointName string

@description('Azure region')
param location string = resourceGroup().location

@description('Environment name')
@allowed(['dev', 'prod'])
param environment string

@description('Resource ID of the service to connect to')
param serviceResourceId string

@description('Group ID - the sub-resource type (blob, file, vault, etc)')
param groupId string

@description('Subnet ID to place the private endpoint in')
param subnetId string

@description('Private DNS Zone ID for DNS registration')
param privateDnsZoneId string

var commonTags = {
  environment: environment
  project: 'iac-study'
  managedBy: 'bicep'
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-05-01' = {
  name: privateEndpointName
  location: location
  tags: commonTags
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: privateEndpointName
        properties: {
          privateLinkServiceId: serviceResourceId
          groupIds: [
            groupId
          ]
        }
      }
    ]
  }
}

// DNS Zone Group - automatically creates DNS record in Private DNS Zone
resource dnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-05-01' = {
  parent: privateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config'
        properties: {
          privateDnsZoneId: privateDnsZoneId
        }
      }
    ]
  }
}

output privateEndpointId string = privateEndpoint.id
output privateEndpointName string = privateEndpoint.name
output privateIpAddress string = privateEndpoint.properties.customNetworkInterfaceName
