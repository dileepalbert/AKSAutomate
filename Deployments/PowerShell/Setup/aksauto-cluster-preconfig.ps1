param([Parameter(Mandatory=$true)]  [string] $isPrivateCluster = "false",
      [Parameter(Mandatory=$false)] [string] $resourceGroup = "aks-workshop-rg",
      [Parameter(Mandatory=$false)] [string] $lwResourceGroup = "monitoring-workshop-rg",
      [Parameter(Mandatory=$false)] [string] $masterResourceGroup = "master-workshop-rg",
      [Parameter(Mandatory=$false)] [string] $location = "eastus",
      [Parameter(Mandatory=$false)] [string] $clusterName = "aks-workshop-cluster",
      [Parameter(Mandatory=$false)] [string] $acrName = "akswkshpacr",
      [Parameter(Mandatory=$false)] [string] $keyVaultName = "aks-workshop-kv",
      [Parameter(Mandatory=$false)] [string] $logworkspaceName = "aks-workshop-lw",
      [Parameter(Mandatory=$false)] [string] $appgwName = "aks-workshop-appgw",
      [Parameter(Mandatory=$false)] [string] $masterVNetName = "master-workshop-vnet",
      [Parameter(Mandatory=$false)] [string] $aksVNetName = "aks-workshop-vnet",
      [Parameter(Mandatory=$false)] [string] $aksVNetPrefix = "12.0.0.0/16",
      [Parameter(Mandatory=$false)] [string] $aksSubnetName = "aks-workshop-subnet",
      [Parameter(Mandatory=$false)] [string] $aksSubNetPrefix = "12.0.0.0/22",
      [Parameter(Mandatory=$false)] [string] $appgwSubnetName = "aks-workshop-appgw-subnet",
      [Parameter(Mandatory=$false)] [string] $appgwSubnetPrefix = "12.0.4.0/27",
      [Parameter(Mandatory=$false)] [string] $ingressSubnetName = "aks-workshop-ing-subnet",
      [Parameter(Mandatory=$false)] [string] $ingressSubnetPrefix = "12.0.5.0/24",
      [Parameter(Mandatory=$false)] [string] $vrnSubnetName = "vrn-workshop-subnet",
      [Parameter(Mandatory=$false)] [string] $vrnSubnetPrefix = "12.0.7.0/24",
      [Parameter(Mandatory=$false)] [string] $aksPrivateDNSHostName = "aks.private.wkshpdev.com",
      [Parameter(Mandatory=$false)] [string] $networkTemplateFileName = "aksauto-network-deploy",
      [Parameter(Mandatory=$false)] [string] $acrTemplateFileName = "aksauto-acr-deploy",
      [Parameter(Mandatory=$false)] [string] $kvTemplateFileName = "aksauto-keyvault-deploy",
      [Parameter(Mandatory=$false)] [string] $pfxCertFileName = "<pfxCertFileName>",
      [Parameter(Mandatory=$false)] [string] $subscriptionId = "<subscriptionId>",
      [Parameter(Mandatory=$false)] [array]  $aadAdminGroupIDs = @("<aadAdminGroupID>"),
      [Parameter(Mandatory=$false)] [string] $aadTenantID = "<aadTenantID>",
      [Parameter(Mandatory=$false)] [string] $objectId = "<objectId>",
      [Parameter(Mandatory=$false)] [string] $baseFolderPath = "<baseFolderPath>")

$vnetRole = "Network Contributor"
$privateDNSRole = "private dns zone contributor"
$aksSPDisplayName = $clusterName + "-sp"
$aksSPIdName = $clusterName + "-sp-id"
$aksSPSecretName = $clusterName + "-sp-secret"
$masterAKSPeeringName = "$masterVNetName-$aksVNetName-peering";
$aksMasterPeeringName = "$aksVNetName-$masterVNetName-peering";
$masterVnetAKSLinkName = "$masterVNetName-aks-dns-plink"

$templatesFolderPath = $baseFolderPath + "/PowerShell/Templates"
$certSecretName = $appgwName + "-cert-secret"
$certPFXFilePath = $baseFolderPath + "/Certs/$pfxCertFileName.pfx"

# Assuming Logged In

$networkNames = "-aksVNetName $aksVNetName -aksVNetPrefix $aksVNetPrefix -aksSubnetName $aksSubnetName -aksSubNetPrefix $aksSubNetPrefix -appgwSubnetName $appgwSubnetName -appgwSubnetPrefix $appgwSubnetPrefix -ingressSubnetName $ingressSubnetName -ingressSubnetPrefix $ingressSubnetPrefix -vrnSubnetName $vrnSubnetName -vrnSubnetPrefix $vrnSubnetPrefix"
$networkDeployCommand = "/Network/$networkTemplateFileName.ps1 -rg $resourceGroup -fpath $templatesFolderPath -deployFileName $networkTemplateFileName $networkNames"

$acrDeployCommand = "/ACR/$acrTemplateFileName.ps1 -rg $resourceGroup -fpath $templatesFolderPath -deployFileName $acrTemplateFileName -acrName $acrName"
$keyVaultDeployCommand = "/KeyVault/$kvTemplateFileName.ps1 -rg $resourceGroup -fpath $templatesFolderPath -deployFileName $kvTemplateFileName -keyVaultName $keyVaultName -objectId $objectId"

$subscription = Get-AzSubscription -SubscriptionId $subscriptionId
if (!$subscription)
{
    Write-Host "Error fetching Subscription information"
    return;
}

# PS Select Subscriotion 
Select-AzSubscription -SubscriptionId $subscriptionId

# CLI Select Subscriotion 
$subscriptionCommand = "az account set -s $subscriptionId"
Invoke-Expression -Command $subscriptionCommand

$rgRef = Get-AzResourceGroup -Name $resourceGroup -Location $location
if (!$rgRef)
{

   $rgRef = New-AzResourceGroup -Name $resourceGroup -Location $location
   if (!$rgRef)
   {
        Write-Host "Error creating Resource Group"
        return;
   }
}

$lwrgRef = Get-AzResourceGroup -Name $lwResourceGroup -Location $location
if (!$lwrgRef)
{

    $lwrgRef = New-AzResourceGroup -Name $lwResourceGroup -Location $location
   if (!$lwrgRef)
   {
        Write-Host "Error creating Monitoring Resource Group"
        return;
   }
}

$logWorkspace = Get-AzOperationalInsightsWorkspace `
-ResourceGroupName $lwResourceGroup `
-Name $logWorkspaceName 
if (!$logWorkspace)
{
   
   $logWorkspace = New-AzOperationalInsightsWorkspace `
   -ResourceGroupName $lwResourceGroup `
   -Location $location -Name $logWorkspaceName
   if (!$logWorkspace)
   {
        Write-Host "Error creating Resource Group"
        return;
   }
}

$aksVnet = Get-AzVirtualNetwork -Name $aksVNetName `
-ResourceGroupName $resourceGroup
$networkDeployPath = $templatesFolderPath + $networkDeployCommand
if (!$aksVnet)
{
    
    Invoke-Expression -Command $networkDeployPath
    $aksVnet = Get-AzVirtualNetwork -Name $aksVNetName `
    -ResourceGroupName $resourceGroup

}

$acrDeployPath = $templatesFolderPath + $acrDeployCommand
Invoke-Expression -Command $acrDeployPath

$keyVaultDeployPath = $templatesFolderPath + $keyVaultDeployCommand
Invoke-Expression -Command $keyVaultDeployPath

$keyVault = Get-AzKeyVault -VaultName $keyVaultName `
-ResourceGroupName $resourceGroup
if ($keyVault)
{

    Set-AzKeyVaultAccessPolicy -VaultName $keyVaultName -ObjectId $objectId `
    -PermissionsToSecrets get,list,set,delete `
    -PermissionsToKeys get,list,update,create,delete `
    -PermissionsToCertificates get,list,update,create,delete

    foreach ($adminId in $aadAdminGroupIDs)
    {

        Set-AzKeyVaultAccessPolicy -VaultName $keyVaultName `
        -BypassObjectIdValidation -ObjectId $adminId `
        -PermissionsToSecrets get,list,set,delete `
        -PermissionsToKeys get,list,update,create,delete `
        -PermissionsToCertificates get,list,update,create,delete 
        
    }
}

$aksSP = Get-AzADServicePrincipal -DisplayName $aksSPDisplayName
if (!$aksSP)
{
    $aksSP = New-AzADServicePrincipal -SkipAssignment `
    -DisplayName $aksSPDisplayName
    if (!$aksSP)
    {

        Write-Host "Error creating Service Principal for AKS"
        return;

    }

    Write-Host $aksSPDisplayName

    $aksSPObjectId = ConvertTo-SecureString -String $aksSP.ApplicationId `
    -AsPlainText -Force
    Set-AzKeyVaultSecret -VaultName $keyVaultName -Name $aksSPIdName `
    -SecretValue $aksSPObjectId

    Set-AzKeyVaultSecret -VaultName $keyVaultName -Name $aksSPSecretName `
    -SecretValue $aksSP.Secret

    $aksVnet = Get-AzVirtualNetwork -Name $aksVNetName `
    -ResourceGroupName $resourceGroup
    if ($aksVnet)
    {

        New-AzRoleAssignment -RoleDefinitionName $vnetRole `
        -ApplicationId $aksSP.ApplicationId -Scope $aksVnet.Id

    }

    $acrInfo = Get-AzContainerRegistry -ResourceGroupName $resourceGroup `
    -Name $acrName
    if ($acrInfo)
    {

        New-AzRoleAssignment -RoleDefinitionName "AcrPush" `
        -ApplicationId $aksSP.ApplicationId -Scope $acrInfo.Id

    }
}

$certPFXBytes = [System.IO.File]::ReadAllBytes($certPFXFilePath)
$certPFXContents = [Convert]::ToBase64String($certPFXBytes)
$certPFXContentsSecure = ConvertTo-SecureString -String $certPFXContents `
-AsPlainText -Force

$certPFXInfo = Get-AzKeyVaultSecret -VaultName $keyVaultName `
-Name $certSecretName
if (!$certPFXInfo)
{

    Set-AzKeyVaultSecret -VaultName $keyVaultName -Name $certSecretName `
    -SecretValue $certPFXContentsSecure

}

$masterVnet = Get-AzVirtualNetwork -Name $masterVNetName `
-ResourceGroupName $masterResourceGroup
if (!$masterVnet)
{

    Write-Host "Error getting Master VNet details"
    return;

}

$masterAKSPeering = Get-AzVirtualNetworkPeering -ResourceGroupName $masterResourceGroup `
-VirtualNetworkName $masterVNetName -Name $masterAKSPeeringName
if ($masterAKSPeering)
{

    Remove-AzVirtualNetworkPeering -VirtualNetworkName $masterVNetName `
    -ResourceGroupName $masterResourceGroup -Name $masterAKSPeeringName -Force

}

$aksMasterPeering = Get-AzVirtualNetworkPeering -ResourceGroupName $resourceGroup `
-VirtualNetworkName $aksVNetName -Name $aksMasterPeeringName
if ($aksMasterPeering)
{

    Remove-AzVirtualNetworkPeering -VirtualNetworkName $aksVNetName `
    -ResourceGroupName $resourceGroup -Name $aksMasterPeeringName -Force
    
}

Add-AzVirtualNetworkPeering -Name $masterAKSPeeringName -VirtualNetwork $masterVnet `
-RemoteVirtualNetworkId $aksVnet.Id

Add-AzVirtualNetworkPeering -Name $aksMasterPeeringName -VirtualNetwork $aksVnet `
-RemoteVirtualNetworkId $masterVnet.Id

if ($isPrivateCluster -eq "true")
{
    
    $privateDNSZone = Get-AzPrivateDnsZone -ResourceGroupName $masterResourceGroup `
    -Name $aksPrivateDNSHostName
    if (!$privateDNSZone)
    {

        $privateDNSZone = New-AzPrivateDnsZone -ResourceGroupName $masterResourceGroup `
        -Name $aksPrivateDNSHostName 
        if (!$privateDNSZone)
        {

            Write-Host "Error creating Private DNS Zone"
            return;

        }
    }

    New-AzRoleAssignment -RoleDefinitionName $privateDNSRole `
    -ApplicationId $aksSP.ApplicationId -Scope $privateDNSZone.ResourceId

    $masterVNetLink = Get-AzPrivateDnsVirtualNetworkLink -ZoneName $aksPrivateDNSHostName `
    -ResourceGroupName $masterResourceGroup -Name $masterVnetAKSLinkName
    if (!$masterVNetLink)
    {

        $masterVnet = Get-AzVirtualNetwork -Name $masterVNetName `
        -ResourceGroupName $masterResourceGroup
        if ($masterVnet)
        {

            New-AzPrivateDnsVirtualNetworkLink -ZoneName $aksPrivateDNSHostName `
            -ResourceGroupName $masterResourceGroup -Name $masterVnetAKSLinkName `
            -VirtualNetworkId $masterVnet.Id

        }
    }
}

Write-Host "------------Pre-Config----------"
