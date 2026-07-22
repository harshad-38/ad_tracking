// Execute this main file to deploy a plain, standard Azure Machine Learning workspace

// Parameters
@minLength(2)
@maxLength(12)
@description('Name for the AI resource and used to derive name of dependent resources.')
param workSpaceName string = 'adtracking' // Kept under 12 chars to prevent storage name overflow

@description('Friendly name for your Azure AI resource')
param workSpaceFriendlyName string = 'Testing Ad Tracking Env' // Fixed parameter spelling typo

@description('Description of your Azure AI resource displayed in AI Foundry')
param workSpaceDescription string = 'This resource is created for testing purpose.'

@description('Azure region used for the deployment of all resources.')
param location string = resourceGroup().location

@description('Set of tags to apply to all resources.')
// FIXED: Cleaned up object literal syntax strings to valid Bicep structure
param tags object = {
  env: 'staging'
  task: 'testing'
}

// Variables
var name = toLower('${workSpaceName}')

// Create a short, unique suffix, that will be unique to each resource group
var uniqueSuffix = substring(uniqueString(resourceGroup().id), 0, 4)

// 1. Core Dependent resources (WITHOUT AI Services)
module mlDependencies 'modules/dependent-resources.bicep' = {
  name: 'dependencies-${name}-${uniqueSuffix}-deployment'
  params: {
    location: location
    storageName: 'st${name}${uniqueSuffix}'
    keyvaultName: 'kv-${name}-${uniqueSuffix}'
    applicationInsightsName: 'appi-${name}-${uniqueSuffix}'
    containerRegistryName: 'cr${name}${uniqueSuffix}'
    tags: tags
    // REMOVED: aiServicesName parameter
  }
}

// 2. Standard Machine Learning Workspace Deployment
module standardWorkSpace 'modules/standard-workspace.bicep' = { // Renamed file path for clarity
  name: 'mlw-${name}-${uniqueSuffix}-deployment'
  params: {
    // workspace organization
    workSpaceName: 'mlw-${name}-${uniqueSuffix}'
    workSpaceFriendlyName: workSpaceFriendlyName
    workSpaceDescription: workSpaceDescription
    location: location
    tags: tags

    // Core underlying infrastructure inputs passed cleanly from dependencies module
    applicationInsightsId: mlDependencies.outputs.applicationInsightsId
    containerRegistryId: mlDependencies.outputs.containerRegistryId
    keyVaultId: mlDependencies.outputs.keyvaultId
    storageAccountId: mlDependencies.outputs.storageId
    
    // REMOVED: aiServicesId and aiServicesTarget lines completely
  }
}
