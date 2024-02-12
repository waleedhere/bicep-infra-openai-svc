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

@description('Name of the Application Insight')
param applicationInsightName string

@description('storage Account Name')
param storageAccountName string

param requireAzureOauth bool 

var tenantId = subscription().tenantId

param appRegistrationClientId string

@description('Storage Account type')
param storageAccountType string

var keyVaultSecretsUserRole = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6')

var keyVaultCryptoOfficer = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '14b46e9e-c2b7-41b4-b07b-48a6ebf60603')

// ---- Existing resources --
param apiKeyName string

param clientSecretName string

param keyVaultName string

param vnetName string

param snetFunctionName string

resource kv 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

resource hostingPlan 'Microsoft.Web/serverfarms@2021-03-01' = {
  name: hostingPlanName
  location: location
  kind: 'linux'
  sku: {
    name: hostingSkuName
    tier: hostingTier
  }
  properties: {
    reserved: true

  }
}

resource azureFunction 'Microsoft.Web/sites@2022-03-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp,linux'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentityKv.id}': {}
    }
  }
  properties: {
    serverFarmId: hostingPlan.id
    reserved: true
    virtualNetworkSubnetId: resourceId(resourceGroup().name, 'Microsoft.Network/virtualNetworks/subnets', vnetName, snetFunctionName)
    keyVaultReferenceIdentity: managedIdentityKv.id
    siteConfig: {
      linuxFxVersion: 'Python|3.9'
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      alwaysOn: true
      ipSecurityRestrictions: [
        {
          ipAddress: '10.52.0.0/16'
          action: 'Allow'
          tag: 'Default'
          priority: 200
          name: 'Allow Azure VNETs'
        }
        {
          ipAddress: 'AzureCloud'
          action: 'Allow'
          tag: 'ServiceTag'
          priority: 200
          name: 'Allow Azure portal access'
          description: 'E.g. for export template option'
        }
        {
          ipAddress: 'Any'
          action: 'Deny'
          priority: 2147483647
          name: 'Deny all'
          description: 'Deny all access'
        }
      ]
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: toLower(functionAppName)
        }
        {
          name: 'AZURE_ENDPOINT'
          value: 'https://acc-sanday.openai.azure.com/'
        }
        {
          name: 'API_VERSION'
          value: '2023-07-01-preview'
        }
        {
          name: 'Client_id'
          value: '4d0188f2-e826-4a50-a397-bf3fd5483feb'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~2'
        }
        {
          name: 'DEPLOYMENT_NAME'
          value: 'gpt4-verrichting'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: applicationInsights.properties.InstrumentationKey
        }
        {
          name: 'API_KEY'
          value: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=${apiKeyName})'
        }
        {
          name: 'Client_secret'
          value: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=${clientSecretName})'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: '4'
        }
        {
          name: 'WEBSITE_CONTENTOVERVNET'
          value: '1'
        }
      ]
    }
  }
}

resource azureAdIdentityProvider 'Microsoft.Web/sites/config@2021-03-01' = if (requireAzureOauth) {
  name: 'authsettingsV2'
  parent: azureFunction
  properties: {
    globalValidation: {
      requireAuthentication: true
      unauthenticatedClientAction: 'Return401'
    }
    login: {
      tokenStore: {
        enabled: true
      }
    }
    identityProviders: {
      azureActiveDirectory: {
        enabled: true
        registration: {
          clientId: appRegistrationClientId
          clientSecretSettingName: 'MICROSOFT_PROVIDER_AUTHENTICATION_SECRET'
          openIdIssuer: 'https://sts.windows.net/${tenantId}/v2.0'
        }
      }
    }
  }
}


resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: applicationInsightName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Request_Source: 'rest'
  }
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-08-01' = {
  name: storageAccountName
  location: location
  kind: 'StorageV2'
  sku: {
    name: storageAccountType
  }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentityStorageAccount.id}': {}
    }
  }
  properties: {
    encryption: {
      identity: {
        userAssignedIdentity: managedIdentityStorageAccount.id
      }
      keyvaultproperties: {
        keyvaulturi: kv.properties.vaultUri
        keyname: storageAccountEncryptionKey.name

      }
      services: {
        blob: {
          keyType: 'Account'
          enabled: true
        }
        file: {
          keyType: 'Account'
          enabled: true
        }
      }
      keySource: 'Microsoft.Keyvault'
    }
    keyPolicy: {
      keyExpirationPeriodInDays: 7
    }
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    allowBlobPublicAccess: false
    allowSharedKeyAccess: false
    allowCrossTenantReplication: false
    defaultToOAuthAuthentication: false
    isHnsEnabled: false
    isSftpEnabled: false
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
      virtualNetworkRules: [
        {
          id: resourceId(resourceGroup().name, 'Microsoft.Network/virtualNetworks/subnets', vnetName, snetFunctionName)
          action: 'Allow'
        }
      ]
      resourceAccessRules: []
    }
  }
  dependsOn: [
    storageCryptoRoleAssignment
  ]
}

resource managedIdentityKv 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'mi-kvSecret-ReadWrite'
  location: location
}

resource keyVaultWFunctionAppUser 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid('SecretsUser', functionAppName, subscription().subscriptionId, uniqueString(resourceGroup().id))
  scope: kv
  properties: {
    principalType: 'ServicePrincipal'
    principalId: managedIdentityKv.properties.principalId
    roleDefinitionId: keyVaultSecretsUserRole
  }
}

resource managedIdentityStorageAccount 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: 'mi-kvKey-reader-acc'
  location: location
}

resource storageCryptoRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid('KeyReader', storageAccountName, subscription().subscriptionId, uniqueString(resourceGroup().id))
  scope: kv
  properties: {
    principalType: 'ServicePrincipal'
    roleDefinitionId: keyVaultCryptoOfficer
    principalId: managedIdentityStorageAccount.properties.principalId

  }
}

resource storageAccountEncryptionKey 'Microsoft.KeyVault/vaults/keys@2023-07-01' = {
  name: 'key-storage-account-encryption'
  parent: kv
  properties: {
    kty: 'RSA'
    keySize: 4096
    attributes: {
      enabled: true
    }
    keyOps: [
      'decrypt'
      'encrypt'
      'unwrapKey'
      'wrapKey'
      'sign'
      'verify'
    ]
  }
  dependsOn: [
    //##[error]KeyVaultAuthenticationFailure: The operation failed because of authentication issue on the keyvault. For more information, see - https://aka.ms/storagekeyvaultaccesspolicy
    // set dependency here so that the role assignment MUST be completed before the key is created and after that encryptST scope is created.
    storageCryptoRoleAssignment
  ]
}
