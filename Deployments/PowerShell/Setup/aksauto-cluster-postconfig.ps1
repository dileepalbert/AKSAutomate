param([Parameter(Mandatory=$false)] [string] $resourceGroup = "aks-workshop-rg",        
      [Parameter(Mandatory=$false)] [string] $projectName = "aks-workshop",
      [Parameter(Mandatory=$false)] [string] $nameSpaceName = "aks-workshop-dev",
      [Parameter(Mandatory=$false)] [string] $location = "eastus",
      [Parameter(Mandatory=$false)] [string] $clusterName = "aks-workshop-cluster",        
      [Parameter(Mandatory=$false)] [string] $acrName = "akswkshpacr",
      [Parameter(Mandatory=$false)] [string] $keyVaultName = "aks-workshop-kv",
      [Parameter(Mandatory=$false)] [string] $appgwName = "aks-workshop-appgw",
      [Parameter(Mandatory=$false)] [string] $aksVNetName = "aks-workshop-vnet",
      [Parameter(Mandatory=$false)] [string] $aksSubnetName = "aks-workshop-subnet",
      [Parameter(Mandatory=$false)] [string] $appgwSubnetName = "aks-workshop-appgw-subnet",        
      [Parameter(Mandatory=$false)] [string] $appgwTemplateFileName = "aksauto-appgw-deploy",        
      [Parameter(Mandatory=$false)] [string] $ingControllerIPAddress = "<ingress-private-ip>",
      [Parameter(Mandatory=$false)] [string] $ingHostName = "<ingress-host-name>",
      [Parameter(Mandatory=$false)] [string] $baseFolderPath = "<base-folder-path>")

$templatesFolderPath = $baseFolderPath + "/PowerShell/Templates"
$yamlFilePath = "$baseFolderPath/YAMLs"
$ingControllerName = $projectName + "-ing"
$ingControllerNSName = $ingControllerName + "-ns"
$ingControllerFileName = "internal-ingress"
$ingControllerFilePath = "$yamlFilePath/Common/$ingControllerFileName.yaml"
$privateIPToken = "<PRIVATE_IP>"

# Switch Cluster context
$kbctlContextCommand = "az aks get-credentials --resource-group $resourceGroup --name $clusterName --overwrite-existing --admin"
Invoke-Expression -Command $kbctlContextCommand

Write-Host $yamlFilePath

# Configure ILB file
$ingressContent = Get-Content -Path $ingControllerFilePath -Raw
$ingressContent = $ingressContent -replace $privateIPToken, $ingControllerIPAddress
Set-Content -Path $ingControllerFilePath  $ingressContent

# Create nginx Namespace
$nginxNSCommand = "kubectl create namespace $ingControllerNSName"
Invoke-Expression -Command $nginxNSCommand

# Install nginx as ILB using Helm
$nginxRepoAddCommand = "helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx"
Invoke-Expression -Command $nginxRepoAddCommand

$nginxRepoUpdateCommand = "helm repo update"
Invoke-Expression -Command $nginxRepoUpdateCommand

$nginxILBCommand = "helm install $ingControllerName ingress-nginx/ingress-nginx --namespace $ingControllerNSName -f $yamlFilePath/Common/$ingControllerFileName.yaml"
Invoke-Expression -Command $nginxILBCommand

# Install AppGW
$networkNames = "-appgwName $appgwName -projectName $projectName -vnetName $aksVNetName -subnetName $appgwSubnetName"
$appgwDeployCommand = "/AppGW/$appgwTemplateFileName.ps1 -rg $resourceGroup -fpath $templatesFolderPath -deployFileName $appgwTemplateFileName -backendIPAddress $ingControllerIPAddress -hostName $ingHostName $networkNames"
$appgwDeployPath = $templatesFolderPath + $appgwDeployCommand
Invoke-Expression -Command $appgwDeployPath

Write-Host "-----------Post-Config------------"
