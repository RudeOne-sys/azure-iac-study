// deployments/storage.bicep
// Top-level deployment template - orchestrates modules

@description('Name of the storage account')
param storageAccountName string

@description('Environment name')
@allowed([
  'dev'
  'prod'
])
param environment string

@description('Storage SKU')
param sku string = 'Standard_LRS'

// Reference the reusable module
module storage '../modules/storage/storageAccount.bicep' = {
  name: 'storageDeployment-${uniqueString(resourceGroup().id)}'
  params: {
    storageAccountName: storageAccountName
    environment: environment
    sku: sku
  }
}

output deployedStorageId string = storage.outputs.storageAccountId
output deployedStorageName string = storage.outputs.storageAccountName
