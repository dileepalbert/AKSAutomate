@minLength(5)
@maxLength(50)
param acrName string
param acrAdminUserEnabled bool = true
param location string = resourceGroup().location

@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param acrSku string = 'Standard'

resource acrDeploy 'Microsoft.ContainerRegistry/registries@2020-11-01-preview' = {

  name: acrName
  location: location
  tags: {
    displayName: 'Container Registry'
    'container.registry': acrName
  }
  sku: {
    name: acrSku
  }
  properties: {
    adminUserEnabled: acrAdminUserEnabled
  }
}

var acrReeslourceId = acrDeploy.id
output acrLoginServer string = reference(acrReeslourceId, '2020-11-01-preview').loginServer
output acrId string = acrDeploy.id
