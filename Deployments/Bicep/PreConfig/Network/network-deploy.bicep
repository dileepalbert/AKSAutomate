param vnetName string
param vnetPrefix string
param aksSubnetName string
param aksSubnetPrefix string
param ingressSubnetName string
param ingressSubnetPrefix string
param appgwSubnetName string
param appgwSubnetPrefix string
param location string = resourceGroup().location

resource spokeVnetDeploy 'Microsoft.Network/virtualNetworks@2021-02-01' = {

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

resource aksSubnetDeploy 'Microsoft.Network/virtualNetworks/subnets@2021-02-01' = {

  parent: spokeVnetDeploy
  name: aksSubnetName
  properties: {
    addressPrefix: aksSubnetPrefix
  }
  dependsOn:[
    
    spokeVnetDeploy
  ]
}

resource ingressSubnetDeploy 'Microsoft.Network/virtualNetworks/subnets@2021-02-01' = {
  
  parent: spokeVnetDeploy
  name: ingressSubnetName
  properties: {
    addressPrefix: ingressSubnetPrefix
  }
  dependsOn: [

    aksSubnetDeploy
  ]
}

resource appgwSubnetDeploy 'Microsoft.Network/virtualNetworks/subnets@2021-02-01' = {
  
  parent: spokeVnetDeploy
  name: appgwSubnetName
  properties: {
    addressPrefix: appgwSubnetPrefix
  }
  dependsOn: [

    ingressSubnetDeploy
  ]
}

output vnetId string = spokeVnetDeploy.id
output aksSubnetId string = aksSubnetDeploy.id
output ingressSubnetId string = ingressSubnetDeploy.id
output apgwSubnetId string = appgwSubnetDeploy.id
