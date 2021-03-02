param([Parameter(Mandatory=$false)]   [string] $resourceGroup = "aks-workshop-rg",        
        [Parameter(Mandatory=$false)] [string] $projectName = "aks-workshop",        
        [Parameter(Mandatory=$false)] [string] $location = "eastus",
        [Parameter(Mandatory=$false)] [string] $clusterName = "aks-workshop-cluster",        
        [Parameter(Mandatory=$false)] [string] $acrName = "akswkshpacr",
        [Parameter(Mandatory=$false)] [string] $keyVaultName = "aks-workshop-kv",
        [Parameter(Mandatory=$false)] [string] $appgwName = "aks-workshop-appgw",
        [Parameter(Mandatory=$false)] [string] $aksVNetName = "aks-workshop-vnet",
        [Parameter(Mandatory=$false)] [string] $aksSubnetName = "aks-workshop-subnet",
        [Parameter(Mandatory=$false)] [string] $appgwSubnetName = "aks-workshop-appgw-subnet",        
        [Parameter(Mandatory=$false)] [string] $appgwTemplateFileName = "aksauto-appgw-deploy",        
        [Parameter(Mandatory=$false)] [string] $ingControllerIPAddress = "173.0.0.200",
        [Parameter(Mandatory=$false)] [string] $ingHostName = "ingress-dev.wkshpdev.com",
        [Parameter(Mandatory=$false)] [string] $baseFolderPath = "/Users/monojitd/Materials/Projects/AKSProjects/AKSWorkshop/AKSAutomate/Deployments")

$templatesFolderPath = $baseFolderPath + "/Azure-CLI/Templates"
$yamlFilePath = "$baseFolderPath/YAMLs"
$ingControllerName = $projectName + "-ing"
$ingControllerNSName = $ingControllerName + "-ns"
$ingControllerFileName = "internal-ingress"
$ingControllerFilePath = "$yamlFilePath/Common/$ingControllerFileName.yaml"

# Switch Cluster context
$kbctlContextCommand = "az aks get-credentials --resource-group $resourceGroup --name $clusterName --overwrite-existing --admin"
Invoke-Expression -Command $kbctlContextCommand

Write-Host $yamlFilePath

# Configure ILB file
$ingressContent = Get-Content -Path $ingControllerFilePath -Raw
$ingressContent = $ingressContent -replace "<PRIVATE_IP>", $ingControllerIPAddress
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
$appgwParameters = "applicationGatewayName=$appgwName vnetName=$aksVNetName subnetName=$appgwSubnetName backendIpAddress1=$ingControllerIPAddress hostName=$ingHostName"
$appgwDeployCommand = "az deployment group create -g $resourceGroup --template-file $templatesFolderPath/AppGW/$appgwTemplateFileName.json --parameters $appgwParameters --query='id' -o json"
Invoke-Expression -Command $appgwDeployCommand

Write-Host "-----------Post-Config------------"
