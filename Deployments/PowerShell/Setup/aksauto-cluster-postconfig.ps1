param([Parameter(Mandatory=$true)]  [string] $isUdrCluster,
      [Parameter(Mandatory=$true)]  [string] $e2eSSL,
      [Parameter(Mandatory=$true)]  [string] $resourceGroup = "aks-workshop-rg",
      [Parameter(Mandatory=$true)]  [string] $masterResourceGroup = "master-workshop-rg",
      [Parameter(Mandatory=$false)] [string] $fwResourceGroup = $masterResourceGroup,
      [Parameter(Mandatory=$false)] [string] $fwName = "master-hub-workshop-fw",
      [Parameter(Mandatory=$true)]  [string] $location = "eastus",
      [Parameter(Mandatory=$true)]  [array]  $httpsListeners = @("dev", "qa", "smoke"),
      [Parameter(Mandatory=$false)] [array]  $httpListeners = @("dev", "qa"),
      [Parameter(Mandatory=$true)]  [array]  $namespaces = @("aks-workshop-dev", "aks-workshop-qa", "smoke"),
      [Parameter(Mandatory=$true)]  [string] $clusterName = "aks-workshop-cluster",
      [Parameter(Mandatory=$true)]  [string] $acrName = "akswkshpacr",
      [Parameter(Mandatory=$true)]  [string] $keyVaultName = "aks-workshop-kv",      
      [Parameter(Mandatory=$true)]  [string] $masterVNetName = "master-workshop-vnet",
      [Parameter(Mandatory=$true)]  [string] $aksVNetName = "aks-workshop-vnet",
      [Parameter(Mandatory=$true)]  [string] $ingressSubnetName = "aks-workshop-ing-subnet",
      [Parameter(Mandatory=$true)]  [string] $ingressNodePoolName = "akssyspool",
      [Parameter(Mandatory=$true)]  [string] $appgwName = "aks-workshop-appgw",
      [Parameter(Mandatory=$true)]  [string] $appgwSubnetName = "aks-workshop-appgw-subnet",
      [Parameter(Mandatory=$true)]  [string] $appgwTemplateFileName = "aksauto-appgw-deploy",
      [Parameter(Mandatory=$true)]  [string] $appgwConfigFileName = "aksauto-config-appgw",
      [Parameter(Mandatory=$false)] [string] $fwPostConfigFileName = "aksauto-firewall-post-config",
      [Parameter(Mandatory=$true)]  [string] $ingressControllerIPAddress = "12.0.5.100",
      [Parameter(Mandatory=$true)]  [string] $ingressHostName = "<ingressHostName>",
      [Parameter(Mandatory=$true)]  [string] $listenerHostName = "<listenerHostName>",
      [Parameter(Mandatory=$true)]  [string] $healthProbeHostName = "<healthProbeHostName>",
      [Parameter(Mandatory=$true)]  [string] $healthProbePath = "<healthProbePath>",
      [Parameter(Mandatory=$true)]  [string] $subscriptionId = "<subscriptionId>",
      [Parameter(Mandatory=$true)]  [string] $baseFolderPath = "<baseFolderPath>")

$setupFolderPath = "$baseFolderPath/PowerShell/Setup"
$securityFolderPath = "$setupFolderPath/Security"
$ingControllerName = $clusterName + "-ing"
$ingControllerNSName = $ingControllerName + "-ns"
$ingControllerFileName = "internal-ingress"
$ingControllerFilePath = "$setupFolderPath/Common/$ingControllerFileName.yaml"
$masterVnetLinkName = "$masterVNetName-dns-plink"
$aksVnetLinkName = "$aksVNetName-dns-plink"
$appgwUDRName = $appgwSubnetName + "-rt"

# Creating Private DNS Zone
$privateDNSZone = Get-AzPrivateDnsZone -ResourceGroupName $masterResourceGroup `
-Name $ingressHostName
if (!$privateDNSZone)
{

      $privateDNSZone = New-AzPrivateDnsZone -ResourceGroupName $masterResourceGroup `
      -Name $ingressHostName 
      if (!$privateDNSZone)
      {

            Write-Host "Error creating Private DNS Zone"
            return;

      }
}

# Add Record Sets in Private DNS Zone
foreach ($httpsListener in $httpsListeners)
{
            
      $recordSet = Get-AzPrivateDnsRecordSet -Zone $privateDNSZone `
      -Name $httpsListener -RecordType A
      if (!$recordSet)
      {

            $recordConfigsList = New-AzPrivateDnsRecordConfig `
            -IPv4Address $ingressControllerIPAddress

            New-AzPrivateDnsRecordSet -Name $httpsListener -RecordType A `
            -ResourceGroupName $masterResourceGroup -TTL 3600 `
            -ZoneName $ingressHostName `
            -PrivateDnsRecords $recordConfigsList
            
      }
}

# Link Master VNET to Private DNS Zone
$masterVNetLink = Get-AzPrivateDnsVirtualNetworkLink -ZoneName $ingressHostName `
-ResourceGroupName $masterResourceGroup -Name $masterVnetLinkName
if (!$masterVNetLink)
{

      $masterVnet = Get-AzVirtualNetwork -Name $masterVNetName `
      -ResourceGroupName $masterResourceGroup
      if ($masterVnet)
      {

            New-AzPrivateDnsVirtualNetworkLink -ZoneName $ingressHostName `
            -ResourceGroupName $masterResourceGroup -Name $masterVnetLinkName `
            -VirtualNetworkId $masterVnet.Id

      }

}

# Link AKS VNET to Private DNS Zone
$aksVNetLink = Get-AzPrivateDnsVirtualNetworkLink -ZoneName $ingressHostName `
-ResourceGroupName $masterResourceGroup -Name $aksVnetLinkName
if (!$aksVNetLink)
{

      $aksVnet = Get-AzVirtualNetwork -Name $aksVNetName `
      -ResourceGroupName $resourceGroup
      if ($aksVnet)
      {

            New-AzPrivateDnsVirtualNetworkLink -ZoneName $ingressHostName `
            -ResourceGroupName $masterResourceGroup -Name $aksVnetLinkName `
            -VirtualNetworkId $aksVnet.Id

      }

}

# Switch Cluster context
$kbctlContextCommand = "az aks get-credentials --resource-group $resourceGroup --name $clusterName --overwrite-existing --admin"
Invoke-Expression -Command $kbctlContextCommand

# Create enviorment specific Namespaces
foreach ($namepaceName in $namespaces)
{
            
      $createNSCommand = "kubectl create namespace $namepaceName"
      Invoke-Expression -Command $createNSCommand

      $labelNSCommand = "kubectl label namespace $namepaceName name=$namepaceName"
      Invoke-Expression -Command $labelNSCommand

}

# Create nginx Namespace
$nginxNSCommand = "kubectl create namespace $ingControllerNSName"
Invoke-Expression -Command $nginxNSCommand

$labelNSCommand = "kubectl label namespace $ingControllerNSName name=$ingControllerNSName"
Invoke-Expression -Command $labelNSCommand

# Install nginx as ILB using Helm
$nginxRepoAddCommand = "helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx"
Invoke-Expression -Command $nginxRepoAddCommand

$nginxRepoUpdateCommand = "helm repo update"
Invoke-Expression -Command $nginxRepoUpdateCommand

$nginxConfigCommand = "--set controller.service.loadBalancerIP=$ingressControllerIPAddress --set controller.nodeSelector.agentpool=$ingressNodePoolName --set controller.defaultBackend.nodeSelector.agentpool=$ingressNodePoolName --set controller.service.annotations.'service\.beta\.kubernetes\.io/azure-load-balancer-internal-subnet'=$ingressSubnetName"
$nginxILBCommand = "helm install $ingControllerName ingress-nginx/ingress-nginx --namespace $ingControllerNSName -f $ingControllerFilePath $nginxConfigCommand"
Invoke-Expression -Command $nginxILBCommand

$processedHttpsListeners = @()
foreach ($listener in $httpsListeners)
{
      $processedHttpsListeners += "'$listener'"
}
$processedHttpsListeners = $processedHttpsListeners -join ","

$processedHttpListeners = @()
foreach ($listener in $httpListeners)
{
      $processedHttpListeners += "'$listener'"
}
$processedHttpListeners = $processedHttpListeners -join ","
$ingressHostName = "." + $ingressHostName
$listenerHostName = "." + $listenerHostName

$appgwParameters = "-e2eSSL $e2eSSL -httpListeners @($processedHttpListeners) -httpsListeners @($processedHttpsListeners) -appgwVNetName $aksVNetName -appgwSubnetName $appgwSubnetName -appgwTemplateFileName $appgwTemplateFileName -backendIpAddress $ingressControllerIPAddress -backendPoolHostName $ingressHostName -listenerHostName $listenerHostName -healthProbeHostName $healthProbeHostName -healthProbePath $healthProbePath"
$appgwDeployCommand = "/$appgwConfigFileName.ps1 -resourceGroup $resourceGroup -appgwName $appgwName -baseFolderPath $baseFolderPath -keyVaultName $keyVaultName $appgwParameters"
$appgwDeployPath = $securityFolderPath + $appgwDeployCommand
Invoke-Expression -Command $appgwDeployPath

if ($isUdrCluster -eq "true")
{

      $appgwPublicIPInfo = Get-AzPublicIpAddress -Name "$appgwName-pip" `
      -ResourceGroupName $resourceGroup
      $appgwPublicIP = $appgwPublicIPInfo.IpAddress
            
      $firewall = Get-AzFirewall -Name $fwName -ResourceGroupName $fwResourceGroup
      if (!$firewall)
      {

            Write-Host "Error fetching Azure Firewall instance"
            return;

      }

      $aksVnet = Get-AzVirtualNetwork -Name $aksVNetName `
      -ResourceGroupName $resourceGroup
      if (!$aksVnet)
      {
            
            Write-Host "Error fetching Vnet info"
            return;

      }

      $appgwSubnet = Get-AzVirtualNetworkSubnetConfig -Name $appgwSubnetName `
      -VirtualNetwork $aksVnet
      if (!$appgwSubnet)
      {
            
            Write-Host "Error fetching AKS Subnet info"
            return;

      }

      $fwPrivateIP = $firewall.IpConfigurations[0].PrivateIPAddress
      $apiServerCommand = "kubectl get endpoints -n default -o json"
      $apiServerInfo = Invoke-Expression -Command $apiServerCommand
      $apiServerInfoJson = $apiServerInfo | ConvertFrom-Json
      $apiServerIP = $apiServerInfoJson.items.Where{$_.metadata.name -match "kubernetes"}.subsets[0].addresses[0].ip
      
      $apiServerRulesCollection = $firewall.GetNetworkRuleCollectionByName($apiServerRulesCollectionName)
      if ($apiServerRulesCollection)
      {
            $apiServerRules = New-AzFirewallNetworkRule `
            -Name "allow-api-server" `
            -Description "allow api server" `
            -Protocol Any `
            -SourceAddress "*" `
            -DestinationAddress "$apiServerIP" `
            -DestinationPort "443"

            $apiServerRulesCollection.AddRule($apiServerRules)
            Set-AzFirewall -AzureFirewall $firewall

      }

      $appgwRouteInfo = Get-AzRouteTable -Name $appgwUDRName `
      -ResourceGroupName $resourceGroup
      if (!$appgwRouteInfo)
      {
      
            $appgwRouteInfo = New-AzRouteTable -Name $appgwUDRName `
            -ResourceGroupName $resourceGroup -Location $location
      
      }
      $rtDefaultRouteInfo = $appgwRouteInfo.Routes.Where{$_.Name -match "$appgwUDRName-default"}
      if (!$rtDefaultRouteInfo)
      {
      
            $rtDefaultRouteInfo = New-AzRouteConfig -Name "$appgwUDRName-default" `
            -AddressPrefix "$appgwPublicIP/32" -NextHopType VirtualAppliance `
            -NextHopIpAddress "$fwPrivateIP"
      
            $appgwRouteInfo.Routes.Add($rtDefaultRouteInfo)
      
      }

      Set-AzRouteTable -RouteTable $appgwRouteInfo

}

Write-Host "-----------Post-Config------------"
