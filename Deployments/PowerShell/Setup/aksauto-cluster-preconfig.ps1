param([Parameter(Mandatory=$false)] [string] $resourceGroup = "aks-workshop-rg",
      [Parameter(Mandatory=$false)] [string] $location = "eastus",
      [Parameter(Mandatory=$false)] [string] $clusterName = "aks-workshop-cluster",
      [Parameter(Mandatory=$false)] [string] $acrName = "akswkshpacr",
      [Parameter(Mandatory=$false)] [string] $keyVaultName = "aks-workshop-kv",
      [Parameter(Mandatory=$false)] [string] $aksVNetName = "aks-workshop-vnet",
      [Parameter(Mandatory=$false)] [string] $aksVNetPrefix = "173.0.0.0/16",
      [Parameter(Mandatory=$false)] [string] $aksSubnetName = "aks-workshop-subnet",
      [Parameter(Mandatory=$false)] [string] $aksSubNetPrefix = "173.0.0.0/22",
      [Parameter(Mandatory=$false)] [string] $appgwSubnetName = "aks-workshop-appgw-subnet",
      [Parameter(Mandatory=$false)] [string] $appgwSubnetPrefix = "173.0.4.0/27",
      [Parameter(Mandatory=$false)] [string] $vrnSubnetName = "vrn-workshop-subnet",
      [Parameter(Mandatory=$false)] [string] $vrnSubnetPrefix = "173.0.5.0/24",
      [Parameter(Mandatory=$false)] [string] $appgwName = "aks-workshop-appgw",
      [Parameter(Mandatory=$false)] [string] $networkTemplateFileName = "aksauto-network-deploy",
      [Parameter(Mandatory=$false)] [string] $acrTemplateFileName = "aksauto-acr-deploy",
      [Parameter(Mandatory=$false)] [string] $kvTemplateFileName = "aksauto-keyvault-deploy",
      [Parameter(Mandatory=$false)] [string] $pfxCertFileName = "<pfxCertFileName>",
      [Parameter(Mandatory=$false)] [string] $rootCertFileName = "<rootCertFileName>",
      [Parameter(Mandatory=$false)] [string] $subscriptionId = "<subscriptionId>",
      [Parameter(Mandatory=$false)] [string] $objectId = "<objectId>",
      [Parameter(Mandatory=$false)] [string] $baseFolderPath = "<baseFolderPath>") # Till Deployments

$vnetRole = "Network Contributor"
$aksSPDisplayName = $clusterName + "-sp"
$aksSPIdName = $clusterName + "-sp-id"
$aksSPSecretName = $clusterName + "-sp-secret"
$templatesFolderPath = $baseFolderPath + "/PowerShell/Templates"

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

$rgRef = Get-AzResourceGroup -Name $resourceGroup -Location $location `
-ErrorAction SilentlyContinue
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
-ResourceGroupName $resourceGroup -ErrorAction SilentlyContinue
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

$certCERBytes = [System.IO.File]::ReadAllBytes($certCERFilePath)
$certCERContents = [Convert]::ToBase64String($certCERBytes)
$certCERContentsSecure = ConvertTo-SecureString -String $certCERContents `
-AsPlainText -Force

$certPFXInfo = Get-AzKeyVaultSecret -VaultName $keyVaultName `
-Name $certSecretName
if ($certPFXInfo)
{

    Remove-AzKeyVaultSecret -VaultName $keyVaultName `
    -Name $certSecretName -Force
    

}

Set-AzKeyVaultSecret -VaultName $keyVaultName -Name $certSecretName `
-SecretValue $certPFXContentsSecure

$certCERInfo = Get-AzKeyVaultSecret -VaultName $keyVaultName `
-Name $rootCertSecretName
if ($certCERInfo)
{

    Remove-AzKeyVaultSecret -VaultName $keyVaultName `
    -Name $rootCertSecretName -Force
}

Set-AzKeyVaultSecret -VaultName $keyVaultName -Name $rootCertSecretName `
-SecretValue $certCERContentsSecure

Write-Host "------------Pre-Config----------"
