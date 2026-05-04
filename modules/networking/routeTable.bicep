// modules/networking/routeTable.bicep
// Route table forcing traffic through Azure Firewall

@description('Route table name')
param routeTableName string

@description('Azure region')
param location string = resourceGroup().location

@description('Environment name')
@allowed(['dev', 'prod'])
param environment string

@description('Azure Firewall private IP address')
param firewallPrivateIp string

var commonTags = {
  environment: environment
  project: 'iac-study'
  managedBy: 'bicep'
}

resource routeTable 'Microsoft.Network/routeTables@2023-05-01' = {
  name: routeTableName
  location: location
  tags: commonTags
  properties: {
    disableBgpRoutePropagation: true  // prevents on-prem routes overriding UDRs
    routes: [
      {
        name: 'route-to-firewall'
        properties: {
          addressPrefix: '0.0.0.0/0'         // all traffic
          nextHopType: 'VirtualAppliance'     // send to NVA/firewall
          nextHopIpAddress: firewallPrivateIp // firewall private IP
        }
      }
    ]
  }
}

output routeTableId string = routeTable.id
output routeTableName string = routeTable.name
