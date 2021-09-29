// Virtual Network Params
param vnetName string
param vnetPrefix string
param subnetsList array = []
param logWorkspaceInfo object = {
  lwRGName: ''
  location:''
  lwName: ''
  lwSku: ''
  lwRetention: 0
  dailyQuotaGb: 0

}

// ACR Params
param acrName string

// KeyVault Params
param keyVaultName string

// General Params
param objectId string

module logWorkspaceModule '../Modules/LogWorkspace/logworkspace-deploy.bicep' = {
  name: 'logWorkspaceDeploy'
  scope: resourceGroup(logWorkspaceInfo.lwRGName)
  params:{
    logWorkspaceInfo: logWorkspaceInfo
  }
}

module spokeNetworkModule '../Modules/Network/network-deploy.bicep' = {
  name: 'spokeNetworkDeploy'
  params:{
    vnetName: vnetName
    vnetPrefix: vnetPrefix
    subnetsList: subnetsList
  }
}

output vnetId string = spokeNetworkModule.outputs.vnetId

module acrModule '../Modules/ACR/acr-deploy.bicep' = {
  name: 'acrDeploy'
  params:{
    acrName: acrName
  }
}

output acrId string = acrModule.outputs.acrId
output acrLogInServer string = acrModule.outputs.acrLoginServer

module keyVaultModule '../Modules/KeyVault/Keyvault-deploy.bicep' = {
  name: 'keyVaultDeploy'
  params:{
    keyVaultName: keyVaultName
    objectId: objectId
  }
}

output keyVaultId string = keyVaultModule.outputs.keyVaultId

