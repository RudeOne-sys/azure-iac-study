// modules/networking/applicationSecurityGroup.bicep
// Application Security Group for grouping VMs by role

@description('ASG name')
param asgName string

@description('Azure region')
param location string = resourceGroup().location

@description('Environment name')
@allowed(['dev', 'prod'])
param environment string

@description('Workload role this ASG represents')
param role string

var commonTags = {
  environment: environment
  project: 'iac-study'
  managedBy: 'bicep'
  role: role
}

resource applicationSecurityGroup 'Microsoft.Network/applicationSecurityGroups@2023-05-01' = {
  name: asgName
  location: location
  tags: commonTags
  properties: {}
}

output asgId string = applicationSecurityGroup.id
output asgName string = applicationSecurityGroup.name
