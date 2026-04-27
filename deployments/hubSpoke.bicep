// deployments/hubSpoke.bicep
// Orchestrates hub and spoke network topology

targetScope = 'resourceGroup'

@description('Environment name')
@allowed(['dev', 'prod'])
param environment string

@description('Azure region')
param location string = resourceGroup().location

// Naming
var hubVnetName = 'vnet-hub-${environment}'
var devSpokeVnetName = 'vnet-spoke-dev-${environment}'
var prodSpokeVnetName = 'vnet-spoke-prod-${environment}'

// Deploy Hub VNet
module hubVnet '../modules/networking/hubVnet.bicep' = {
  name: 'hubVnetDeployment-${uniqueString(resourceGroup().id)}'
  params: {
    hubVnetName: hubVnetName
    location: location
    environment: environment
    hubAddressPrefix: '10.0.0.0/16'
    gatewaySubnetPrefix: '10.0.0.0/27'
    firewallSubnetPrefix: '10.0.1.0/26'
    bastionSubnetPrefix: '10.0.2.0/26'
    sharedServicesSubnetPrefix: '10.0.3.0/24'
  }
}

// Deploy Dev Spoke VNet
module devSpoke '../modules/networking/spokeVnet.bicep' = {
  name: 'devSpokeDeployment-${uniqueString(resourceGroup().id)}'
  params: {
    spokeVnetName: devSpokeVnetName
    location: location
    environment: environment
    spokeAddressPrefix: '10.1.0.0/16'
    workloadSubnetPrefix: '10.1.1.0/24'
    hubVnetId: hubVnet.outputs.hubVnetId
    hubVnetName: hubVnetName
  }
}

// Deploy Prod Spoke VNet
module prodSpoke '../modules/networking/spokeVnet.bicep' = {
  name: 'prodSpokeDeployment-${uniqueString(resourceGroup().id)}'
  params: {
    spokeVnetName: prodSpokeVnetName
    location: location
    environment: environment
    spokeAddressPrefix: '10.2.0.0/16'
    workloadSubnetPrefix: '10.2.1.0/24'
    hubVnetId: hubVnet.outputs.hubVnetId
    hubVnetName: hubVnetName
  }
}

// Hub peering back to Dev Spoke
module hubToDevPeering '../modules/networking/hubPeering.bicep' = {
  name: 'hubToDevPeeringDeployment-${uniqueString(resourceGroup().id)}'
  params: {
    hubVnetName: hubVnetName
    spokeVnetName: devSpokeVnetName
    spokeVnetId: devSpoke.outputs.spokeVnetId
  }
  dependsOn: [hubVnet, devSpoke]
}

// Hub peering back to Prod Spoke
module hubToProdPeering '../modules/networking/hubPeering.bicep' = {
  name: 'hubToProdPeeringDeployment-${uniqueString(resourceGroup().id)}'
  params: {
    hubVnetName: hubVnetName
    spokeVnetName: prodSpokeVnetName
    spokeVnetId: prodSpoke.outputs.spokeVnetId
  }
  dependsOn: [hubVnet, prodSpoke]
}

// Outputs
output hubVnetId string = hubVnet.outputs.hubVnetId
output devSpokeVnetId string = devSpoke.outputs.spokeVnetId
output prodSpokeVnetId string = prodSpoke.outputs.spokeVnetId
