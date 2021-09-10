// Virtual Network Params
param vnetName string
param vnetPrefix string
param aksSubnetName string
param aksSubnetPrefix string
param ingressSubnetName string
param ingressSubnetPrefix string
param appgwSubnetName string
param appgwSubnetPrefix string

// ACR Params
param acrName string

// KeyVault Params
param keyVaultName string

// General Params
param objectId string

module spokeNetworkModule './Network/network-deploy.bicep' = {

  name: 'networkDeploy'
  params:{

    vnetName: vnetName
    vnetPrefix: vnetPrefix
    aksSubnetName: aksSubnetName
    aksSubnetPrefix: aksSubnetPrefix
    ingressSubnetName: ingressSubnetName
    ingressSubnetPrefix: ingressSubnetPrefix
    appgwSubnetName: appgwSubnetName
    appgwSubnetPrefix: appgwSubnetPrefix

  }
}

output vnetId string = spokeNetworkModule.outputs.vnetId
output subnetId string = spokeNetworkModule.outputs.aksSubnetId
output apgwSubnetId string = spokeNetworkModule.outputs.apgwSubnetId

module acrModule './ACR/acr-deploy.bicep' = {

  name: 'acrDeploy'
  params:{

    acrName: acrName
  }
}

output acrId string = acrModule.outputs.acrId
output acrLogInServer string = acrModule.outputs.acrLoginServer


module keyVaultModule './KeyVault/Keyvault-deploy.bicep' = {

  name: 'keyVaultDeploy'
  params:{

    keyVaultName: keyVaultName
    objectId: objectId
  }
}

output keyVaultId string = keyVaultModule.outputs.keyVaultId

