/*
###
#   deploy.spoke.ai.function.bicep
#
#   This Bicep file creates a function apb.
#
#   List of actions:
#     - Creates App Service Plan, Function app, Application Insight
#     - Creates VNET and subnet 
#     - Creates peering
#     - Creates Keyvault
#     - Creates OpenAI Services
### 
*/

@description('Storage Account type')
param storageAccountType string

@description('storage Account Name')
param storageAccountName string

@description('That name is the name of our application.')
param cognitiveServiceName string

@description('Function App Name')
param functionAppName string

@description('Hosting Plan Name')
param hostingPlanName string

@description('Hosting Plan SKU')
param hostingSkuName string

@description('Hosting Plan tier')
param hostingTier string

@description('Location for all resources.')
param location string = resourceGroup().location

@description('location of the Open AI Service')
param openAilocation string

@description('VNET name.')
param vnetName string

@description('SNET name for Function')
param snetFunctionName string

@description('SNET name for Open AI Service')
param snetOpenAiName string

param peerings array

@description('Name of the private Endpoint for the AI Account Service')
param privateEndpointOpenAiName string

@description('Name of the Application Insight')
param applicationInsightName string

@description('Name of the Azure OpenAI service')
param openAiName string

@description('Name of the Domain for Open AI Studio')
param customDomainName string

@description('Kind of the Azure OpenAI service')
param kind string

@description('KPublic network access of the Azure OpenAI service')
param publicNetworkAccess string

@description('SKU for Open AI Service')
param openAiSku object

@description('Name of the Key Vault')
param keyVaultName string

param clientId string

@description('Adding secret name of App registration')
param clientSecretNameValue string

@description('Adding secret name of API key for Open AI service')
@secure()
param apiKeyNameValue string

@description('Adding secret value of App registration')
@secure()
param clientSecretValue string

@description('Adding secret value of API key for Open AI service')
@secure()
param apiKeyValue string

@description('Name of the privatelink')
param openAIVirtualNetworkLinkName string

module virtualNetworkModule 'network.bicep' = {
  name: 'NetworkDeploy'
  params: {
    vnetName: vnetName
    snetFunctionName: snetFunctionName
    snetOpenAiName: snetOpenAiName
    location: location
  }
}
module peeringFromRemote '../modules/deploy.spoke.services.vnet.peering.with.hub.bicep' = [for peering in peerings: {
  name: 'module-peer-${peering.remoteVnetName}-to-${vnetName}'
  scope: resourceGroup(peering.resourceGroupName)
  params: {
    hubVnetName: peering.remoteVnetName
    peeringName: 'peer-${peering.remoteVnetName}-to-${vnetName}'
    spokeResourceGroupName: resourceGroup().name
    spokeVnetName: vnetName
  }
  dependsOn: [
    virtualNetworkModule
  ]
}]

module peeringToRemote '../modules/deploy.spoke.services.vnet.peering.with.hub.bicep' = [for peering in peerings: {
  name: 'module-peer-${vnetName}-to-${peering.remoteVnetName}'
  params: {
    hubVnetName: vnetName
    peeringName: 'peer-${vnetName}-to-${peering.remoteVnetName}'
    spokeResourceGroupName: peering.resourceGroupName
    spokeVnetName: peering.remoteVnetName
  }
  dependsOn: [
    virtualNetworkModule
  ]
}]

module deployKeyvaultwithSecret 'keyvault.bicep' = {
  name: 'KeyVaultDeploy'
  dependsOn: [
    virtualNetworkModule
  ]
  params: {
    keyVaultName: keyVaultName
    location: location
    clientSecretName: clientSecretNameValue
    apiKeyName: apiKeyNameValue
    clientsecretValue: clientSecretValue
    apiKeySecretValue: apiKeyValue
    snetFunctionName: snetFunctionName
    vnetName: vnetName
  }
}

module functionAppModule 'functionapp.bicep' = {
  name: 'functionAppDeploy'
  dependsOn: [
    virtualNetworkModule
    deployKeyvaultwithSecret
  ]
  params: {
    functionAppName: functionAppName
    location: location
    applicationInsightName: applicationInsightName
    hostingPlanName: hostingPlanName
    hostingSkuName: hostingSkuName
    hostingTier: hostingTier
    storageAccountName: storageAccountName
    vnetName: vnetName
    storageAccountType: storageAccountType
    keyVaultName: keyVaultName
    apiKeyName: apiKeyNameValue
    clientSecretName: clientSecretNameValue
    snetFunctionName: snetFunctionName
    appRegistrationClientId: clientId
    requireAzureOauth: true
  }
}

module openAiModule 'openai.bicep' = {
  name: 'DeployOpenAIServices'
  dependsOn: [
    virtualNetworkModule
  ]
  params: {
    openAiName: openAiName
    openAilocation: openAilocation
    cognitiveServiceName: cognitiveServiceName
    customDomainName: customDomainName
    location: location
    kind: kind
    openAiSku: openAiSku
    privateEndpointOpenAiName: privateEndpointOpenAiName
    publicNetworkAccess: publicNetworkAccess
    snetOpenAiName: snetOpenAiName
    vnetName: vnetName
    virtualNetworkId: openAIVirtualNetworkLinkName
  }
}
