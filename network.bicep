@description('VNET name.')
param vnetName string

@description('Location for all resources.')
param location string = resourceGroup().location

@description('SNET name for Function')
param snetFunctionName string

@description('SNET name for Open AI Service')
param snetOpenAiName string


resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-06-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [ '10.52.141.0/24' ]
    }
    subnets: [
      {
        name: snetFunctionName
        properties: {
          serviceEndpoints: [
            {
              service: 'Microsoft.CognitiveServices'
              locations: [
                '*'
              ]
            }
            {
              service: 'Microsoft.KeyVault'
              locations: [
                '*'
              ]
            }
            {
              service: 'Microsoft.Storage'
              locations: [
                '*'
              ]
            }
          ]
          addressPrefix: '10.52.141.0/26'
          delegations: [
            {
              name: 'Microsoft.Web/serverFarms'
              properties: {
                serviceName: 'Microsoft.Web/serverFarms'
              }
            }
          ]
        }
      }
      {
        name: snetOpenAiName
        properties: {
          addressPrefix: '10.52.141.128/26'
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
    ]
  }
}
