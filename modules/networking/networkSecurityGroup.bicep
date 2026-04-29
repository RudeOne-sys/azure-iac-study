// modules/networking/networkSecurityGroup.bicep
// NSG with security rules using Service Tags and ASGs

@description('NSG name')
param nsgName string

@description('Azure region')
param location string = resourceGroup().location

@description('Environment name')
@allowed(['dev', 'prod'])
param environment string

@description('ASG ID for web tier')
param webAsgId string

@description('ASG ID for app tier')
param appAsgId string

@description('ASG ID for data tier')
param dataAsgId string

var commonTags = {
  environment: environment
  project: 'iac-study'
  managedBy: 'bicep'
}

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2023-05-01' = {
  name: nsgName
  location: location
  tags: commonTags
  properties: {
    securityRules: [

      // ── Inbound Rules ──────────────────────────────────

      {
        name: 'allow-https-inbound'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: 'Internet'
          sourcePortRange: '*'
          destinationApplicationSecurityGroups: [
            { id: webAsgId }
          ]
          destinationPortRange: '443'
          description: 'Allow HTTPS from internet to web tier only'
        }
      }

      {
        name: 'allow-web-to-app'
        properties: {
          priority: 200
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceApplicationSecurityGroups: [
            { id: webAsgId }
          ]
          sourcePortRange: '*'
          destinationApplicationSecurityGroups: [
            { id: appAsgId }
          ]
          destinationPortRange: '8080'
          description: 'Allow web tier to call app tier on port 8080'
        }
      }

      {
        name: 'allow-app-to-data'
        properties: {
          priority: 300
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceApplicationSecurityGroups: [
            { id: appAsgId }
          ]
          sourcePortRange: '*'
          destinationApplicationSecurityGroups: [
            { id: dataAsgId }
          ]
          destinationPortRange: '1433'
          description: 'Allow app tier to reach SQL on port 1433'
        }
      }

      {
        name: 'allow-bastion-ssh'
        properties: {
          priority: 400
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: 'VirtualNetwork'
          sourcePortRange: '*'
          destinationAddressPrefix: 'VirtualNetwork'
          destinationPortRange: '22'
          description: 'Allow SSH from Bastion subnet only'
        }
      }

      {
        name: 'deny-all-inbound'
        properties: {
          priority: 4000
          direction: 'Inbound'
          access: 'Deny'
          protocol: '*'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
          description: 'Explicit deny all - belt and braces'
        }
      }

      // ── Outbound Rules ─────────────────────────────────

      {
        name: 'allow-azure-services-outbound'
        properties: {
          priority: 100
          direction: 'Outbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: 'VirtualNetwork'
          sourcePortRange: '*'
          destinationAddressPrefix: 'AzureCloud'
          destinationPortRange: '443'
          description: 'Allow outbound to Azure services over HTTPS'
        }
      }

      {
        name: 'deny-internet-outbound'
        properties: {
          priority: 4000
          direction: 'Outbound'
          access: 'Deny'
          protocol: '*'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: 'Internet'
          destinationPortRange: '*'
          description: 'Block direct internet outbound - must go through firewall'
        }
      }
    ]
  }
}

// Flow logs require Network Watcher - covered in Session 13
output nsgId string = networkSecurityGroup.id
output nsgName string = networkSecurityGroup.name
