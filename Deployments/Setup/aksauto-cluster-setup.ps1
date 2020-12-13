param([Parameter(Mandatory=$true)]    [string] $mode,        
        [Parameter(Mandatory=$false)] [string] $resourceGroup = "aks-workshop-rg",
        [Parameter(Mandatory=$false)] [string] $location = "eastus",
        [Parameter(Mandatory=$false)] [string] $clusterName = "aks-workshop-cluster",
        [Parameter(Mandatory=$false)] [string] $acrName = "akswkshpacr",
        [Parameter(Mandatory=$false)] [string] $keyVaultName = "aks-workshop-kv",
        [Parameter(Mandatory=$false)] [string] $aksVNetName = "aks-workshop-vnet",
        [Parameter(Mandatory=$false)] [string] $aksSubnetName = "aks-workshop-subnet",
        [Parameter(Mandatory=$false)] [string] $vrnSubnetName = "vrn-workshop-subnet",
        [Parameter(Mandatory=$false)] [string] $version = "1.17.13",
        [Parameter(Mandatory=$false)] [string] $addons = "monitoring",
        [Parameter(Mandatory=$false)] [string] $nodeCount = 2,        
        [Parameter(Mandatory=$false)] [string] $maxPods = 30,
        [Parameter(Mandatory=$false)] [string] $vmSetType = "AvailabilitySet",
        [Parameter(Mandatory=$false)] [string] $nodeVMSize = "Standard_DS2_v2",
        [Parameter(Mandatory=$false)] [string] $networkPlugin= "azure",
        [Parameter(Mandatory=$false)] [string] $networkPolicy = "azure",
        [Parameter(Mandatory=$false)] [string] $nodePoolName = "akslnxpool",
        [Parameter(Mandatory=$false)] [string] $winNodeUserName = "azureuser",
        [Parameter(Mandatory=$false)] [string] $winNodePassword = "PassW0rd@12345",        
        [Parameter(Mandatory=$false)] [array]  $aadAdminGroupIDs = @("6ec3a0a8-a6c6-4cdf-a6e3-c296407a5ec1"),
        [Parameter(Mandatory=$false)] [string] $aadTenantID = "3851f269-b22b-4de6-97d6-aa9fe60fe301")


$aksSPIdName = $clusterName + "-sp-id"
$aksSPSecretName = $clusterName + "-sp-secret"

$keyVault = Get-AzKeyVault -ResourceGroupName $resourceGroup -VaultName $keyVaultName
if (!$keyVault)
{

    Write-Host "Error fetching KeyVault"
    return;

}

$spAppId = Get-AzKeyVaultSecret -VaultName $keyVaultName -Name $aksSPIdName
if (!$spAppId)
{

    Write-Host "Error fetching Service Principal Id"
    return;

}

$spPassword = Get-AzKeyVaultSecret -VaultName $keyVaultName -Name $aksSPSecretName
if (!$spPassword)
{

    Write-Host "Error fetching Service Principal Password"
    return;

}

$aksVnet = Get-AzVirtualNetwork -Name $aksVNetName `
-ResourceGroupName $resourceGroup
if (!$aksVnet)
{

    Write-Host "Error fetching Vnet"
    return;

}

$aksSubnet = Get-AzVirtualNetworkSubnetConfig -Name $aksSubnetName `
-VirtualNetwork $aksVnet
if (!$aksSubnet)
{

    Write-Host "Error fetching Subnet"
    return;

}

if ($mode -eq "create")
{

    Write-Host "Creating Cluster... $clusterName"

    az aks create --name $clusterName `
    --resource-group $resourceGroup `
    --kubernetes-version $version --location $location `
    --vnet-subnet-id $aksSubnet.Id --enable-addons $addons `
    --node-vm-size $nodeVMSize `
    --node-count $nodeCount --max-pods $maxPods `
    --service-principal $spAppId.SecretValueText `
    --client-secret $spPassword.SecretValueText `
    --network-plugin $networkPlugin --network-policy $networkPolicy `
    --nodepool-name $nodePoolName --vm-set-type $vmSetType `
    --generate-ssh-keys `
    --windows-admin-username $winNodeUserName `
    --windows-admin-password $winNodePassword `
    --enable-aad `
    --aad-admin-group-object-ids $aadAdminGroupIDs `
    --aad-tenant-id $aadTenantID `
    --attach-acr $acrName `
    --enable-private-cluster

    $LASTEXITCODE
    if (!$?)
    {

        Write-Host "Error Creating AKS Cluster - $clusterName"
        return;
    
    }
    
}
elseif ($mode -eq "aad")
{

    Write-Host "Updating AAD Credentials for the Cluster... $clusterName"

    az aks update-credentials --name $clusterName `
    --resource-group $resourceGroup --reset-aad `
    --aad-server-app-id $aadServerAppID `
    --aad-server-app-secret $aadServerAppSecret `
    --aad-client-app-id $aadClientAppID `
    --aad-tenant-id $aadTenantID

    $LASTEXITCODE
    if (!$?)
    {

        Write-Host "Error Updating AAD for AKS Cluster - $clusterName"
        return;
    
    }
    
}
elseif ($mode -eq "sp")
{

    Write-Host "Updating Service Principal for the Cluster... $clusterName"

    az aks update-credentials --name $clusterName `
    --resource-group $resourceGroup --reset-service-principal `
    --aad-server-app-id $aadServerAppID `
    --service-principal $spAppId.SecretValueText `
    --client-secret $spPassword.SecretValueText

    $LASTEXITCODE
    if (!$?)
    {

        Write-Host "Error Updating Service Principal for AKS Cluster - $clusterName"
        return;
    
    }
    
}
elseif ($mode -eq "vn")
{

    Write-Host "Enable Virtual Node addon for the Cluster... $clusterName"

    az aks enable-addons --name $clusterName `
    --resource-group $resourceGroup `
    --addons virtual-node `
    --subnet-name $vrnSubnetName

    $LASTEXITCODE
    if (!$?)
    {

        Write-Host "Error Enabling Virtual Node for AKS Cluster - $clusterName"
        return;
    
    }
    
}

Write-Host "-----------Setup------------"

