// deployments/hybridConnectivity.bicep
// Deploys VPN Gateway, Local Network Gateway and VPN Connection

@description('Environment name')
@allowed(['dev', 'prod'])
param environment string

@description('Azure region')
param location string = resourceGroup().location

@description('Hub VNet name')
param hubVnetName string

@description('On-premises VPN device public IP - placeholder for study environment')
param onPremPublicIp string = '1.2.3.4'

@description('VPN tunnel shared key')
@secure()
param vpnSharedKey string

// Naming
var vpnGatewayName = 'vpng-hub-${environment}'
var lngName = 'lng-onprem-${environment}'
var connectionName = 'cn-hub-to-onprem-${environment}'

// Reference existing hub VNet
resource hubVnet 'Microsoft.Network/virtualNetworks@2023-05-01' existing = {
  name: hubVnetName
}

var gatewaySubnetId = '${hubVnet.id}/subnets/GatewaySubnet'

// Deploy VPN Gateway
module vpnGateway '../modules/networking/vpnGateway.bicep' = {
  name: 'vpnGatewayDeployment-${uniqueString(resourceGroup().id)}'
  params: {
    vpnGatewayName: vpnGatewayName
    location: location
    environment: environment
    gatewaySubnetId: gatewaySubnetId
  }
}

// Deploy Local Network Gateway
module localNetworkGateway '../modules/networking/localNetworkGateway.bicep' = {
  name: 'lngDeployment-${uniqueString(resourceGroup().id)}'
  params: {
    lngName: lngName
    location: location
    environment: environment
    onPremPublicIp: onPremPublicIp
  }
}

// Deploy VPN Connection
module vpnConnection '../modules/networking/vpnConnection.bicep' = {
  name: 'vpnConnectionDeployment-${uniqueString(resourceGroup().id)}'
  params: {
    connectionName: connectionName
    location: location
    environment: environment
    vpnGatewayId: vpnGateway.outputs.vpnGatewayId
    localNetworkGatewayId: localNetworkGateway.outputs.lngId
    sharedKey: vpnSharedKey
  }
}

output vpnGatewayPublicIp string = vpnGateway.outputs.vpnGatewayPublicIp
output vpnGatewayName string = vpnGateway.outputs.vpnGatewayName
output connectionName string = vpnConnection.outputs.connectionName
