param vnetName string
param vnetPrefix string
param subnetsList array
param location string = resourceGroup().location

resource vnet 'Microsoft.Network/virtualNetworks@2018-10-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetPrefix
      ]
    }
  }
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2018-10-01' = [for subnetRef in subnetsList: {
  parent: vnet
  name: subnetRef.name
  properties: {
    addressPrefix: subnetRef.prefix
  }
  dependsOn: [
    vnet
  ]
}]

output vnetId string = vnet.id
