param([Parameter(Mandatory=$true)]  [string] $isUdrCluster,
      [Parameter(Mandatory=$true)]  [string] $e2eSSL,
      [Parameter(Mandatory=$true)]  [string] $resourceGroup,
      [Parameter(Mandatory=$true)]  [string] $masterResourceGroup,
      [Parameter(Mandatory=$false)] [string] $fwResourceGroup = $masterResourceGroup,
      [Parameter(Mandatory=$false)] [string] $fwName,
      [Parameter(Mandatory=$true)]  [string] $location,      
      [Parameter(Mandatory=$true)]  [array]  $namespaces,
      [Parameter(Mandatory=$true)]  [string] $clusterName,
      [Parameter(Mandatory=$true)]  [string] $acrName,
      [Parameter(Mandatory=$true)]  [string] $keyVaultName,
      [Parameter(Mandatory=$true)]  [string] $masterVNetName,
      [Parameter(Mandatory=$true)]  [string] $aksVNetName,
      [Parameter(Mandatory=$true)]  [string] $ingressSubnetName,
      [Parameter(Mandatory=$true)]  [string] $ingressNodePoolName,
      [Parameter(Mandatory=$true)]  [string] $appgwName,
      [Parameter(Mandatory=$true)]  [string] $appgwSubnetName,            
      [Parameter(Mandatory=$false)] [string] $fwPostConfigFileName,
      [Parameter(Mandatory=$true)]  [string] $ingressControllerIPAddress,
      [Parameter(Mandatory=$true)]  [string] $subscriptionId = "<subscriptionId>",
      [Parameter(Mandatory=$true)]  [string] $baseFolderPath = "<baseFolderPath>")

$setupFolderPath = "$baseFolderPath/Bicep/Setup"
$ingControllerName = $clusterName + "-ing"
$ingControllerNSName = $ingControllerName + "-ns"
$ingControllerFileName = "internal-ingress"
$ingControllerFilePath = "$setupFolderPath/Common/$ingControllerFileName.yaml"
$appgwUDRName = $appgwSubnetName + "-rt"

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
