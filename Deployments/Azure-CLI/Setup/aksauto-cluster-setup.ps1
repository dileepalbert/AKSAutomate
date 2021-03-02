param([Parameter(Mandatory=$true)] [string] $mode,        
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
      [Parameter(Mandatory=$false)] [string] $vmSetType = "VirtualMachineScaleSets",
      [Parameter(Mandatory=$false)] [string] $nodeVMSize = "Standard_DS2_v2",
      [Parameter(Mandatory=$false)] [string] $networkPlugin= "azure",
      [Parameter(Mandatory=$false)] [string] $networkPolicy = "azure",
      [Parameter(Mandatory=$false)] [string] $nodePoolName = "akslnxpool",
      [Parameter(Mandatory=$false)] [string] $winNodeUserName = "azureuser",
      [Parameter(Mandatory=$false)] [string] $winNodePassword = "PassW0rd@12345",
      [Parameter(Mandatory=$false)] [string] $logworkspaceId = "/subscriptions/6bdcc705-8db6-4029-953a-e749070e6db6/resourcegroups/defaultresourcegroup-eus/providers/microsoft.operationalinsights/workspaces/aks-workshop-lw",
      [Parameter(Mandatory=$false)] [array]  $aadAdminGroupIDs = @("6ec3a0a8-a6c6-4cdf-a6e3-c296407a5ec1"),
      [Parameter(Mandatory=$false)] [string] $aadTenantID = "3851f269-b22b-4de6-97d6-aa9fe60fe301")
      

$aksSPIdName = $clusterName + "-sp-id"
$aksSPSecretName = $clusterName + "-sp-secret"

$kvShowAppIdCommand = "az keyvault secret show -n $aksSPIdName --vault-name $keyVaultName --query 'value' -o json"
$spAppId = Invoke-Expression -Command $kvShowAppIdCommand

$kvShowSecretCommand = "az keyvault secret show -n $aksSPSecretName --vault-name $keyVaultName --query 'value' -o json"
$spPassword = Invoke-Expression -Command $kvShowSecretCommand

if ($mode -eq "create")
{

    $networkShowCommand = "az network vnet subnet show -n $aksSubnetName --vnet-name $aksVNetName -g $resourceGroup --query 'id' -o json"    
    $aksSubnetId = Invoke-Expression -Command $networkShowCommand
    if (!$aksSubnetId)
    {

        Write-Host "Error fetching Vnet"
        return;

    }

    Write-Host "Creating Cluster... $clusterName"

    az aks create --name $clusterName `
    --resource-group $resourceGroup `
    --kubernetes-version $version --location $location `
    --vnet-subnet-id $aksSubnetId --enable-addons $addons `
    --node-vm-size $nodeVMSize `
    --node-count $nodeCount --max-pods $maxPods `
    --service-principal $spAppId `
    --client-secret $spPassword `
    --network-plugin $networkPlugin --network-policy $networkPolicy `
    --nodepool-name $nodePoolName --vm-set-type $vmSetType `
    --generate-ssh-keys `
    --windows-admin-username $winNodeUserName `
    --windows-admin-password $winNodePassword `
    --enable-aad `
    --aad-admin-group-object-ids $aadAdminGroupIDs `
    --aad-tenant-id $aadTenantID `
    --attach-acr $acrName `
    --workspace-resource-id $logworkspaceId `
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

    az aks update --name $clusterName `
    --resource-group $resourceGroup `
    --aad-admin-group-object-ids $aadAdminGroupIDs `
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

