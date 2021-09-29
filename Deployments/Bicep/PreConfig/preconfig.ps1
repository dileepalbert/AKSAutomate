param([Parameter(Mandatory=$true)]  [string] $isUdrCluster,
      [Parameter(Mandatory=$true)]  [string] $isPrivateCluster,
      [Parameter(Mandatory=$true)]  [string] $resourceGroup,
    #   [Parameter(Mandatory=$true)]  [string] $lwResourceGroup,
      [Parameter(Mandatory=$true)]  [string] $masterResourceGroup,
      [Parameter(Mandatory=$false)] [string] $fwResourceGroup = $masterResourceGroup,
      [Parameter(Mandatory=$true)]  [string] $location,
      [Parameter(Mandatory=$true)]  [string] $clusterName,
      [Parameter(Mandatory=$true)]  [string] $acrName,
      [Parameter(Mandatory=$true)]  [string] $keyVaultName,    
      [Parameter(Mandatory=$true)]  [string] $appgwName,
      [Parameter(Mandatory=$false)] [string] $fwName,
      [Parameter(Mandatory=$true)]  [string] $aksVNetName,          
      [Parameter(Mandatory=$true)]  [string] $masterVNetName,
      [Parameter(Mandatory=$false)] [string] $fwVnetName = $masterVNetName,
      [Parameter(Mandatory=$false)] [string] $aksPrivateDNSHostName,      
      [Parameter(Mandatory=$false)] [string] $fwConfigFileName,
      [Parameter(Mandatory=$false)] [string] $fwRouteConfigFileName,
      [Parameter(Mandatory=$true)]  [string] $pfxCertFileName,
      [Parameter(Mandatory=$false)] [string] $rootCertFileName,
      [Parameter(Mandatory=$true)]  [string] $spDisplayName,      
      [Parameter(Mandatory=$true)]  [string] $subscriptionId,
      [Parameter(Mandatory=$true)]  [array]  $aadAdminGroupIDs,
      [Parameter(Mandatory=$true)]  [string] $aadTenantID,
      [Parameter(Mandatory=$true)]  [string] $objectId,
      [Parameter(Mandatory=$true)]  [string] $baseFolderPath)

$vnetRole = "Network Contributor"
$privateDNSRole = "private dns zone contributor"
$aksSPIdName = $clusterName + "-sp-id"
$aksSPSecretName = $clusterName + "-sp-secret"
$masterAKSPeeringName = "$masterVNetName-$aksVNetName-peering";
$aksMasterPeeringName = "$aksVNetName-$masterVNetName-peering";
$masterVnetAKSLinkName = "$masterVNetName-aks-dns-plink"

$securityFolderPath = $baseFolderPath + "/Bicep/Security"
$certSecretName = $appgwName + "-cert-secret"
$certPFXFilePath = $baseFolderPath + "/Certs/$pfxCertFileName.pfx"
if (![string]::IsNullOrWhiteSpace($rootCertFileName))
{

    $rootCertDataSecretName = $appgwName + "-root-cert-secret"
    $certCERFilePath = $baseFolderPath + "/Certs/$rootCertFileName.cer"

}

$subscription = Get-AzSubscription -SubscriptionId $subscriptionId
if (!$subscription)
{
    Write-Host "Error fetching Subscription information"
    return;
}

Select-AzSubscription -SubscriptionId $subscriptionId

$subscriptionCommand = "az account set -s $subscriptionId"
Invoke-Expression -Command $subscriptionCommand

# $rgRef = Get-AzResourceGroup -Name $resourceGroup -Location $location
# if (!$rgRef)
# {

#     $rgRef = New-AzResourceGroup -Name $resourceGroup -Location $location
#     if (!$rgRef)
#     {
#         Write-Host "Error creating Resource Group"
#         return;
#     }
# }

# $lwrgRef = Get-AzResourceGroup -Name $lwResourceGroup -Location $location
# if (!$lwrgRef)
# {

#     $lwrgRef = New-AzResourceGroup -Name $lwResourceGroup -Location $location
#     if (!$lwrgRef)
#     {
#         Write-Host "Error creating Monitoring Resource Group"
#         return;
#     }
# }

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

$aksSP = Get-AzADServicePrincipal -DisplayName $spDisplayName
if (!$aksSP)
{
    $spCommand = "az ad sp create-for-rbac --skip-assignment -n $spDisplayName"
    $aksSP = Invoke-Expression -Command $spCommand
    if (!$aksSP)
    {

        Write-Host "Error creating Service Principal for AKS"
        return;

    }

    $aksSP=$aksSP | ConvertFrom-Json

    $aksSPSecureId = ConvertTo-SecureString -String $aksSP.appId `
    -AsPlainText -Force
    Set-AzKeyVaultSecret -VaultName $keyVaultName -Name $aksSPIdName `
    -SecretValue $aksSPSecureId

    $aksSPSecureSecret = ConvertTo-SecureString -String $aksSP.password `
    -AsPlainText -Force
    Set-AzKeyVaultSecret -VaultName $keyVaultName -Name $aksSPSecretName `
    -SecretValue $aksSPSecureSecret

    $aksVnet = Get-AzVirtualNetwork -Name $aksVNetName `
    -ResourceGroupName $resourceGroup
    if ($aksVnet)
    {

        New-AzRoleAssignment -RoleDefinitionName $vnetRole `
        -ApplicationId $aksSP.appId -Scope $aksVnet.Id

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

if (![string]::IsNullOrWhiteSpace($rootCertFileName))
{

    $certCERBytes = [System.IO.File]::ReadAllBytes($certCERFilePath)
    $certCERContents = [Convert]::ToBase64String($certCERBytes)
    $certCERContentsSecure = ConvertTo-SecureString -String $certCERContents `
    -AsPlainText -Force

    $certCERInfo = Get-AzKeyVaultSecret -VaultName $keyVaultName `
    -Name $rootCertDataSecretName
    if (!$certCERInfo)
    {

        Set-AzKeyVaultSecret -VaultName $keyVaultName -Name $rootCertDataSecretName `
        -SecretValue $certCERContentsSecure
        
    }
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

if ($isUdrCluster -eq "true")
{
    $fwConfigCommand = "$securityFolderPath/$fwConfigFileName.ps1 -fwResourceGroup $fwResourceGroup -location $location -fwName $fwName -fwVnetName $fwVnetName -subscriptionId $subscriptionId"
    Invoke-Expression -Command $fwConfigCommand

    $fwRouteConfigCommand = "$securityFolderPath/$fwRouteConfigFileName.ps1 -fwResourceGroup $fwResourceGroup -vnetResourceGroup $resourceGroup -location $location -fwName $fwName -aksVNetName $aksVNetName -aksSubnetName $aksSubnetName -aksSPDisplayName $spDisplayName"
    Invoke-Expression -Command $fwRouteConfigCommand
    
}


Write-Host "------------Pre-Config----------"