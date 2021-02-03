param([Parameter(Mandatory=$true)] [string] $resourceGroup = "aks-workshop-rg",
      [Parameter(Mandatory=$true)] [string] $projectName = "aks-workshop",
      [Parameter(Mandatory=$true)] [string] $location = "eastus",
      [Parameter(Mandatory=$true)] [string] $clusterName = "aks-workshop-cluster",
      [Parameter(Mandatory=$true)] [string] $acrName = "akswkshpacr",
      [Parameter(Mandatory=$true)] [string] $keyVaultName = "aks-workshop-kv",
      [Parameter(Mandatory=$true)] [string] $aksVNetName = "aks-workshop-vnet",
      [Parameter(Mandatory=$true)] [string] $aksVNetPrefix = "173.0.0.0/16",
      [Parameter(Mandatory=$true)] [string] $aksSubnetName = "aks-workshop-subnet",
      [Parameter(Mandatory=$true)] [string] $aksSubNetPrefix = "173.0.0.0/22",
      [Parameter(Mandatory=$true)] [string] $appgwSubnetName = "aks-workshop-appgw-subnet",
      [Parameter(Mandatory=$true)] [string] $appgwSubnetPrefix = "173.0.4.0/27",
      [Parameter(Mandatory=$true)] [string] $vrnSubnetName = "vrn-workshop-subnet",
      [Parameter(Mandatory=$true)] [string] $vrnSubnetPrefix = "173.0.5.0/24",
      [Parameter(Mandatory=$true)] [string] $appgwName = "aks-workshop-appgw",
      [Parameter(Mandatory=$true)] [string] $networkTemplateFileName = "aksauto-network-deploy",
      [Parameter(Mandatory=$true)] [string] $acrTemplateFileName = "aksauto-acr-deploy",
      [Parameter(Mandatory=$true)] [string] $kvTemplateFileName = "aksauto-keyvault-deploy",
      [Parameter(Mandatory=$true)] [string] $pfxCertFileName = "star.wkshpdev.com",
      [Parameter(Mandatory=$true)] [string] $rootCertFileName = "star_wkshpdev_com_116159745TrustedRoot",
      [Parameter(Mandatory=$true)] [string] $subscriptionId = "<subscriptionId>",
      [Parameter(Mandatory=$true)] [string] $objectId = "<objectId>",
      [Parameter(Mandatory=$true)] [string] $baseFolderPath = "<baseFolderPath>") # As per host devops machine

$vnetRole = "Network Contributor"
$acrSPRole = "acrpush"
$aksSPDisplayName = $clusterName + "-sp"
$aksSPIdName = $clusterName + "-sp-id"
$aksSPSecretName = $clusterName + "-sp-secret"
$acrSPDisplayName = $clusterName + "-acr-sp"
$acrSPIdName = $acrName + "-sp-id"
$acrSPSecretName = $acrName + "-sp-secret"
$templatesFolderPath = $baseFolderPath + "/Templates"

$certSecretName = $appgwName + "-cert-secret"
$certPFXFilePath = $baseFolderPath + "/Certs/$pfxCertFileName.pfx"

$rootCertSecretName = $appgwName + "-root-cert-secret"
$certCERFilePath = $baseFolderPath + "/Certs/$rootCertFileName.cer"

# Assuming Logged In

$networkNames = "-aksVNetName $aksVNetName -aksVNetPrefix $aksVNetPrefix -aksSubnetName $aksSubnetName -aksSubNetPrefix $aksSubNetPrefix -appgwSubnetName $appgwSubnetName -appgwSubnetPrefix $appgwSubnetPrefix -vrnSubnetName $vrnSubnetName -vrnSubnetPrefix $vrnSubnetPrefix"
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

$aksVnet = Get-AzVirtualNetwork -Name $aksVNetName `
-ResourceGroupName $resourceGroup
$networkDeployPath = $templatesFolderPath + $networkDeployCommand
if (!$aksVnet)
{
    
    Invoke-Expression -Command $networkDeployPath    

}

$acrDeployPath = $templatesFolderPath + $acrDeployCommand
Invoke-Expression -Command $acrDeployPath

$keyVaultDeployPath = $templatesFolderPath + $keyVaultDeployCommand
Invoke-Expression -Command $keyVaultDeployPath

$certPFXBytes = [System.IO.File]::ReadAllBytes($certPFXFilePath)
$certPFXContents = [Convert]::ToBase64String($certPFXBytes)
$certPFXContentsSecure = ConvertTo-SecureString -String $certPFXContents -AsPlainText -Force

$certCERContents = [System.IO.File]::ReadAllText($certCERFilePath)
$certCERContentsSecure = ConvertTo-SecureString -String $certCERContents -AsPlainText -Force

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

    New-AzRoleAssignment -RoleDefinitionName $vnetRole `
    -ApplicationId $aksSP.ApplicationId -Scope $aksVnet.Id

}

$acrInfo = Get-AzContainerRegistry -Name $acrName `
-ResourceGroupName $resourceGroup
if (!$acrInfo)
{

    Write-Host "Error fetching ACR information"
    return;

}

$acrSP = Get-AzADServicePrincipal -DisplayName $acrSPDisplayName
if (!$acrSP)
{

    Write-Host $acrInfo.Id

    $acrSP = New-AzADServicePrincipal -SkipAssignment `
    -DisplayName $acrSPDisplayName
    if (!$acrSP)
    {

        Write-Host "Error creating Service Principal for ACR"
        return;

    }

    Write-Host $acrSPDisplayName
    
    $acrSPObjectId = ConvertTo-SecureString -String $acrSP.ApplicationId `
    -AsPlainText -Force
    Set-AzKeyVaultSecret -VaultName $keyVaultName -Name $acrSPIdName `
    -SecretValue $acrSPObjectId

    Set-AzKeyVaultSecret -VaultName $keyVaultName -Name $acrSPSecretName `
    -SecretValue $acrSP.Secret

    New-AzRoleAssignment -RoleDefinitionName $acrSPRole `
    -ApplicationId $acrSP.ApplicationId -Scope $acrInfo.Id
    
}

Set-AzKeyVaultSecret -VaultName $keyVaultName -Name $certSecretName `
-SecretValue $certPFXContentsSecure

Set-AzKeyVaultSecret -VaultName $keyVaultName -Name $rootCertSecretName `
-SecretValue $certCERContentsSecure

Write-Host "------------Pre-Config----------"
