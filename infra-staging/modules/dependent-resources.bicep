// Creates Azure dependent resources for an Azure Machine Learning workspace

@description('Azure region of the deployment')
param location string = resourceGroup().location

@description('Tags to add to the resources')
param tags object = {}

@description('Application Insights resource name')
param applicationInsightsName string

@description('Container registry name')
param containerRegistryName string

@description('The name of the Key Vault')
param keyvaultName string

var containerRegistryNameCleaned = replace(containerRegistryName, '-', '')

// 1. ADDED: Log Analytics Workspace backend to fix the Application Insights ingestion retirement
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2025-07-01' = {
  name: 'log-${applicationInsightsName}'
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

resource applicationInsights 'Microsoft.Insights/components@2026-03-01' = {
  name: applicationInsightsName
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspace.id // Explicitly linked to prevent deployment failures
    DisableIpMasking: false
    DisableLocalAuth: false
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2026-03-01-preview' = {
  name: containerRegistryNameCleaned
  location: location
  tags: tags
  sku: {
    name: 'Standard' // Changed from Premium to Standard to save unnecessary enterprise costs
  }
  properties: {
    adminUserEnabled: true
    // FIXED: Changed public entry points to 'Allow'/'Enabled' to prevent workspace resource lockouts
    publicNetworkAccess: 'Enabled' 
    networkRuleSet: {
      defaultAction: 'Allow'
    }
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2026-03-01-preview' = {
  name: keyvaultName
  location: location
  tags: tags
  properties: {
    createMode: 'default'
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: false
    enableSoftDelete: true
    enableRbacAuthorization: true
    enablePurgeProtection: false // Set to false for easier testing/deletion; change to true for strict production compliance
    // FIXED: Changed network isolation rules to Allow to prevent workspace connection blockages
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
    }
    sku: {
      family: 'A'
      name: 'standard'
    }
    softDeleteRetentionInDays: 7
    tenantId: subscription().tenantId
  }
}

@description('Name of the storage account')
param storageName string

@allowed([
  'Standard_LRS'
  'Standard_ZRS'
  'Standard_GRS'
  'Standard_GZRS'
  'Standard_RAGRS'
  'Standard_RAGZRS'
  'Premium_LRS'
  'Premium_ZRS'
])
@description('Storage SKU')
param storageSkuName string = 'Standard_LRS'

var storageNameCleaned = replace(storageName, '-', '')

resource storage 'Microsoft.Storage/storageAccounts@2026-04-01' = {
  name: storageNameCleaned
  location: location
  tags: tags
  sku: {
    name: storageSkuName
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    allowCrossTenantReplication: false
    allowSharedKeyAccess: true
    encryption: {
      keySource: 'Microsoft.Storage'
      requireInfrastructureEncryption: false
      services: {
        blob: { enabled: true, keyType: 'Account' }
        file: { enabled: true, keyType: 'Account' }
      }
    }
    isHnsEnabled: false
    isNfsV3Enabled: false
    minimumTlsVersion: 'TLS1_2'
    // FIXED: Network path set to Allow so standard public ML workspace initialization script succeeds
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
    }
    supportsHttpsTrafficOnly: true
  }
}

// MATCHED: Outputs match perfectly with main orchestrator expectations
output storageId string = storage.id
output keyvaultId string = keyVault.id
output containerRegistryId string = containerRegistry.id
output applicationInsightsId string = applicationInsights.id
