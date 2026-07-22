@description('Azure region of the deployment')
param location string

@description('Tags to add to the resources')
param tags object

@description('workspace name')
param workSpaceName string

@description('workspace display name')
param workSpaceFriendlyName string = workSpaceName

@description('workspace description')
param workSpaceDescription string

@description('Resource ID of the application insights resource for storing diagnostics logs')
param applicationInsightsId string

@description('Resource ID of the container registry resource for storing docker images')
param containerRegistryId string

@description('Resource ID of the key vault resource for storing connection strings')
param keyVaultId string

@description('Resource ID of the storage account resource for storing experimentation outputs')
param storageAccountId string

// REMOVED: AI Services parameters that are no longer needed

resource workSpace 'Microsoft.MachineLearningServices/workspaces@2026-05-01' = {
  name: workSpaceName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    friendlyName: workSpaceFreindlyName
    description: workSpaceDescription

    // dependent resources linked explicitly
    keyVault: keyVaultId
    storageAccount: storageAccountId
    applicationInsights: applicationInsightsId
    containerRegistry: containerRegistryId
  }
  kind: 'default' // Establishes a standard workspace, not an AI Hub 

  // REMOVED: Nested aiServicesConnection resource
}

output workSpaceID string = workSpace.id
