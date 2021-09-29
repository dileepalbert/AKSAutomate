param([Parameter(Mandatory=$true)] [string] $fwResourceGroup = "master-workshop-rg",
      [Parameter(Mandatory=$true)] [string] $vnetResourceGroup = "aks-wkshpprv-rg",
      [Parameter(Mandatory=$true)] [string] $location = "eastus",
      [Parameter(Mandatory=$true)] [string] $fwName = "master-hub-workshop-fw",
      [Parameter(Mandatory=$true)] [string] $aksVNetName = "aks-wkshpprv-vnet",
      [Parameter(Mandatory=$true)] [string] $aksSubnetName = "aks-wkshpprv-subnet",
      [Parameter(Mandatory=$true)] [string] $aksSPDisplayName = "aks-wkshpprv-cluster-sp")

$aksSP = Get-AzADServicePrincipal -DisplayName $aksSPDisplayName
$aksVnet = Get-AzVirtualNetwork -Name $aksVNetName -ResourceGroupName $vnetResourceGroup
$fwPipInfo = Get-AzPublicIpAddress -Name $fwName-pip -ResourceGroupName $fwResourceGroup
$fwPublicIP = $fwPipInfo.IpAddress

$firewall = Get-AzFirewall -Name $fwName -ResourceGroupName $fwResourceGroup
$fwPrivateIP = $firewall.IpConfigurations[0].PrivateIPAddress

$routeTableName = "$aksSubnetName-rt"
$rtInfo = Get-AzRouteTable -Name $routeTableName -ResourceGroupName $vnetResourceGroup
if (!$rtInfo)
{

      $rtInfo = New-AzRouteTable -Name $routeTableName `
      -ResourceGroupName $vnetResourceGroup -Location $location

}

$rtDefaultRouteInfo = $rtInfo.Routes.Where{$_.Name -match "$routeTableName-default"}
if (!$rtDefaultRouteInfo)
{

      $rtDefaultRouteInfo = New-AzRouteConfig -Name "$routeTableName-default" `
      -AddressPrefix "0.0.0.0/0" -NextHopType VirtualAppliance `
      -NextHopIpAddress "$fwPrivateIP"

      $rtInfo.Routes.Add($rtDefaultRouteInfo)

}

$rtInternetRouteInfo = $rtInfo.Routes.Where{$_.Name -match "$routeTableName-internet"}
if (!$rtInternetRouteInfo)
{

      $rtInternetRouteInfo = New-AzRouteConfig -Name "$routeTableName-internet" `
      -AddressPrefix "$fwPublicIP/32" -NextHopType Internet

      $rtInfo.Routes.Add($rtInternetRouteInfo)

}

Set-AzRouteTable -RouteTable $rtInfo

$aksSubnetInfo = Get-AzVirtualNetworkSubnetConfig -Name $aksSubnetName `
-VirtualNetwork $aksVnet
if ($aksSubnetInfo)
{

      $aksSubnetInfo.RouteTable = $rtInfo

      Set-AzVirtualNetworkSubnetConfig -Name $aksSubnetName `
      -VirtualNetwork $aksVnet -AddressPrefix $aksSubnetInfo.AddressPrefix `
      -RouteTable $aksSubnetInfo.RouteTable

      Set-AzVirtualNetwork -VirtualNetwork $aksVnet

}

New-AzRoleAssignment -RoleDefinitionName "Network Contributor" `
-Scope $rtInfo.Id -ApplicationId $aksSP.ApplicationId