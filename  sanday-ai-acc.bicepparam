using './main.bicep'

param cognitiveServiceName = 'gpt4-verrichting'

param openAilocation = 'francecentral'

param openAiName = 'ai-sanday-acc'

param customDomainName = 'openai-acc-sanday'

param kind = 'OpenAI'

param publicNetworkAccess = 'Disabled'

param vnetName = 'vnet-ai-acc'

param snetFunctionName = 'snet-ai-func-acc'

param snetOpenAiName = 'snet-ai-svc-acc'

param privateEndpointOpenAiName = 'pe-openai-acc'

param functionAppName = 'func-procedurepal-acc'

param hostingPlanName = 'plan-open-ai-acc'

param storageAccountType = 'Standard_ZRS'

param storageAccountName = 'stsopenaiacc01'

param hostingSkuName = 'S1'

param hostingTier = 'Standard'

param applicationInsightName = 'ai-openai-acc'

param openAIVirtualNetworkLinkName = 'openai-virtualnetworklink'

param apiKeyNameValue = 'APIKEY'

param apiKeyValue = ''

param clientId = '4d0188f2-e826-4a50-a397-bf3fd5483feb' //767f96f1-f02c-45ce-9df6-7518b9d5a6d1<==ClientId of the sandbox//
//'4d0188f2-e826-4a50-a397-bf3fd5483feb' //ClientId of the app reg acc

param clientSecretNameValue = 'ClientSecret'

param clientSecretValue = ''

param keyVaultName = 'kv-ai-acc'

param openAiSku = {
  name: 'S0'
}

param peerings = [ {
    resourceGroupName: 'rg-huisarts-acc'
    remoteVnetName: 'vnet-huisarts-acc'
    remotePeeringName: 'peering-vnet-huisarts-acc-to-vnet-ai-acc'
    localPeeringName: 'vnet-ai-acc-to-vnet-huisarts-acc'

  }
]
