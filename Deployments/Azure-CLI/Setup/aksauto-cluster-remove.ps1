param([Parameter(Mandatory=$true)]  [string] $shouldRemoveAll = "false",
      [Parameter(Mandatory=$false)] [string] $resourceGroup = "aks-workshop-rg",
      [Parameter(Mandatory=$false)] [string] $fwResourceGroup = "master-workshop-rg",
      [Parameter(Mandatory=$false)] [string] $clusterName = "aks-workshop-cluster",
      [Parameter(Mandatory=$false)] [string] $acrName = "akswkshpacr",
      [Parameter(Mandatory=$false)] [string] $keyVaultName = "aks-workshop-kv",
      [Parameter(Mandatory=$false)] [string] $aksVNetName = "aks-workshop-vnet",
      [Parameter(Mandatory=$false)] [string] $appGwName = "aks-workshop-appgw",
      [Parameter(Mandatory=$false)] [string] $fwName = "master-hub-workshop-fw",
      [Parameter(Mandatory=$false)] [string] $subscriptionId = "6bdcc705-8db6-4029-953a-e749070e6db6")

$aksSPName = $clusterName + "-sp"
$subscriptionCommand = "az account set -s $subscriptionId"

# PS Select Subscriotion 
Select-AzSubscription -SubscriptionId $subscriptionId

# CLI Select Subscriotion 
Invoke-Expression -Command $subscriptionCommand

az aks delete --name $clusterName --resource-group $resourceGroup --yes

if ($shouldRemoveAll -eq "true")
{
        az acr delete --name $acrName --resource-group $resourceGroup --yes
        az keyvault delete --name $keyVaultName --resource-group $resourceGroup
        az network application-gateway delete --name $appGwName --resource-group $resourceGroup
        az network vnet delete --name $vnetName --resource-group $resourceGroup
        az network firewall delete --name $fwName --resource-group $fwResourceGroup
        
        $spDeleteCommand = "az ad sp delete --id http://$aksSPName"
        Invoke-Expression -Command $spDeleteCommand

}

Write-Host "-----------Remove------------"