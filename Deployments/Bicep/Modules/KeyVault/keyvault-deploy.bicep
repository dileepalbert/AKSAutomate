param keyVaultName string
param objectId string
param location string = resourceGroup().location

@allowed([
  true
  false
])
param enabledForDeployment bool = false

@allowed([
  true
  false
])
param enabledForDiskEncryption bool = false

@allowed([
  true
  false
])
param enabledForTemplateDeployment bool = true
param tenantId string = subscription().tenantId
param keysPermissions array = [
  'get'
  'list'
  'create'
  'delete'
  'update'
]
param secretsPermissions array = [
  'get'
  'list'
  'set'
  'delete'
]
param certificatesPermissions array = [
  'get'
  'list'
  'create'
  'delete'
  'update'
]

@allowed([
  'standard'
  'premium'
])
param skuName string = 'standard'

resource keyVaultDeploy 'Microsoft.KeyVault/vaults@2021-04-01-preview' = {
  
  name: keyVaultName
  location: location
  properties: {
    enabledForDeployment: enabledForDeployment
    enabledForDiskEncryption: enabledForDiskEncryption
    enabledForTemplateDeployment: enabledForTemplateDeployment
    tenantId: tenantId
    accessPolicies: [
      {
        objectId: objectId
        tenantId: tenantId
        permissions: {
          keys: keysPermissions
          secrets: secretsPermissions
          certificates: certificatesPermissions
        }
      }
    ]
    sku: {
      name: skuName
      family: 'A'
    }
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
  }
}

output keyVaultId string = keyVaultDeploy.id
