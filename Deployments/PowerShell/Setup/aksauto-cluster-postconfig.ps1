param([Parameter(Mandatory=$true)]  [string] $resourceGroup = "aks-workshop-rg",
      [Parameter(Mandatory=$true)]  [string] $masterResourceGroup = "master-workshop-rg",
      [Parameter(Mandatory=$true)]  [string] $location = "eastus",
      [Parameter(Mandatory=$true)]  [array]  $httpsListeners = @("dev", "qa", "smoke"),
      [Parameter(Mandatory=$false)] [array]  $httpListeners = @("dev", "qa"),
      [Parameter(Mandatory=$true)]  [array]  $namespaces = @("aks-workshop-dev", "aks-workshop-qa", "smoke"),
      [Parameter(Mandatory=$true)]  [string] $clusterName = "aks-workshop-cluster",
      [Parameter(Mandatory=$true)]  [string] $acrName = "akswkshpacr",
      [Parameter(Mandatory=$true)]  [string] $keyVaultName = "aks-workshop-kv",
      [Parameter(Mandatory=$true)]  [string] $certDataSecretName = "aks-workshop-appgw-cert-secret",
      [Parameter(Mandatory=$true)]  [string] $certSecretName = "aks-workshop-appgw-cert-password",
      [Parameter(Mandatory=$false)] [string] $rootCertSecretName = "aks-workshop-appgw-root-cert-secret",
      [Parameter(Mandatory=$true)]  [string] $masterVNetName = "master-workshop-vnet",
      [Parameter(Mandatory=$true)]  [string] $aksVNetName = "aks-workshop-vnet",
      [Parameter(Mandatory=$true)]  [string] $ingressSubnetName = "aks-workshop-ing-subnet",
      [Parameter(Mandatory=$true)]  [string] $ingressNodePoolName = "akssyspool",
      [Parameter(Mandatory=$true)]  [string] $appgwName = "aks-workshop-appgw",
      [Parameter(Mandatory=$true)]  [string] $appgwSubnetName = "aks-workshop-appgw-subnet",
      [Parameter(Mandatory=$true)]  [string] $appgwTemplateFileName = "aksauto-appgw-deploy",
      [Parameter(Mandatory=$true)]  [string] $appgwConfigFileName = "aksauto-config-appgw",
      [Parameter(Mandatory=$true)]  [string] $ingressControllerIPAddress = "12.0.5.100",
      [Parameter(Mandatory=$true)]  [string] $ingressHostName = "<ingressHostName>",
      [Parameter(Mandatory=$true)]  [string] $listenerHostName = "<listenerHostName>",
      [Parameter(Mandatory=$true)]  [string] $healthProbeHostName = "<healthProbeHostName>",
      [Parameter(Mandatory=$true)]  [string] $healthProbePath = "<healthProbePath>",
      [Parameter(Mandatory=$true)]  [string] $subscriptionId = "<subscriptionId>",
      [Parameter(Mandatory=$true)]  [string] $baseFolderPath = "<baseFolderPath>")

$setupFolderPath = "$baseFolderPath/PowerShell/Setup"
$securityFolderPath = "$setupFolderPath/Security"
$ingControllerName = $clusterName + "-ing"
$ingControllerNSName = $ingControllerName + "-ns"
$ingControllerFileName = "internal-ingress"
$ingControllerFilePath = "$setupFolderPath/Common/$ingControllerFileName.yaml"
$masterVnetLinkName = "$masterVNetName-dns-plink"
$aksVnetLinkName = "$aksVNetName-dns-plink"

# Creating Private DNS Zone
$privateDNSZone = Get-AzPrivateDnsZone -ResourceGroupName $masterResourceGroup `
-Name $ingressHostName
if (!$privateDNSZone)
{

      $privateDNSZone = New-AzPrivateDnsZone -ResourceGroupName $masterResourceGroup `
      -Name $ingressHostName 
      if (!$privateDNSZone)
      {

            Write-Host "Error creating Private DNS Zone"
            return;

      }
}

# Add Record Sets in Private DNS Zone
foreach ($httpsListener in $httpsListeners)
{
            
      $recordSet = Get-AzPrivateDnsRecordSet -Zone $privateDNSZone `
      -Name $httpsListener -RecordType A
      if (!$recordSet)
      {

            $recordConfigsList = New-AzPrivateDnsRecordConfig -IPv4Address $ingressControllerIPAddress

            New-AzPrivateDnsRecordSet -Name $httpsListener -RecordType A `
            -ResourceGroupName $masterResourceGroup -TTL 3600 -ZoneName $ingressHostName `
            -PrivateDnsRecords $recordConfigsList
            
      }
}

# Link Master VNET to Private DNS Zone
$masterVNetLink = Get-AzPrivateDnsVirtualNetworkLink -ZoneName $ingressHostName `
-ResourceGroupName $masterResourceGroup -Name $masterVnetLinkName
if (!$masterVNetLink)
{

      $masterVnet = Get-AzVirtualNetwork -Name $masterVNetName `
      -ResourceGroupName $masterResourceGroup
      if ($masterVnet)
      {

            New-AzPrivateDnsVirtualNetworkLink -ZoneName $ingressHostName `
            -ResourceGroupName $masterResourceGroup -Name $masterVnetLinkName `
            -VirtualNetworkId $masterVnet.Id

      }

}

# Link AKS VNET to Private DNS Zone
$aksVNetLink = Get-AzPrivateDnsVirtualNetworkLink -ZoneName $ingressHostName `
-ResourceGroupName $masterResourceGroup -Name $aksVnetLinkName
if (!$aksVNetLink)
{

      $aksVnet = Get-AzVirtualNetwork -Name $aksVNetName `
      -ResourceGroupName $resourceGroup
      if ($aksVnet)
      {

            New-AzPrivateDnsVirtualNetworkLink -ZoneName $ingressHostName `
            -ResourceGroupName $masterResourceGroup -Name $aksVnetLinkName `
            -VirtualNetworkId $aksVnet.Id

      }

}

# Switch Cluster context
$kbctlContextCommand = "az aks get-credentials --resource-group $resourceGroup --name $clusterName --overwrite-existing --admin"
Invoke-Expression -Command $kbctlContextCommand

# Create enviorment specific Namespaces
foreach ($namepaceName in $namespaces)
{
            
      $createNSCommand = "kubectl create namespace $namepaceName"
      Invoke-Expression -Command $createNSCommand

      $labelNSCommand = "kubectl label namespace $namepaceName name=$namepaceName"
      Invoke-Expression -Command $labelNSCommand

}

# Create nginx Namespace
$nginxNSCommand = "kubectl create namespace $ingControllerNSName"
Invoke-Expression -Command $nginxNSCommand

$labelNSCommand = "kubectl label namespace $ingControllerNSName name=$ingControllerNSName"
Invoke-Expression -Command $labelNSCommand

# Install nginx as ILB using Helm
$nginxRepoAddCommand = "helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx"
Invoke-Expression -Command $nginxRepoAddCommand

$nginxRepoUpdateCommand = "helm repo update"
Invoke-Expression -Command $nginxRepoUpdateCommand

$nginxConfigCommand = "--set controller.service.loadBalancerIP=$ingressControllerIPAddress --set controller.nodeSelector.agentpool=$ingressNodePoolName --set controller.defaultBackend.nodeSelector.agentpool=$ingressNodePoolName --set controller.service.annotations.'service\.beta\.kubernetes\.io/azure-load-balancer-internal-subnet'=$ingressSubnetName"
$nginxILBCommand = "helm install $ingControllerName ingress-nginx/ingress-nginx --namespace $ingControllerNSName -f $ingControllerFilePath $nginxConfigCommand"
Invoke-Expression -Command $nginxILBCommand

$processedHttpsListeners = @()
foreach ($listener in $httpsListeners)
{
      $processedHttpsListeners += "'$listener'"
}
$processedHttpsListeners = $processedHttpsListeners -join ","

$processedHttpListeners = @()
foreach ($listener in $httpListeners)
{
      $processedHttpListeners += "'$listener'"
}
$processedHttpListeners = $processedHttpListeners -join ","
$ingressHostName = "." + $ingressHostName
$listenerHostName = "." + $listenerHostName

$appgwParameters = "-httpListeners @($processedHttpListeners) -httpsListeners @($processedHttpsListeners) -appgwName $appgwName -appgwVNetName $aksVNetName -appgwSubnetName $appgwSubnetName -appgwTemplateFileName $appgwTemplateFileName -backendIpAddress $ingressControllerIPAddress -backendPoolHostName $ingressHostName -listenerHostName $listenerHostName -healthProbeHostName $healthProbeHostName -healthProbePath $healthProbePath -baseFolderPath $baseFolderPath"
$appgwDeployCommand = "/$appgwConfigFileName.ps1 -resourceGroup $resourceGroup $appgwParameters -keyVaultName $keyVaultName -certDataSecretName $certDataSecretName -certSecretName $certSecretName"
if ($rootCertSecretName)
{

      $appgwDeployCommand = $appgwDeployCommand + " -rootCertDataSecretName $rootCertSecretName"

}
$appgwDeployPath = $securityFolderPath + $appgwDeployCommand
Invoke-Expression -Command $appgwDeployPath

Write-Host "-----------Post-Config------------"
