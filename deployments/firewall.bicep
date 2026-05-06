// deployments/firewall.bicep
// Orchestrates Azure Firewall, public IP and route tables

@description('Environment name')
@allowed(['dev', 'prod'])
param environment string

@description('Azure region')
param location string = resourceGroup().location

@description('Firewall subnet ID')
param firewallSubnetId string

// Naming
var firewallName = 'afw-hub-${environment}'
var publicIpName = 'pip-afw-hub-${environment}'
var routeTableName = 'rt-spoke-${environment}'

// Public IP for firewall
module firewallPublicIp '../modules/networking/publicIp.bicep' = {
  name: 'firewallPipDeployment-${uniqueString(resourceGroup().id)}'
  params: {
    publicIpName: publicIpName
    location: location
    environment: environment
    purpose: 'azure-firewall'
  }
}

// Azure Firewall
module firewall '../modules/networking/azureFirewall.bicep' = {
  name: 'firewallDeployment-${uniqueString(resourceGroup().id)}'
  params: {
    firewallName: firewallName
    location: location
    environment: environment
    firewallSubnetId: firewallSubnetId
    publicIpId: firewallPublicIp.outputs.publicIpId
    spokeAddressPrefixes: [
      '10.1.0.0/16'
      '10.2.0.0/16'
    ]
  }
}

// Route table for spoke subnets
module routeTable '../modules/networking/routeTable.bicep' = {
  name: 'routeTableDeployment-${uniqueString(resourceGroup().id)}'
  params: {
    routeTableName: routeTableName
    location: location
    environment: environment
    firewallPrivateIp: firewall.outputs.firewallPrivateIp
  }
}

output firewallId string = firewall.outputs.firewallId
output firewallPrivateIp string = firewall.outputs.firewallPrivateIp
output firewallPublicIp string = firewallPublicIp.outputs.publicIpAddress
output routeTableId string = routeTable.outputs.routeTableId
