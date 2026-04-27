// modules/storage/storageAccount.bicep
// Enhanced storage module demonstrating core Bicep concepts

@description('Name of the storage account - must be globally unique, 3-24 chars, lowercase only')
@minLength(3)
@maxLength(24)
param storageAccountName string

@description('Azure region for deployment')
param location string = resourceGroup().location

@description('Storage account SKU - prod uses GRS for geo-redundancy')
@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_ZRS'
  'Premium_LRS'
])
param sku string = 'Standard_LRS'

@description('Environment name - controls conditional features')
@allowed(['dev', 'prod'])
param environment string

@description('Project identifier for tagging')
param project string = 'iac-study'

@description('Enable blob soft delete - always on in prod')
param enableSoftDelete bool = true

@description('Soft delete retention in days')
@minValue(1)
@maxValue(365)
param softDeleteDays int = 7

// ── Variables ──────────────────────────────────────────────
// Soft delete days vary by environment
var retentionDays = environment == 'prod' ? 30 : softDeleteDays

// Common tags applied to all resources
var commonTags = {
  environment: environment
  project: project
  managedBy: 'bicep'
}

// ── Resources ──────────────────────────────────────────────
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
  tags: commonTags
}

// Blob service - child resource using parent reference
resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-01-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
    deleteRetentionPolicy: {
      enabled: enableSoftDelete
      days: retentionDays
    }
  }
}

// Conditional - advanced threat protection only in prod
resource threatProtection 'Microsoft.Security/advancedThreatProtectionSettings@2019-01-01' = if (environment == 'prod') {
  name: 'current'
  scope: storageAccount
  properties: {
    isEnabled: true
  }
}

// ── Outputs ────────────────────────────────────────────────
output storageAccountId string = storageAccount.id
output storageAccountName string = storageAccount.name
output blobEndpoint string = storageAccount.properties.primaryEndpoints.blob
output retentionDaysApplied int = retentionDays
