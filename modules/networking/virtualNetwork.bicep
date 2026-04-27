// modules/networking/virtualNetwork.bicep
// Basic VNet and subnet for compute workloads

@description('Name of the virtual network')
param vnetName string

@description('Azure region')
param location string = resourceGroup().location

@description('Environment name')
@allowed(['dev', 'prod'])
param environment string

@description('Address space for the VNet')
param addressPrefix string = '10.0.0.0/16'

@description('Address prefix for the compute subnet')
param subnetPrefix string = '10.0.1.0/24'

var commonTags = {
  environment: environment
  project: 'iac-study'
  managedBy: 'bicep'
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: vnetName
  location: location
  tags: commonTags
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: [
      {
        name: 'snet-compute'
        properties: {
          addressPrefix: subnetPrefix
        }
      }
    ]
  }
}

output vnetId string = virtualNetwork.id
output vnetName string = virtualNetwork.name
output subnetId string = virtualNetwork.properties.subnets[0].id
