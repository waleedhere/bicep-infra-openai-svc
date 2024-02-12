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

param privateEndpointOpenAiName string

@description('location of the Open AI Service')
param openAilocation string

@description('That name is the name of our application.')
param cognitiveServiceName string

@description('Location for all resources.')
param location string = resourceGroup().location

// existing resource name params 
param vnetName string
param snetOpenAiName string


param virtualNetworkId string

var subnetOpenAiId = virtualNetwork::privateEndointSnetOpenAi.id

// ---- Existing resources ----
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-06-01' existing = {
  name: vnetName

  resource privateEndointSnetOpenAi 'subnets' existing = {
    name: snetOpenAiName

  }
}

resource openAiAccount 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: openAiName
  location: openAilocation
  kind: kind
  properties: {
    customSubDomainName: customDomainName
    publicNetworkAccess: publicNetworkAccess
    networkAcls: {
      defaultAction: 'Deny'
    }
  }

  sku: openAiSku
}

resource openaiDeployment 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' = {
  parent: openAiAccount
  name: cognitiveServiceName
  sku: {
    capacity: 1
    name: 'Standard'
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: 'gpt-4'
      version: '1106-Preview'
    }
    raiPolicyName: null
  }
}

resource privateEndpointOpenAi 'Microsoft.Network/privateEndpoints@2022-01-01' = {
  name: privateEndpointOpenAiName

  location: location
  properties: {
    subnet: {
      id: subnetOpenAiId
    }
    customNetworkInterfaceName: 'pe-nic-openai'
    privateLinkServiceConnections: [
      {
        name: privateEndpointOpenAiName
        properties: {
          privateLinkServiceId: openAiAccount.id
          groupIds: [
            'account'
          ]
        }
      }
    ]
  }
  dependsOn: [ dnsZones ]

  resource dnsZoneGroupOpenAi 'privateDnsZoneGroups' = {
    name: '${privateEndpointOpenAiName}-default'
    properties: {
      privateDnsZoneConfigs: [
        {
          name: 'privatelink-openai-azure-com'
          properties: {
            privateDnsZoneId: dnsZones.id
          }
        }
      ]
    }
  }
}

resource dnsZones 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.openai.azure.com'
  location: 'global'
  tags: {}
  properties: {}
  resource virtualNetworkLink 'virtualNetworkLinks' = {
    name: virtualNetworkId
    location: 'global'
    properties: {
      virtualNetwork: {
        id: virtualNetwork.id
      }
      registrationEnabled: false
    }
  }

}

// ---- Outputs ----

output openAiResourceName string = openAiAccount.name
