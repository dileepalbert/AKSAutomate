param([Parameter(Mandatory=$true)]    [string] $mode,
        [Parameter(Mandatory=$false)] [string] $resourceGroup = "aks-workshop-rg",
        [Parameter(Mandatory=$false)] [string] $location = "eastus",
        [Parameter(Mandatory=$false)] [string] $clusterName = "aks-workshop-cluster",
        [Parameter(Mandatory=$false)] [string] $keyVaultName = "aks-workshop-kv",
        [Parameter(Mandatory=$false)] [string] $aksVNetName = "aks-workshop-vnet",
        [Parameter(Mandatory=$false)] [string] $aksSubnetName = "aks-workshop-subnet",        
        [Parameter(Mandatory=$false)] [string] $version = "1.16.15",
        [Parameter(Mandatory=$false)] [string] $addons = "monitoring",
        [Parameter(Mandatory=$false)] [string] $nodeCount = 2,
        [Parameter(Mandatory=$false)] [string] $minNodeCount = $nodeCount,
        [Parameter(Mandatory=$false)] [string] $maxNodeCount = 20,
        [Parameter(Mandatory=$false)] [string] $maxPods = 40,
        [Parameter(Mandatory=$false)] [string] $vmSetType = "VirtualMachineScaleSets",
        [Parameter(Mandatory=$false)] [string] $nodeVMSize = "Standard_DS3_V2",
        [Parameter(Mandatory=$false)] [string] $networkPlugin= "azure",
        [Parameter(Mandatory=$false)] [string] $networkPolicy = "azure",
        [Parameter(Mandatory=$false)] [string] $nodePoolName = "akslnxpool",
        [Parameter(Mandatory=$false)] [string] $winNodeUserName = "azureuser",
        [Parameter(Mandatory=$false)] [string] $winNodePassword = "PassW0rd@123",        
        [Parameter(Mandatory=$false)] [string] $aadServerAppID = "3adf37ca-d914-43e9-9b24-8c081e0b3a08",
        [Parameter(Mandatory=$false)] [string] $aadServerAppSecret = ".Te.--TTxrcU7gZl6U_9ic70D.GVrTLCsN",
        [Parameter(Mandatory=$false)] [string] $aadClientAppID = "70dba699-0fba-4c1d-805e-213acea0a63e",
        [Parameter(Mandatory=$false)] [string] $aadTenantID = "3851f269-b22b-4de6-97d6-aa9fe60fe301")


$aksSPIdName = $clusterName + "-sp-id"
$aksSPSecretName = $clusterName + "-sp-secret"
$configSuccessCommand =  "length(@)"

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

    $result = az aks create --name $clusterName `
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
    --aad-client-app-id $aadClientAppID `
    --aad-server-app-id $aadServerAppID `
    --aad-server-app-secret $aadServerAppSecret `
    --aad-tenant-id $aadTenantID `
    --query $configSuccessCommand

    Write-Host "Result - $result"

    if ($result -le 0)
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
    
}
elseif ($mode -eq "sp")
{

    Write-Host "Updating Service Principal for the Cluster... $clusterName"

    $result = az aks update-credentials --name $clusterName `
    --resource-group $resourceGroup --reset-service-principal `
    --aad-server-app-id $aadServerAppID `
    --service-principal $spAppId.SecretValueText `
    --client-secret $spPassword.SecretValueText
    
}
elseif ($mode -eq "vn")
{

    Write-Host "Enable Virtual Node addon for the Cluster... $clusterName"

    $result = az aks enable-addons --name $clusterName `
    --resource-group $resourceGroup `
    --addons virtual-node `
    --subnet-name vrn-workshop-subnet    
    
}

Write-Host "-----------Setup------------"

