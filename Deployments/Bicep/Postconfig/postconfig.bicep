param zoneName string
param zoneResourceGroup string
param aRecordName string
param aRecordsArray array = []
param vnetName string = ''
param vnetResourceGroup string = ''
param ttl int
param location string = 'global'

param appgwName string = guid(resourceGroup().id)
param appgwResourceGroup string
param appgwVnetName string
param appgwSubnetName string
param httpsListenerNames array = []
param backendIpAddress string = ''

module privateDNSZoneModule '../Modules/Network/private-dns-zone-deploy.bicep' = {
  name: 'privateDNSZoneDeploy'
  scope: resourceGroup(zoneResourceGroup)
  params:{
    zoneName: zoneName
    aRecordName: aRecordName
    aRecordsArray: aRecordsArray
    vnetName: vnetName
    vnetResourceGroup: vnetResourceGroup
    ttl: ttl
    location: location
  }
}

output privateDNSZoneId string = privateDNSZoneModule.outputs.pvtDNSZoneId

module applicationGatewayModule '../Modules/AppGW/appgw-deploy.bicep' = {
  name: 'applicationGatewayDeploy'
  scope: resourceGroup(appgwResourceGroup)
  params:{
    applicationGatewayName: appgwName
    vnetName: appgwVnetName
    subnetName: appgwSubnetName
    httpsListenerNames: httpsListenerNames
    backendIpAddress: backendIpAddress
  }
}

output appliicationGatewayId string = applicationGatewayModule.outputs.applicationGatewayId

