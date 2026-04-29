// deployments/nsg.bicep
// Deploys ASGs and NSG for three-tier workload security

@description('Environment name')
@allowed(['dev', 'prod'])
param environment string

@description('Azure region')
param location string = resourceGroup().location

// Naming
var webAsgName = 'asg-web-${environment}'
var appAsgName = 'asg-app-${environment}'
var dataAsgName = 'asg-data-${environment}'
var nsgName = 'nsg-workload-${environment}'

// Deploy ASGs for each tier
module webAsg '../modules/networking/applicationSecurityGroup.bicep' = {
  name: 'webAsgDeployment-${uniqueString(resourceGroup().id)}'
  params: {
    asgName: webAsgName
    location: location
    environment: environment
    role: 'web'
  }
}

module appAsg '../modules/networking/applicationSecurityGroup.bicep' = {
  name: 'appAsgDeployment-${uniqueString(resourceGroup().id)}'
  params: {
    asgName: appAsgName
    location: location
    environment: environment
    role: 'app'
  }
}

module dataAsg '../modules/networking/applicationSecurityGroup.bicep' = {
  name: 'dataAsgDeployment-${uniqueString(resourceGroup().id)}'
  params: {
    asgName: dataAsgName
    location: location
    environment: environment
    role: 'data'
  }
}

// Deploy NSG referencing the ASGs
module nsg '../modules/networking/networkSecurityGroup.bicep' = {
  name: 'nsgDeployment-${uniqueString(resourceGroup().id)}'
  params: {
    nsgName: nsgName
    location: location
    environment: environment
    webAsgId: webAsg.outputs.asgId
    appAsgId: appAsg.outputs.asgId
    dataAsgId: dataAsg.outputs.asgId
  }
}

output nsgId string = nsg.outputs.nsgId
output webAsgId string = webAsg.outputs.asgId
output appAsgId string = appAsg.outputs.asgId
output dataAsgId string = dataAsg.outputs.asgId
