param logWorkspaceInfo object = {
  lwRGName: ''
  location: ''
  lwName: ''
  lwSku: ''
  lwRetention: 0
  dailyQuotaGb: 0
}

resource lwDeploy 'Microsoft.OperationalInsights/workspaces@2020-08-01' = {
  name: logWorkspaceInfo.lwName
  location: logWorkspaceInfo.location
  properties: {
    sku: {
      name: logWorkspaceInfo.lwSku      
    }
    retentionInDays: int(logWorkspaceInfo.lwRetention)
    workspaceCapping: {
      dailyQuotaGb: int(logWorkspaceInfo.dailyQuotaGb)
    }    
  }
}
