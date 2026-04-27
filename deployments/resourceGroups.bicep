// deployments/resourceGroups.bicep
// Subscription-scoped deployment to manage resource groups
targetScope = 'subscription'

@description('Azure region for resource groups')
param location string = 'southafricanorth'

// Dev resource group
resource rgDev 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: 'rg-iac-dev'
  location: location
  tags: {
    environment: 'dev'
    managedBy: 'bicep'
    project: 'iac-study'
  }
}

// Prod resource group
resource rgProd 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: 'rg-iac-prod'
  location: location
  tags: {
    environment: 'prod'
    managedBy: 'bicep'
    project: 'iac-study'
  }
}

output devRgId string = rgDev.id
output prodRgId string = rgProd.id
