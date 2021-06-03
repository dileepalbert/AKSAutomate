param([Parameter(Mandatory=$true)]  [string] $shouldRemoveAll = "false",
      [Parameter(Mandatory=$false)] [string] $resourceGroup = "aks-workshop-rg",
      [Parameter(Mandatory=$false)] [string] $lwResourceGroup = "monitoring-workshop-rg",
      [Parameter(Mandatory=$false)] [string] $masterResourceGroup = "master-workshop-rg",      
      [Parameter(Mandatory=$false)] [string] $clusterName = "aks-workshop-cluster",
      [Parameter(Mandatory=$false)] [string] $acrName = "akswkshpacr",
      [Parameter(Mandatory=$false)] [string] $keyVaultName = "aks-workshop-kv",
      [Parameter(Mandatory=$false)] [string] $appGwName = "aks-workshop-appgw",
      [Parameter(Mandatory=$false)] [string] $logworkspaceName = "aks-workshop-lw",
      [Parameter(Mandatory=$false)] [string] $masterVNetName = "master-workshop-vnet",
      [Parameter(Mandatory=$false)] [string] $aksVNetName = "aks-workshop-vnet",
      [Parameter(Mandatory=$false)] [string] $ingressHostName = "<ingressHostName>",
      [Parameter(Mandatory=$false)] [string] $baseFolderPath = "<baseFolderPath>")

$aksSPName = $clusterName + "-sp"
$subscriptionCommand = "az account set -s $subscriptionId"
$publicIpAddressName = "$appgwName-pip"
$masterAKSPeeringName = "$masterVNetName-$aksVNetName-peering";
$aksMasterPeeringName = "$aksVNetName-$masterVNetName-peering";
$masterVnetLinkName = "$masterVNetName-dns-plink"
$aksVnetLinkName = "$aksVNetName-dns-plink"

# PS Select Subscriotion 
Select-AzSubscription -SubscriptionId $subscriptionId

# CLI Select Subscriotion 
Invoke-Expression -Command $subscriptionCommand

az aks delete --name $clusterName --resource-group $resourceGroup --yes

$LASTEXITCODE
if (!$?)
{

      Write-Host "Error Deleting cluster $clusterName"
      return;
}

if ($shouldRemoveAll -eq "false")
{

      Write-Host "Cluster $clusterName Deleted"
      return;

}

$appgw = Get-AzApplicationGateway -Name $appGwName `
-ResourceGroupName $resourceGroup
if ($appgw)
{

      Remove-AzApplicationGateway -Name $appGwName `
      -ResourceGroupName $resourceGroup -Force

      $appgwPIP = Get-AzPublicIpAddress -Name $publicIpAddressName `
      -ResourceGroupName $resourceGroup
      if ($appgwPIP)
      {

            Remove-AzPublicIpAddress -Name $publicIpAddressName `
            -ResourceGroupName $resourceGroup -Force

      }
}

$masterAKSPeering = Get-AzVirtualNetworkPeering -VirtualNetworkName $masterVNetName `
-ResourceGroupName $masterResourceGroup -Name $masterAKSPeeringName
if ($masterAKSPeering)
{

      Remove-AzVirtualNetworkPeering -VirtualNetworkName $masterVNetName `
      -ResourceGroupName $masterResourceGroup -Name $masterAKSPeeringName -Force

}

$aksMasterPeering = Get-AzVirtualNetworkPeering -VirtualNetworkName $aksVNetName `
-ResourceGroupName $resourceGroup -Name $aksMasterPeeringName
if ($aksMasterPeering)
{

      Remove-AzVirtualNetworkPeering -VirtualNetworkName $aksVNetName `
      -ResourceGroupName $resourceGroup -Name $aksMasterPeeringName -Force

}

$aksDNSZone = Get-AzPrivateDnsZone -ResourceGroupName $masterResourceGroup `
-Name $ingressHostName
if ($aksDNSZone)
{

      $masterDNSLink = Get-AzPrivateDnsVirtualNetworkLink -Name $masterVnetLinkName `
      -ResourceGroupName $masterResourceGroup -ZoneName $ingressHostName       
      if ($masterDNSLink)
      {

            Remove-AzPrivateDnsVirtualNetworkLink -Name $masterVnetLinkName `
            -ResourceGroupName $masterResourceGroup -ZoneName $ingressHostName

      }

      $aksDNSLink = Get-AzPrivateDnsVirtualNetworkLink `
      -ResourceGroupName $masterResourceGroup -ZoneName $ingressHostName `
      -Name $aksVnetLinkName
      if ($aksDNSLink)
      {

            Remove-AzPrivateDnsVirtualNetworkLink -Name $aksVnetLinkName `
            -ResourceGroupName $masterResourceGroup -ZoneName $ingressHostName

      }
      
      Remove-AzPrivateDnsZone -ResourceGroupName $masterResourceGroup `
      -Name $ingressHostName

}

$aksVnet = Get-AzVirtualNetwork -Name $aksVNetName `
-ResourceGroupName $resourceGroup
if ($aksVnet)
{

      Remove-AzVirtualNetwork -Name $aksVNetName `
      -ResourceGroupName $resourceGroup -Force

}

$acrInfo = Get-AzContainerRegistry -Name $acrName `
-ResourceGroupName $resourceGroup
if ($acrInfo)
{

      Remove-AzContainerRegistry -Name $acrName `
      -ResourceGroupName $resourceGroup

}

$keyVault = Get-AzKeyVault -VaultName $keyVaultName
if ($keyVault)
{
      Remove-AzKeyVault -VaultName $keyVaultName `
      -Force
}

$omsInfo = Get-AzOperationalInsightsWorkspace -ResourceGroupName $lwResourceGroup `
-Name $logworkspaceName
if ($omsInfo)
{

      Remove-AzOperationalInsightsWorkspace -ResourceGroupName $lwResourceGroup `
      -Name $logworkspaceName -Force

}

$spInfo = Get-AzADServicePrincipal -DisplayName $aksSPName
if ($spInfo)
{

      $spId = $spInfo.ApplicationId
      $spDeleteCommand = "az ad sp delete --id $spId"
      Invoke-Expression -Command $spDeleteCommand

}

Write-Host "-----------Remove------------"