// modules/storage/storageAccount.bicep
// Reusable storage account module

@description('Name of the storage account - must be globally unique')
@minLength(3)
@maxLength(24)
param storageAccountName string

@description('Azure region for deployment')
param location string = resourceGroup().location

@description('Storage account SKU')
@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_ZRS'
])
param sku string = 'Standard_LRS'

@description('Environment tag')
@allowed([
  'dev'
  'prod'
])
param environment string

@description('Project tag')
param project string = 'iac-study'

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: sku
  }
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    supportsHttpsTrafficOnly: true
  }
  tags: {
    environment: environment
    project: project
    managedBy: 'bicep'
  }
}

output storageAccountId string = storageAccount.id
output storageAccountName string = storageAccount.name
