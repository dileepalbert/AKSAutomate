param([Parameter(Mandatory=$false)]   [string] $resourceGroup = "aks-workshop-rg",        
        [Parameter(Mandatory=$false)] [string] $projectName = "aks-workshop",
        [Parameter(Mandatory=$false)] [string] $location = "eastus",
        [Parameter(Mandatory=$false)] [string] $clusterName = "aks-workshop-cluster",
        [Parameter(Mandatory=$false)] [string] $acrName = "akswkshpacr",
        [Parameter(Mandatory=$false)] [string] $keyVaultName = "aks-workshop-kv",
        [Parameter(Mandatory=$false)] [string] $aksSPName = "aks-workshop-sp",
        [Parameter(Mandatory=$false)] [string] $acrSPName = "aks-workshop-acr-sp",
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
        [Parameter(Mandatory=$true)]  [string] $subscriptionId = "<subscriptionId>",
        [Parameter(Mandatory=$true)]  [string] $objectId = "<objectId>",
        [Parameter(Mandatory=$true)]  [string] $baseFolderPath = "<baseFolderPath>") # As per host devops machine

$vnetRole = "Network Contributor"
$aksSPRole = "Contributor"
$acrSPRole = "acrpush"
$aksSPIdName = $clusterName + "-sp-id"
$aksSPSecretName = $clusterName + "-sp-secret"
$acrSPIdName = $acrName + "-sp-id"
$acrSPSecretName = $acrName + "-sp-secret"
$templatesFolderPath = $baseFolderPath + "/Templates"

# $certSecretName = $appgwName + "-cert-secret"
# $certPFXFilePath = $baseFolderPath + "/Certs/aksauto.pfx"

# Assuming Logged In

$networkNames = "-aksVNetName $aksVNetName -aksVNetPrefix $aksVNetPrefix -aksSubnetName $aksSubnetName -aksSubNetPrefix $aksSubNetPrefix -appgwSubnetName $appgwSubnetName -appgwSubnetPrefix $appgwSubnetPrefix -vrnSubnetName $vrnSubnetName -vrnSubnetPrefix $vrnSubnetPrefix"
$networkDeployCommand = "/Network/$networkTemplateFileName.ps1 -rg $resourceGroup -fpath $templatesFolderPath -deployFileName $networkTemplateFileName $networkNames"

$acrDeployCommand = "/ACR/$acrTemplateFileName.ps1 -rg $resourceGroup -fpath $templatesFolderPath -deployFileName $acrTemplateFileName -acrName $acrName"
$keyVaultDeployCommand = "/KeyVault/$kvTemplateFileName.ps1 -rg $resourceGroup -fpath $templatesFolderPath -deployFileName $kvTemplateFileName -keyVaultName $keyVaultName -objectId $objectId"

# PS Select Subscriotion 
Select-AzSubscription -SubscriptionId $subscriptionId

# CLI Select Subscriotion 
$subscriptionCommand = "az account set -s $subscriptionId"
Invoke-Expression -Command $subscriptionCommand

$subscription = Get-AzSubscription -SubscriptionId $subscriptionId
if (!$subscription)
{
    Write-Host "Error fetching Subscription information"
    return;
}

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

$networkDeployPath = $templatesFolderPath + $networkDeployCommand
Invoke-Expression -Command $networkDeployPath

$acrDeployPath = $templatesFolderPath + $acrDeployCommand
Invoke-Expression -Command $acrDeployPath

$keyVaultDeployPath = $templatesFolderPath + $keyVaultDeployCommand
Invoke-Expression -Command $keyVaultDeployPath

# Write-Host $certPFXFilePath
# $certBytes = [System.IO.File]::ReadAllBytes($certPFXFilePath)
# $certContents = [Convert]::ToBase64String($certBytes)
# $certContentsSecure = ConvertTo-SecureString -String $certContents -AsPlainText -Force
# Write-Host $certPFXFilePath

$aksSP = Get-AzADServicePrincipal -DisplayName $aksSPName
if (!$aksSP)
{
    $aksSP = New-AzADServicePrincipal -SkipAssignment `
    -Role $aksSPRole -DisplayName $aksSPName `
    -Scope $subscription.Id
    if (!$aksSP)
    {

        Write-Host "Error creating Service Principal for AKS"
        return;

    }

    Write-Host $aksSPName

    $aksSPObjectId = ConvertTo-SecureString -String $aksSP.ApplicationId `
    -AsPlainText -Force
    Set-AzKeyVaultSecret -VaultName $keyVaultName -Name $aksSPIdName `
    -SecretValue $aksSPObjectId

    Set-AzKeyVaultSecret -VaultName $keyVaultName -Name $aksSPSecretName `
    -SecretValue $aksSP.Secret

}

$acrInfo = Get-AzContainerRegistry -Name $acrName `
-ResourceGroupName $resourceGroup
if (!$acrInfo)
{

    Write-Host "Error fetching ACR information"
    return;

}

$acrSP = Get-AzADServicePrincipal -DisplayName $acrSPName
if (!$acrSP)
{

    Write-Host $acrInfo.Id

    $acrSP = New-AzADServicePrincipal -SkipAssignment `
    -Role $acrSPRole -DisplayName $acrSPName `
    -Scope $acrInfo.ApplicationId
    if (!$acrSP)
    {

        Write-Host "Error creating Service Principal for ACR"
        return;

    }

    Write-Host $acrSPName
    
    $acrSPObjectId = ConvertTo-SecureString -String $acrSP.ApplicationId `
    -AsPlainText -Force
    Set-AzKeyVaultSecret -VaultName $keyVaultName -Name $acrSPIdName `
    -SecretValue $acrSPObjectId

    Set-AzKeyVaultSecret -VaultName $keyVaultName -Name $acrSPSecretName `
    -SecretValue $acrSP.Secret
    
}

# Set-AzKeyVaultSecret -VaultName $keyVaultName -Name $certSecretName `
# -SecretValue $certContentsSecure

$aksVnet = Get-AzVirtualNetwork -Name $aksVNetName -ResourceGroupName $resourceGroup
if ($aksVnet)
{

    New-AzRoleAssignment -ApplicationId $aksSP.ApplicationId `
    -Scope $aksVnet.Id -RoleDefinitionName $vnetRole

}

New-AzRoleAssignment -ApplicationId $acrSP.ApplicationId `
-RoleDefinitionName $acrSPRole -Scope $acrInfo.Id

Write-Host "------Pre-Config------"
