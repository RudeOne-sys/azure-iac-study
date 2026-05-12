// modules/networking/networkWatcher.bicep
// Network Watcher and NSG Flow Logs

@description('Azure region')
param location string = resourceGroup().location

@description('Environment name')
@allowed(['dev', 'prod'])
param environment string

@description('Storage Account ID for flow logs')
param storageAccountId string

@description('Log Analytics Workspace ID for Traffic Analytics')
param logAnalyticsWorkspaceId string = ''

@description('NSG resource IDs to enable flow logs for')
param nsgIds array = []

@description('Flow log retention in days')
param flowLogRetentionDays int = environment == 'prod' ? 90 : 30

var networkWatcherName = 'NetworkWatcher_${location}'
var commonTags = {
  environment: environment
  project: 'iac-study'
  managedBy: 'bicep'
}

// Network Watcher - one per region per subscription
resource networkWatcher 'Microsoft.Network/networkWatchers@2023-05-01' = {
  name: networkWatcherName
  location: location
  tags: commonTags
  properties: {}
}

// NSG Flow Logs - one per NSG
resource flowLogs 'Microsoft.Network/networkWatchers/flowLogs@2023-05-01' = [for (nsgId, i) in nsgIds: {
  parent: networkWatcher
  name: 'flowlog-${i}'
  location: location
  tags: commonTags
  properties: {
    enabled: true
    storageId: storageAccountId
    targetResourceId: nsgId
    retentionPolicy: {
      days: flowLogRetentionDays
      enabled: true
    }
    format: {
      type: 'JSON'
      version: 2    // version 2 includes bytes and packets
    }
    flowAnalyticsConfiguration: logAnalyticsWorkspaceId != '' ? {
      networkWatcherFlowAnalyticsConfiguration: {
        enabled: true
        workspaceResourceId: logAnalyticsWorkspaceId
        trafficAnalyticsInterval: 60
      }
    } : null
  }
}]

output networkWatcherId string = networkWatcher.id
output networkWatcherName string = networkWatcher.name
