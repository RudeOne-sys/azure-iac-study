// deployments/dnsMonitoring.bicep
// Deploys DNS zones and Network Watcher with flow logs

@description('Environment name')
@allowed(['dev', 'prod'])
param environment string

@description('Azure region')
param location string = resourceGroup().location

@description('Public DNS zone name - use your actual domain or a placeholder')
param publicDnsZoneName string

@description('Storage Account ID for flow logs')
param storageAccountId string

@description('NSG resource ID for flow logs')
param nsgId string

@description('Log Analytics Workspace ID - optional, enables Traffic Analytics')
param logAnalyticsWorkspaceId string = ''

// Deploy Public DNS Zone
module publicDnsZone '../modules/networking/dnsZone.bicep' = {
  name: 'dnsZoneDeployment-${uniqueString(resourceGroup().id)}'
  params: {
    zoneName: publicDnsZoneName
    environment: environment
    aRecords: [
      {
        name: 'www'
        ttl: 3600
        ipAddress: '1.2.3.4'    // placeholder - replace with App Gateway IP
      }
    ]
    txtRecords: [
      {
        name: '@'
        ttl: 3600
        value: 'v=spf1 include:azure.com ~all'  // example SPF record
      }
    ]
  }
}

// Deploy Network Watcher and Flow Logs
module networkWatcher '../modules/networking/networkWatcher.bicep' = {
  name: 'networkWatcherDeployment-${uniqueString(resourceGroup().id)}'
  params: {
    location: location
    environment: environment
    storageAccountId: storageAccountId
    nsgIds: [nsgId]
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
  }
}

output dnsZoneNameServers array = publicDnsZone.outputs.nameServers
output networkWatcherId string = networkWatcher.outputs.networkWatcherId
