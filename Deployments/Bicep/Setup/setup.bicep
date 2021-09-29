param clusterName string
param location string
param kubernetesVersion string
param vmSize string
param osType string
param osSKU string
param vmType string
param vnetName string
param aksSubnetName string
param nodePoolMode string
param nodePoolName string
param nodeResourceGroup string
param logWorkspaceId string
param serviceCidr string
param dnsServiceIP string
param clientId string
param clientSecret string
param privateDNSZoneId string
param loadBalancerType string = 'loadBalancer'
param aadTenantId string
param adminGroupObjectIDs array
param sysNodeCount int
param maxPods int
param maxCount int
param minCount int
param enableAutoScaling bool
param enablePrivateCluster bool

resource spokeVnetModule 'Microsoft.Network/virtualNetworks@2021-02-01' existing = {
  name: vnetName  
}

resource spokeAKSSubnetModule 'Microsoft.Network/virtualNetworks/subnets@2021-02-01' existing = {
  parent: spokeVnetModule
  name: aksSubnetName
}

resource aksk8sClusterModule 'Microsoft.ContainerService/managedClusters@2021-05-01' = {
  name: clusterName
  location: location  
  properties: {
    kubernetesVersion: kubernetesVersion
    dnsPrefix: clusterName    
    agentPoolProfiles: [
      {
        count: sysNodeCount
        vmSize: vmSize
        vnetSubnetID: spokeAKSSubnetModule.id
        maxPods: maxPods
        osType: osType
        osSKU: osSKU
        maxCount: maxCount
        minCount: minCount
        enableAutoScaling: enableAutoScaling
        type: vmType
        mode: nodePoolMode                                                                   
        name: nodePoolName
      }
    ]       
    servicePrincipalProfile: {
      clientId: clientId
      secret: clientSecret
    }
    addonProfiles:{
      omsagent: {
        enabled: true
        config: {
          logAnalyticsWorkspaceResourceID: logWorkspaceId
        }
      }
    }
    nodeResourceGroup: nodeResourceGroup
    enableRBAC: true    
    networkProfile: {
      networkPlugin: 'azure'
      networkPolicy: 'azure'            
      serviceCidr: serviceCidr
      dnsServiceIP: dnsServiceIP      
      outboundType: loadBalancerType   
    }    
    aadProfile: {
      managed: true
      enableAzureRBAC: false
      adminGroupObjectIDs: adminGroupObjectIDs    
      tenantID: aadTenantId
    }
    apiServerAccessProfile:{    
      enablePrivateCluster: enablePrivateCluster
      privateDNSZone: privateDNSZoneId
    }    
  }    
}
