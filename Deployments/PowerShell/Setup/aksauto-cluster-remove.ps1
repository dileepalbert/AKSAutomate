param([Parameter(Mandatory=$true)]  [string] $shouldRemoveAll = "false",
      [Parameter(Mandatory=$false)] [string] $resourceGroup = "aks-workshop-rg",        
      [Parameter(Mandatory=$false)] [string] $clusterName = "aks-workshop-cluster",      
      [Parameter(Mandatory=$false)] [string] $acrName = "akswkshpacr",
      [Parameter(Mandatory=$false)] [string] $keyVaultName = "aks-workshop-kv",
      [Parameter(Mandatory=$false)] [string] $aksVNetName = "aks-workshop-vnet",
      [Parameter(Mandatory=$false)] [string] $appGwName = "aks-workshop-appgw",        
      [Parameter(Mandatory=$false)] [string] $subscriptionId = "<subscription-Id>")

$aksSPName = $clusterName + "-sp"
$publicIpAddressName = "$appgwName-pip"
$subscriptionCommand = "az account set -s $subscriptionId"

# Assuming Logged in (Azure CLI and PowerShell)

# PS Select Subscriotion 
Select-AzSubscription -SubscriptionId $subscriptionId

# CLI Select Subscriotion 
Invoke-Expression -Command $subscriptionCommand

az aks delete --name $clusterName --resource-group $resourceGroup --yes

if ($shouldRemoveAll -eq "true")
{

        Remove-AzApplicationGateway -Name $appGwName `
        -ResourceGroupName $resourceGroup -Force

        Remove-AzPublicIpAddress -Name $publicIpAddressName `
        -ResourceGroupName $resourceGroup -Force

        Remove-AzVirtualNetwork -Name $aksVNetName `
        -ResourceGroupName $resourceGroup -Force

        Remove-AzContainerRegistry -Name $acrName `
        -ResourceGroupName $resourceGroup

        Remove-AzKeyVault -VaultName $keyVaultName `
        -Force

        $spDeleteCommand = "az ad sp delete --id http://$aksSPName"
        Invoke-Expression -Command $spDeleteCommand
               
}

Write-Host "-----------Remove------------"