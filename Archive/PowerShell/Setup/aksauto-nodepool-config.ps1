param([Parameter(Mandatory=$true)]  [string] $mode,
      [Parameter(Mandatory=$true)]  [string] $nodePoolName = "<nodePoolName>",
      [Parameter(Mandatory=$true)]  [string] $resourceGroup = "aks-workshop-rg",
      [Parameter(Mandatory=$true)]  [string] $clusterName = "aks-workshop-cluster",
      [Parameter(Mandatory=$false)] [string] $version = "1.18.17",
      [Parameter(Mandatory=$false)] [string] $nodeCount = 3,
      [Parameter(Mandatory=$false)] [string] $minNodeCount = $nodeCount,
      [Parameter(Mandatory=$false)] [string] $maxNodeCount = 20,
      [Parameter(Mandatory=$false)] [string] $maxPods = 40,
      [Parameter(Mandatory=$false)] [string] $nodePoolVMSize = "Standard_DS3_V2",
      [Parameter(Mandatory=$false)] [string] $osType = "Linux",
      [Parameter(Mandatory=$false)] [string] $nodepoolMode = "User")

# Create Nodepool
if ($mode -eq "create")
{

    $aksNodepoolCommand = "az aks nodepool add --cluster-name $clusterName --resource-group $resourceGroup --name $nodePoolName --kubernetes-version $version --max-pods $maxPods --node-count $nodeCount --node-vm-size $nodePoolVMSize --os-type $osType --mode $nodepoolMode"
    
    Write-Host "Adding Nodepool... $nodePoolName"
    Invoke-Expression -Command $aksNodepoolCommand

    $LASTEXITCODE
    if (!$?)
    {

        Write-Host "Error Adding Nodepool... $nodePoolName"
        return;
    
    }

}
# Enable Cluster AutoScaler for the Noepool
elseif ($mode -eq "autoscale")
{

    $aksUpdateCommand = "az aks nodepool update --cluster-name $clusterName --resource-group $resourceGroup --enable-cluster-autoscaler --min-count $minNodeCount --max-count $maxNodeCount --name $nodePoolName"
    
    Write-Host "Updating Nodepool... $nodePoolName; Enabling Cluster AutoScaler"
    Invoke-Expression -Command $aksUpdateCommand

    $LASTEXITCODE
    if (!$?)
    {

        Write-Host "Error Updating Nodepool... $nodePoolName"
        return;
    
    }
    
}
# Scale the Nodepool AutoScaler
elseif ($mode -eq "scale")
{

    $aksScaleCommand = "az aks nodepool update --update-cluster-autoscaler --cluster-name $clusterName --resource-group $resourceGroup --min-count $minNodeCount --max-count $maxNodeCount --name $nodePoolName"

    Write-Host "Scaling Nodepool... $nodePoolName"
    Invoke-Expression -Command $aksScaleCommand

    $LASTEXITCODE
    if (!$?)
    {

        Write-Host "Error Scaling Nodepool... $nodePoolName"
        return;
    
    }
    
}
# Delete the Nodepool
elseif ($mode -eq "delete")
{

    $aksDeleteCommand = "az aks nodepool delete --cluster-name $clusterName --resource-group $resourceGroup --name $nodePoolName"

    Write-Host "Deleting Nodepool... $nodePoolName"
    Invoke-Expression -Command $aksDeleteCommand

    $LASTEXITCODE
    if (!$?)
    {

        Write-Host "Error Deleting Nodepool... $nodePoolName"
        return;
    
    }
    
}

Write-Host "-----------Nodepool Config------------"

