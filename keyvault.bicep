/*
###
#
#   This bicep create up an Keyvsult in azure and creates secret defined in the parameter file in the root directory.
#
#   List of actions:
#   - Gather all param/variables.
#   - Create Key vault resource.
#
###
*/

@description('Specifies the name of the key vault.')
param keyVaultName string

@description('Specifies the Azure location where the key vault should be created.')
param location string = resourceGroup().location

@description('Specifies whether the key vault is a standard vault or a premium vault.')
@allowed([
  'standard'
  'premium'
])
param skuName string = 'standard'

@description('Specifies the name of the secret that you want to create.')
param clientSecretName string

@description('Specifies the name of the secret that you want to create.')
param apiKeyName string

@secure()
@description('Value of secret for ClientSecret')
param clientsecretValue string

@secure()
@description('Value of secret for APIKEY')
param apiKeySecretValue string

param vnetName string

param snetFunctionName string

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-06-01' existing = {
  name: vnetName

  resource snetFunctionReference 'subnets' existing = {
    name: snetFunctionName
  }
}

resource kv 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  properties: {
    sku: {
      name: skuName
      family: 'A'
    }
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
      virtualNetworkRules: [
        {
          id: resourceId(resourceGroup().name, 'Microsoft.Network/virtualNetworks/subnets', vnetName, snetFunctionName)
        }
      ]
    }
    enableRbacAuthorization: true
    enabledForDeployment: false
    enablePurgeProtection: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    tenantId: tenant().tenantId
  }
  resource secretClientSecret 'secrets' = {
    name: clientSecretName
    properties: {
      value: clientsecretValue
    }
  }
  resource secretAPIKey 'secrets' = {
    name: apiKeyName
    properties: {
      value: apiKeySecretValue
    }
  }
}

