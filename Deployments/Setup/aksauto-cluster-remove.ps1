param([Parameter(Mandatory=$false)]   [string] $resourceGroup = "aks-workshop-rg",
        [Parameter(Mandatory=$false)] [string] $projectName = "aks-workshop",
        [Parameter(Mandatory=$false)] [string] $clusterName = "aks-workshop-cluster",
        [Parameter(Mandatory=$false)] [string] $acrName = "akswkshpacr",
        [Parameter(Mandatory=$false)] [string] $keyVaultName = "aks-workshop-kv",
        [Parameter(Mandatory=$false)] [string] $aksVNetName = "aks-workshop-vnet",        
        [Parameter(Mandatory=$false)] [string] $appgwName = "aks-workshop-appgw",
        [Parameter(Mandatory=$false)] [string] $subscriptionId = "<subscriptionId>")

$aksSPIdName = $clusterName + "-sp-id"
$publicIpAddressName = "$appgwName-pip"
# $acrPrivateDnsZone = "privateLink.azurecr.io"
# $kvPrivateDnsZone = "privatelink.vaultcore.azure.net"
$subscriptionCommand = "az account set -s $subscriptionId"

# $acrAKSPepName = $projectName + "acr-aks-pep"
# $acrDevOpsPepName = $projectName + "acr-devops-pep"
# $kvDevOpsPepName = $projectName + "kv-devops-pep"
# $acrAKSVnetLinkName = $acrAKSPepName + "-link"
# $acrDevOpsVnetLinkName = $acrDevOpsPepName + "-link"
# $kvDevOpsVnetLinkName = $kvDevOpsPepName + "-link"

# PS Select Subscriotion 
Select-AzSubscription -SubscriptionId $subscriptionId

# CLI Select Subscriotion 
Invoke-Expression -Command $subscriptionCommand

az aks delete --name $clusterName --resource-group $resourceGroup --yes

Remove-AzApplicationGateway -Name $appgwName `
-ResourceGroupName $resourceGroup -Force

Remove-AzPublicIpAddress -Name $publicIpAddressName `
-ResourceGroupName $resourceGroup -Force

Remove-AzVirtualNetwork -Name $aksVNetName `
-ResourceGroupName $resourceGroup -Force

Remove-AzContainerRegistry -Name $acrName `
-ResourceGroupName $resourceGroup

$keyVault = Get-AzKeyVault -ResourceGroupName $resourceGroup `
-VaultName $keyVaultName
if ($keyVault)
{

    $spAppId = Get-AzKeyVaultSecret -VaultName $keyVaultName `
    -Name $aksSPIdName
    if ($spAppId)
    {
     
        Remove-AzADServicePrincipal `
        -ApplicationId $spAppId.SecretValueText -Force
        
    }
}

Remove-AzKeyVault -VaultName $keyVaultName `
-ResourceGroupName $resourceGroup -Force

# Remove-AzPrivateEndpoint -ResourceGroupName $resourceGroup `
# -Name $acrAKSPepName -Force

# Remove-AzPrivateEndpoint -ResourceGroupName $resourceGroup `
# -Name $acrDevOpsPepName -Force

# Remove-AzPrivateDnsVirtualNetworkLink `
# -ResourceGroupName $resourceGroup -ZoneName $acrPrivateDnsZone `
# -Name $acrAKSVnetLinkName

# Remove-AzPrivateDnsVirtualNetworkLink `
# -ResourceGroupName $resourceGroup -ZoneName $acrPrivateDnsZone `
# -Name $acrDevOpsVnetLinkName

# $dnsRecordsList = Get-AzPrivateDnsRecordSet -ResourceGroupName $resourceGroup `
# -ZoneName $acrPrivateDnsZone -RecordType "A"

# Remove-AzPrivateDnsRecordSet -RecordSet $dnsRecordsList[0]
# Remove-AzPrivateDnsRecordSet -RecordSet $dnsRecordsList[1]

# Remove-AzPrivateDnsZone -ResourceGroupName $resourceGroup `
# -Name $acrPrivateDnsZone

# Remove-AzPrivateEndpoint -ResourceGroupName $resourceGroup `
# -Name $kvDevOpsPepName -Force

# Remove-AzPrivateDnsVirtualNetworkLink `
# -ResourceGroupName $resourceGroup -ZoneName $kvPrivateDnsZone `
# -Name $kvDevOpsVnetLinkName

# $dnsRecord = Get-AzPrivateDnsRecordSet -ResourceGroupName $resourceGroup `
# -ZoneName $kvPrivateDnsZone -RecordType "A"

# Remove-AzPrivateDnsRecordSet -RecordSet $dnsRecord

# Remove-AzPrivateDnsZone -ResourceGroupName $resourceGroup `
# -Name $kvPrivateDnsZone

Write-Host "-----------Remove------------"