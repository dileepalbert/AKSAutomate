param([Parameter(Mandatory=$true)]    [string] $mode,
        [Parameter(Mandatory=$false)] [string] $resourceGroup = "aks-workshop-rg",
        [Parameter(Mandatory=$false)] [string] $location = "eastus",
        [Parameter(Mandatory=$false)] [string] $clusterName = "aks-workshop-cluster",        
        [Parameter(Mandatory=$false)] [string] $aksVNetName = "aks-workshop-vnet",
        [Parameter(Mandatory=$false)] [string] $aksSubnetName = "aks-workshop-subnet",        
        [Parameter(Mandatory=$false)] [string] $version = "1.17.13",
        [Parameter(Mandatory=$false)] [string] $addons = "monitoring",
        [Parameter(Mandatory=$false)] [string] $nodeCount = 2,
        [Parameter(Mandatory=$false)] [string] $minNodeCount = $nodeCount,
        [Parameter(Mandatory=$false)] [string] $maxNodeCount = 100,
        [Parameter(Mandatory=$false)] [string] $maxPods = 40,
        [Parameter(Mandatory=$false)] [string] $vmSetType = "AvailabilitySet",
        [Parameter(Mandatory=$false)] [string] $nodeVMSize = "Standard_DS3_V2",        
        [Parameter(Mandatory=$false)] [string] $nodePoolName = "aksjobspool",
        [Parameter(Mandatory=$false)] [string] $osType = "Linux")

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
    
    Write-Host "Adding Nodepool... $nodePoolName"

    az aks nodepool add --cluster-name $clusterName `
    --resource-group $resourceGroup `
    --name $nodePoolName `
    --kubernetes-version $version `
    --max-pods $maxPods `
    --node-count $nodeCount `
    --node-vm-size $nodeVMSize `
    --os-type $osType

    $LASTEXITCODE
    if (!$?)
    {

        Write-Host "Error Adding Nodepool... $nodePoolName"
        return;
    
    }

}
elseif ($mode -eq "update")
{

    Write-Host "Updating Nodepool... $nodePoolName; Enabling Cluster AutoScaler"
    
    az aks nodepool update --cluster-name $clusterName `
    --resource-group $resourceGroup --enable-cluster-autoscaler `
    --min-count $minNodeCount --max-count $maxNodeCount `
    --name $nodePoolName

    $LASTEXITCODE
    if (!$?)
    {

        Write-Host "Error Updating Nodepool... $nodePoolName"
        return;
    
    }
    
}
elseif ($mode -eq "scale")
{

    Write-Host "Scaling Nodepool... $nodePoolName"

    az aks nodepool scale --cluster-name $clusterName `
    --resource-group $resourceGroup --node-count $nodeCount `
    --name $nodePoolName

    $LASTEXITCODE
    if (!$?)
    {

        Write-Host "Error Scaling Nodepool... $nodePoolName"
        return;
    
    }
    
}
elseif ($mode -eq "delete")
{

    Write-Host "Deleting Nodepool... $nodePoolName"

    az aks nodepool delete --cluster-name $clusterName `
    --resource-group $resourceGroup --name $nodePoolName

    $LASTEXITCODE
    if (!$?)
    {

        Write-Host "Error Deleting Nodepool... $nodePoolName"
        return;
    
    }
    
}

Write-Host "Nodepool Config Successfully Done!"

