// modules/networking/azureFirewall.bicep
// Azure Firewall with network and application rules

@description('Firewall name')
param firewallName string

@description('Azure region')
param location string = resourceGroup().location

@description('Environment name')
@allowed(['dev', 'prod'])
param environment string

@description('Firewall subnet ID - must be AzureFirewallSubnet')
param firewallSubnetId string

@description('Public IP resource ID for firewall')
param publicIpId string

@description('Spoke address prefixes allowed through firewall')
param spokeAddressPrefixes array = [
  '10.1.0.0/16'
  '10.2.0.0/16'
]

var commonTags = {
  environment: environment
  project: 'iac-study'
  managedBy: 'bicep'
}

// Firewall Policy - modern way to manage rules
resource firewallPolicy 'Microsoft.Network/firewallPolicies@2023-05-01' = {
  name: 'policy-${firewallName}'
  location: location
  tags: commonTags
  properties: {
    sku: {
      tier: 'Standard'
    }
    threatIntelMode: 'Alert'  // Alert on known malicious IPs
  }
}

// Rule Collection Group
resource ruleCollectionGroup 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2023-05-01' = {
  parent: firewallPolicy
  name: 'DefaultRuleCollectionGroup'
  properties: {
    priority: 200
    ruleCollections: [

      // Network rules - Layer 4
      {
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        name: 'NetworkRules'
        priority: 100
        action: {
          type: 'Allow'
        }
        rules: [
          {
            ruleType: 'NetworkRule'
            name: 'allow-dns'
            ipProtocols: ['UDP']
            sourceAddresses: spokeAddressPrefixes
            destinationAddresses: ['168.63.129.16']  // Azure DNS
            destinationPorts: ['53']
            description: 'Allow DNS resolution via Azure DNS'
          }
          {
            ruleType: 'NetworkRule'
            name: 'allow-azure-monitor'
            ipProtocols: ['TCP']
            sourceAddresses: spokeAddressPrefixes
            destinationAddresses: ['AzureMonitor']
            destinationPorts: ['443']
            description: 'Allow Azure Monitor telemetry'
          }
          {
            ruleType: 'NetworkRule'
            name: 'allow-spoke-to-spoke'
            ipProtocols: ['TCP', 'UDP', 'ICMP']
            sourceAddresses: spokeAddressPrefixes
            destinationAddresses: spokeAddressPrefixes
            destinationPorts: ['*']
            description: 'Allow inter-spoke traffic through firewall'
          }
        ]
      }

      // Application rules - Layer 7 FQDN based
      {
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        name: 'ApplicationRules'
        priority: 200
        action: {
          type: 'Allow'
        }
        rules: [
          {
            ruleType: 'ApplicationRule'
            name: 'allow-windows-update'
            sourceAddresses: spokeAddressPrefixes
            protocols: [
              { protocolType: 'Https', port: 443 }
              { protocolType: 'Http', port: 80 }
            ]
            fqdnTags: ['WindowsUpdate']
            description: 'Allow Windows Update via FQDN tag'
          }
          {
            ruleType: 'ApplicationRule'
            name: 'allow-microsoft-services'
            sourceAddresses: spokeAddressPrefixes
            protocols: [
              { protocolType: 'Https', port: 443 }
            ]
            targetFqdns: [
              '*.microsoft.com'
              '*.azure.com'
              '*.windows.net'
            ]
            description: 'Allow Microsoft and Azure service FQDNs'
          }
        ]
      }
    ]
  }
}

// Azure Firewall
resource azureFirewall 'Microsoft.Network/azureFirewalls@2023-05-01' = {
  name: firewallName
  location: location
  tags: commonTags
  properties: {
    sku: {
      name: 'AZFW_VNet'
      tier: 'Standard'
    }
    firewallPolicy: {
      id: firewallPolicy.id
    }
    ipConfigurations: [
      {
        name: 'ipconfig-${firewallName}'
        properties: {
          subnet: {
            id: firewallSubnetId
          }
          publicIPAddress: {
            id: publicIpId
          }
        }
      }
    ]
  }
  dependsOn: [ruleCollectionGroup]
}

output firewallId string = azureFirewall.id
output firewallName string = azureFirewall.name
output firewallPrivateIp string = azureFirewall.properties.ipConfigurations[0].properties.privateIPAddress
output firewallPolicyId string = firewallPolicy.id
