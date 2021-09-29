param([Parameter(Mandatory=$true)]  [string] $mode,
      [Parameter(Mandatory=$false)] [string] $isUdrCluster,
      [Parameter(Mandatory=$false)] [string] $isPrivateCluster,      
      [Parameter(Mandatory=$true)]  [string] $resourceGroup = "aks-workshop-rg",
      [Parameter(Mandatory=$false)] [string] $masterResourceGroup = "master-workshop-rg",
      [Parameter(Mandatory=$false)] [string] $lwResourceGroup = "monitoring-workshop-rg",
      [Parameter(Mandatory=$false)] [string] $location = "eastus",
      [Parameter(Mandatory=$false)] [string] $clusterName = "aks-workshop-cluster",
      [Parameter(Mandatory=$false)] [string] $acrName = "akswkshpacr",
      [Parameter(Mandatory=$true)]  [string] $keyVaultName = "aks-workshop-kv",
      [Parameter(Mandatory=$false)] [string] $logworkspaceName = "aks-workshop-lw",
      [Parameter(Mandatory=$false)] [string] $aksVNetName = "aks-workshop-vnet",
      [Parameter(Mandatory=$false)] [string] $aksSubnetName = "aks-workshop-subnet",
      [Parameter(Mandatory=$false)] [string] $vrnSubnetName = "vrn-workshop-subnet",
      [Parameter(Mandatory=$false)] [string] $version = "1.18.17",
      [Parameter(Mandatory=$false)] [string] $addons = "monitoring",
      [Parameter(Mandatory=$false)] [string] $nodeCount = 3,
      [Parameter(Mandatory=$false)] [string] $maxPods = 40,
      [Parameter(Mandatory=$false)] [string] $vmSetType = "VirtualMachineScaleSets",
      [Parameter(Mandatory=$false)] [string] $nodeVMSize = "Standard_DS3_v2",
      [Parameter(Mandatory=$false)] [string] $aksServicePrefix = "12.0.6.0/24",
      [Parameter(Mandatory=$false)] [string] $aksDNSServiceIP = "12.0.6.10",
      [Parameter(Mandatory=$false)] [string] $networkPlugin= "azure",
      [Parameter(Mandatory=$false)] [string] $networkPolicy = "azure",
      [Parameter(Mandatory=$false)] [string] $nodePoolName = "akssyspool",
      [Parameter(Mandatory=$false)] [array]  $aadAdminGroupIDs = @("<aadAdminGroupID>"),
      [Parameter(Mandatory=$false)] [string] $aadTenantID = "<aadTenantID>")

$aksSPIdName = $clusterName + "-sp-id"
$aksSPSecretName = $clusterName + "-sp-secret"

$keyVault = Get-AzKeyVault -ResourceGroupName $resourceGroup `
-VaultName $keyVaultName
if ($keyVault)
{

    $spAppId = Get-AzKeyVaultSecret -VaultName $keyVaultName `
    -Name $aksSPIdName
    $spAppId = ConvertFrom-SecureString $spAppId.SecretValue `
    -AsPlainText

    $spPassword = Get-AzKeyVaultSecret -VaultName $keyVaultName `
    -Name $aksSPSecretName

    $spPassword = ConvertFrom-SecureString $spPassword.SecretValue `
    -AsPlainText

}

if ($mode -eq "create")
{

    if (!$spAppId || !$spPassword)
    {

        Write-Host "Error fetching Service Principal Info"
        return;

    }

    $aksVnet = Get-AzVirtualNetwork -Name $aksVNetName `
    -ResourceGroupName $resourceGroup
    if (!$aksVnet)
    {

        Write-Host "Error fetching Vnet"
        return;

    }

    $aksSubnet = Get-AzVirtualNetworkSubnetConfig `
    -Name $aksSubnetName -VirtualNetwork $aksVnet
    if (!$aksSubnet)
    {

        Write-Host "Error fetching Subnet"
        return;

    }

    $lwInfo = Get-AzOperationalInsightsWorkspace -Name $logworkspaceName `
    -ResourceGroupName $lwResourceGroup
    $logWorkspaceId = $lwInfo.ResourceId
    if (!$logWorkspaceId)
    {

        Write-Host "Error fetching Log Workspace"
        return;

    }

    $aksSubnetId = $aksSubnet.Id
    $aksCreateCommand = "az aks create --name $clusterName --resource-group $resourceGroup --kubernetes-version $version --location $location --vnet-subnet-id '$aksSubnetId' --enable-addons $addons --node-vm-size $nodeVMSize --node-count $nodeCount --max-pods $maxPods --service-cidr $aksServicePrefix --dns-service-ip $aksDNSServiceIP --service-principal '$spAppId' --client-secret '$spPassword' --network-plugin $networkPlugin --network-policy $networkPolicy --nodepool-name $nodePoolName --vm-set-type $vmSetType --generate-ssh-keys --enable-aad --aad-admin-group-object-ids $aadAdminGroupIDs --aad-tenant-id $aadTenantID --attach-acr $acrName --workspace-resource-id '$logWorkspaceId'"
    $privateClusterCommand = " --enable-private-cluster"
    $udrClusterCommand = " --outbound-type userDefinedRouting"

    if ($isPrivateCluster -eq "true")
    {

        $aksPrivateDNSHostName = "privatelink.$location.azmk8s.io"
        $privateDNSZone = Get-AzPrivateDnsZone -ResourceGroupName $masterResourceGroup `
        -Name $aksPrivateDNSHostName        
        if (!$privateDNSZone)
        {

            Write-Host "Error fetching Private DNS Zone - $aksPrivateDNSHostName"
            return;
            
        }
        
        $privateDNSZoneId = $privateDNSZone.ResourceId
        $privateClusterCommand = " --enable-private-cluster --private-dns-zone $privateDNSZoneId"
        $aksCreateCommand = $aksCreateCommand + $privateClusterCommand

    }

    if ($isUdrCluster -eq "true")
    {
        $aksCreateCommand = $aksCreateCommand + $udrClusterCommand
    }

    Write-Host "Creating Cluster... $clusterName"
    Invoke-Expression -Command $aksCreateCommand

    $LASTEXITCODE
    if (!$?)
    {

        Write-Host "Error Creating AKS Cluster - $clusterName"
        return;
    
    }
}
elseif ($mode -eq "aad")
{

    $aksAADCommand = "az aks update --name $clusterName --resource-group $resourceGroup --aad-admin-group-object-ids $aadAdminGroupIDs --aad-tenant-id $aadTenantID"

    Write-Host "Updating AAD Credentials for the Cluster... $clusterName"
    Invoke-Expression -Command $aksAADCommand

    $LASTEXITCODE
    if (!$?)
    {

        Write-Host "Error Updating AAD for AKS Cluster - $clusterName"
        return;
    
    }
}
elseif ($mode -eq "sp")
{

    if (!$spAppId || !$spPassword)
    {

        Write-Host "Error fetching Service Principal Info"
        return;

    }
    
    $aksSPCommand = "az aks update-credentials --name $clusterName --resource-group $resourceGroup --reset-service-principal --service-principal $spAppId --client-secret $spPassword"

    Write-Host "Updating Service Principal for the Cluster... $clusterName"    
    Invoke-Expression -Command $aksSPCommand

    $LASTEXITCODE
    if (!$?)
    {

        Write-Host "Error Updating Service Principal for AKS Cluster - $clusterName"
        return;
    
    }
}
elseif ($mode -eq "vn")
{

    $aksVNCommand = "az aks enable-addons --name $clusterName --resource-group $resourceGroup --addons virtual-node --subnet-name $vrnSubnetName"
    
    Write-Host "Enable Virtual Node addon for the Cluster... $clusterName"
    Invoke-Expression -Command $aksVNCommand

    $LASTEXITCODE
    if (!$?)
    {

        Write-Host "Error Enabling Virtual Node for AKS Cluster - $clusterName"
        return;
    
    }
    
}

Write-Host "-----------Setup------------"

