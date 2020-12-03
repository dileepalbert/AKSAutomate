param([Parameter(Mandatory=$true)]    [string] $mode,
        [Parameter(Mandatory=$false)] [string] $resourceGroup = "aks-workshop-rg",
        [Parameter(Mandatory=$false)] [string] $location = "eastus",
        [Parameter(Mandatory=$false)] [string] $clusterName = "aks-workshop-cluster",        
        [Parameter(Mandatory=$false)] [string] $aksVNetName = "aks-workshop-vnet",
        [Parameter(Mandatory=$false)] [string] $aksSubnetName = "aks-workshop-subnet",        
        [Parameter(Mandatory=$false)] [string] $version = "1.16.15",
        [Parameter(Mandatory=$false)] [string] $addons = "monitoring",
        [Parameter(Mandatory=$false)] [string] $nodeCount = 3,
        [Parameter(Mandatory=$false)] [string] $minNodeCount = $nodeCount,
        [Parameter(Mandatory=$false)] [string] $maxNodeCount = 20,
        [Parameter(Mandatory=$false)] [string] $maxPods = 40,
        [Parameter(Mandatory=$false)] [string] $vmSetType = "VirtualMachineScaleSets",
        [Parameter(Mandatory=$false)] [string] $nodeVMSize = "Standard_DS3_V2",        
        [Parameter(Mandatory=$false)] [string] $nodePoolName = "aksiotpool",
        [Parameter(Mandatory=$false)] [string] $osType = "Linux")

$configSuccessCommand =  "length(@)"

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

    $result = az aks nodepool add --cluster-name $clusterName `
    --resource-group $resourceGroup `
    --name $nodePoolName `
    --kubernetes-version $version `
    --max-pods $maxPods `
    --node-count $nodeCount `
    --node-vm-size $nodeVMSize `
    --os-type $osType `
    --query $configSuccessCommand

    Write-Host "Result - $result"

    if ($result -le 0)
    {

        Write-Host "Error Creating Nodepool - $nodePoolName"
        return;
    
    }

}
elseif ($mode -eq "update")
{

    Write-Host "Updating Nodepool... $nodePoolName; Enabling Cluster AutoScaler"
    
    $result = az aks nodepool update --cluster-name $clusterName `
    --resource-group $resourceGroup --enable-cluster-autoscaler `
    --min-count $minNodeCount --max-count $maxNodeCount `
    --name $nodePoolName --query $configSuccessCommand

    Write-Host "Result - $result"

    if ($result -le 0)
    {

        Write-Host "Error Updating Nodepool - $nodePoolName"
        return;
    
    }
    
}
elseif ($mode -eq "scale")
{

    Write-Host "Scaling Nodepool... $nodePoolName"

    $result = az aks nodepool scale --cluster-name $clusterName `
    --resource-group $resourceGroup --node-count $nodeCount `
    --name $nodePoolName `
    --query $configSuccessCommand

    Write-Host "Result - $result"

    if ($result -le 0)
    {

        Write-Host "Error Scaling Nodepool - $nodePoolName"
        return;
    
    }
    
}
elseif ($mode -eq "delete")
{

    Write-Host "Deleting Nodepool... $nodePoolName"

    az aks nodepool delete --cluster-name $clusterName `
    --resource-group $resourceGroup --name $nodePoolName
    
}

Write-Host "Nodepool Config Successfully Done!"

