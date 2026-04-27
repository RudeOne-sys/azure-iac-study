// deployments/compute.bicep
// Orchestrates networking and compute modules

@description('Environment name')
@allowed(['dev', 'prod'])
param environment string

@description('Azure region')
param location string = resourceGroup().location

@description('Admin SSH public key for VM access')
@secure()
param adminSshKey string

// Naming variables
var vnetName = 'vnet-iac-${environment}'
var vmName = 'vm-iac-${environment}'

// Deploy networking first
module networking '../modules/networking/virtualNetwork.bicep' = {
  name: 'networkingDeployment-${uniqueString(resourceGroup().id)}'
  params: {
    vnetName: vnetName
    location: location
    environment: environment
  }
}

// Deploy VM - passes subnet ID from networking output
module compute '../modules/compute/virtualMachine.bicep' = {
  name: 'computeDeployment-${uniqueString(resourceGroup().id)}'
  params: {
    vmName: vmName
    location: location
    environment: environment
    subnetId: networking.outputs.subnetId
    adminSshKey: adminSshKey
  }
}

output vmId string = compute.outputs.vmId
output vmName string = compute.outputs.vmName
output managedIdentityPrincipalId string = compute.outputs.managedIdentityPrincipalId
output privateIpAddress string = compute.outputs.privateIpAddress
output vnetId string = networking.outputs.vnetId
