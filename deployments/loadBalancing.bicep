// deployments/loadBalancing.bicep
// Deploys Application Gateway (web tier) and Internal LB (app tier)

@description('Environment name')
@allowed(['dev', 'prod'])
param environment string

@description('Azure region')
param location string = resourceGroup().location

@description('Hub VNet name')
param hubVnetName string

@description('Spoke VNet name for internal LB')
param spokeVnetName string

// Naming
var appGwName = 'agw-hub-${environment}'
var lbName = 'lbi-app-${environment}'

// Reference existing hub VNet for App Gateway subnet
resource hubVnet 'Microsoft.Network/virtualNetworks@2023-05-01' existing = {
  name: hubVnetName
}

// Reference existing spoke VNet for internal LB subnet
resource spokeVnet 'Microsoft.Network/virtualNetworks@2023-05-01' existing = {
  name: spokeVnetName
}

var appGwSubnetId = '${hubVnet.id}/subnets/snet-appgateway'
var appSubnetId = '${spokeVnet.id}/subnets/snet-workload'

// Deploy Application Gateway
module appGateway '../modules/networking/applicationGateway.bicep' = {
  name: 'appGwDeployment-${uniqueString(resourceGroup().id)}'
  params: {
    appGwName: appGwName
    location: location
    environment: environment
    subnetId: appGwSubnetId
  }
}

// Deploy Internal Load Balancer
module loadBalancer '../modules/networking/loadBalancer.bicep' = {
  name: 'lbDeployment-${uniqueString(resourceGroup().id)}'
  params: {
    lbName: lbName
    location: location
    environment: environment
    subnetId: appSubnetId
  }
}

output appGwPublicIp string = appGateway.outputs.publicIpAddress
output lbFrontendIp string = loadBalancer.outputs.frontendIp
