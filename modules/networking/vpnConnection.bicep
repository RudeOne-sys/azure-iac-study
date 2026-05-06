// modules/networking/vpnConnection.bicep
// VPN Connection - establishes the tunnel between VPN Gateway and on-premises

@description('Connection name')
param connectionName string

@description('Azure region')
param location string = resourceGroup().location

@description('Environment name')
@allowed(['dev', 'prod'])
param environment string

@description('VPN Gateway resource ID')
param vpnGatewayId string

@description('Local Network Gateway resource ID')
param localNetworkGatewayId string

@description('Shared key for the VPN tunnel - use Key Vault reference in production')
@secure()
param sharedKey string

@description('Enable BGP')
param enableBgp bool = true

var commonTags = {
  environment: environment
  project: 'iac-study'
  managedBy: 'bicep'
}

resource vpnConnection 'Microsoft.Network/connections@2023-05-01' = {
  name: connectionName
  location: location
  tags: commonTags
  properties: {
    connectionType: 'IPsec'
    virtualNetworkGateway1: {
      id: vpnGatewayId
      properties: {}
    }
    localNetworkGateway2: {
      id: localNetworkGatewayId
      properties: {}
    }
    sharedKey: sharedKey
    enableBgp: enableBgp
    ipsecPolicies: [
      {
        saLifeTimeSeconds: 27000
        saDataSizeKilobytes: 102400000
        ipsecEncryption: 'AES256'
        ipsecIntegrity: 'SHA256'
        ikeEncryption: 'AES256'
        ikeIntegrity: 'SHA256'
        dhGroup: 'DHGroup14'
        pfsGroup: 'PFS14'
      }
    ]
  }
}

output connectionId string = vpnConnection.id
output connectionName string = vpnConnection.name
