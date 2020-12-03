param([Parameter(Mandatory=$false)]   [string] $resourceGroup = "aks-workshop-rg",
        [Parameter(Mandatory=$false)] [string] $dvoResourceGroup = "devops-workshop-rg",
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
        [Parameter(Mandatory=$false)] [string] $dvoVNetName = "devops-workshop-vnet",
        [Parameter(Mandatory=$false)] [string] $dvoSubetName = "devops-workshop-subnet",
        [Parameter(Mandatory=$false)] [string] $appgwTemplateFileName = "aksauto-appgw-deploy",
        [Parameter(Mandatory=$false)] [string] $pepConfigFileName = "aksauto-pep-config",
        [Parameter(Mandatory=$false)] [string] $pepTemplateFileName = "aksauto-pep-deploy",
        [Parameter(Mandatory=$false)] [string] $acrPvtLinkFileName = "aksauto-acr-plink-config",
        [Parameter(Mandatory=$false)] [string] $kvPvtLinkFileName = "aksauto-kv-plink-config",
        [Parameter(Mandatory=$false)] [string] $ingControllerIPAddress = "173.0.0.200",
        [Parameter(Mandatory=$false)] [string] $baseFolderPath = "<baseFolderPath>")

$templatesFolderPath = $baseFolderPath + "/Templates"
$yamlFilePath = "$baseFolderPath/YAMLs"
$ingControllerName = $projectName + "-ing"
$ingControllerNSName = $ingControllerName + "-ns"
$ingControllerFileName = "internal-ingress"

# Enable these lines if you want Private Endpoint

# $setupFolderPath = $baseFolderPath + "/Setup"
# $acrAKSPepName = $projectName + "-acr-aks-pep"
# $acrAKSPepConnectionName = $acrAKSPepName + "-conn"
# $acrDevOpsPepName = $projectName + "-acr-devops-pep"
# $acrDevOpsPepConnectionName = $acrDevOpsPepName + "-conn"
# $acrPepResourceType = "Microsoft.ContainerRegistry/registries"
# $acrPepSubResourceId = "registry"
# $kvDevOpsPepName = $projectName + "-kv-devops-pep"
# $kvDevOpsPepConnectionName = $kvDevOpsPepName + "-conn"
# $kvPepResourceType = "Microsoft.KeyVault/vaults"
# $kvPepSubResourceId = "vault"
# $acrAKSVnetLinkName = $acrAKSPepName + "-link"
# $acrDevOpsVnetLinkName = $acrDevOpsPepName + "-link"
# $kvDevOpsVnetLinkName = $kvDevOpsPepName + "-link"

# $acrAKSPepNames = "-pepName $acrAKSPepName -pepConnectionName $acrAKSPepConnectionName -pepResourceType $acrPepResourceType -pepResourceName $acrName -pepTemplateFileName $pepTemplateFileName -pepSubResourceId $acrPepSubResourceId"
# $acrAKSPepDeployCommand = "/Security/$pepConfigFileName.ps1 -resourceGroup $resourceGroup -vnetResourceGroup $resourceGroup -vnetName $aksVNetName -subnetName $aksSubnetName -baseFolderPath $baseFolderPath $acrAKSPepNames"

# $acrAKSPvtLinkNames = "-pepName $acrAKSPepName -pepResourceName $acrName -vnetLinkName $acrAKSVnetLinkName"
# $acrAKSPvtLinkDeployCommand = "/Security/$acrPvtLinkFileName.ps1 -resourceGroup $resourceGroup -vnetResourceGroup $resourceGroup -location $location -vnetName $aksVNetName $acrAKSPvtLinkNames"

# $acrDevOpsPepNames = "-pepName $acrDevOpsPepName -pepConnectionName $acrDevOpsPepConnectionName -pepResourceType $acrPepResourceType -pepResourceName $acrName -pepTemplateFileName $pepTemplateFileName -pepSubResourceId $acrPepSubResourceId"
# $acrDevOpsPepDeployCommand = "/Security/$pepConfigFileName.ps1 -resourceGroup $resourceGroup -vnetResourceGroup $dvoResourceGroup -vnetName $dvoVNetName -subnetName $dvoSubetName -baseFolderPath $baseFolderPath $acrDevOpsPepNames"

# $acrDevOpsPvtLinkNames = "-pepName $acrDevOpsPepName -pepResourceName $acrName -vnetLinkName $acrDevOpsVnetLinkName"
# $acrDevOpsPvtLinkDeployCommand = "/Security/$acrPvtLinkFileName.ps1 -resourceGroup $resourceGroup -vnetResourceGroup $dvoResourceGroup -location $location -vnetName $dvoVNetName $acrDevOpsPvtLinkNames"

# $kvDevOpsPepNames = "-pepName $kvDevOpsPepName -pepConnectionName $kvDevOpsPepConnectionName -pepResourceType $kvPepResourceType -pepResourceName $keyVaultName -pepTemplateFileName $pepTemplateFileName -pepSubResourceId $kvPepSubResourceId"
# $kvDevOpsPepDeployCommand = "/Security/$pepConfigFileName.ps1 -resourceGroup $resourceGroup -vnetResourceGroup $dvoResourceGroup -vnetName $dvoVNetName -subnetName $dvoSubetName -baseFolderPath $baseFolderPath $kvDevOpsPepNames"

# $kvDevOpsPvtLinkNames = "-pepName $kvDevOpsPepName -pepResourceName $keyVaultName -vnetLinkName $kvDevOpsVnetLinkName"
# $kvDevOpsPvtLinkDeployCommand = "/Security/$kvPvtLinkFileName.ps1 -resourceGroup $resourceGroup -vnetResourceGroup $dvoResourceGroup -location $location -vnetName $dvoVNetName $kvDevOpsPvtLinkNames"

# $acrUpdateNwRulesCommand = "az acr update --public-network-enabled false --name $acrName --resource-group $resourceGroup"
# $kvUpdateNwRulesCommand = "Update-AzKeyVaultNetworkRuleSet -DefaultAction Deny -ResourceGroupName $resourceGroup -VaultName $keyVaultName"

# Switch Cluster context
$kbctlContextCommand = "az aks get-credentials --resource-group $resourceGroup --name $clusterName --overwrite-existing --admin"
Invoke-Expression -Command $kbctlContextCommand

# Configure ILB file
$ipReplaceCommand = "sed -e 's|<ILB_IP>|$ingControllerIPAddress|' $yamlFilePath/Common/$ingControllerFileName.yaml > $yamlFilePath/Common/tmp.$ingControllerFileName.yaml"
Invoke-Expression -Command $ipReplaceCommand
# Remove temp ILB file
$removeTempFileCommand = "mv $yamlFilePath/Common/tmp.$ingControllerFileName.yaml $yamlFilePath/Common/$ingControllerFileName.yaml"
Invoke-Expression -Command $removeTempFileCommand

# Create Namespace
$nginxNSCommand = "kubectl create namespace $nameSpaceName"
Invoke-Expression -Command $nginxNSCommand
# nginx NS
$nginxNSCommand = "kubectl create namespace $ingControllerNSName"
Invoke-Expression -Command $nginxNSCommand

# Install nginx as ILB using Helm
$nginxRepoUpdateCommand = "helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx"
Invoke-Expression -Command $nginxRepoUpdateCommand
$nginxILBCommand = "helm install $ingControllerName ingress-nginx/ingress-nginx  --namespace $ingControllerNSName -f $yamlFilePath/Common/$ingControllerFileName.yaml --set controller.replicaCount=2 --set nodeSelector.'beta.kubernetes.io/os'=linux --set defaultBackend.nodeSelector.'beta\.kubernetes\.io/os'=linux"
Invoke-Expression -Command $nginxILBCommand

# Install AppGW
$networkNames = "-appgwName $appgwName -vnetName $aksVNetName -subnetName $appgwSubnetName"
$appgwDeployCommand = "/AppGW/$appgwTemplateFileName.ps1 -rg $resourceGroup -fpath $templatesFolderPath -deployFileName $appgwTemplateFileName -backendIPAddress $ingControllerIPAddress $networkNames"
$appgwDeployPath = $templatesFolderPath + $appgwDeployCommand
Invoke-Expression -Command $appgwDeployPath

# Enable these lines if you want Private Endpoint

# Invoke-Expression -Command $acrUpdateNwRulesCommand
# $acrAKSPepDeployPath = $setupFolderPath + $acrAKSPepDeployCommand
# Invoke-Expression -Command $acrAKSPepDeployPath

# $acrAKSPvtLinkDeployPath = $setupFolderPath + $acrAKSPvtLinkDeployCommand
# Invoke-Expression -Command $acrAKSPvtLinkDeployPath

# $acrDevOpsPepDeployPath = $setupFolderPath + $acrDevOpsPepDeployCommand
# Invoke-Expression -Command $acrDevOpsPepDeployPath

# $acrDevOpsPvtLinkDeployPath = $setupFolderPath + $acrDevOpsPvtLinkDeployCommand
# Invoke-Expression -Command $acrDevOpsPvtLinkDeployPath

# Invoke-Expression -Command $kvUpdateNwRulesCommand
# $kvDevOpsPepDeployPath = $setupFolderPath + $kvDevOpsPepDeployCommand
# Invoke-Expression -Command $kvDevOpsPepDeployPath

# $kvDevOpsPvtLinkDeployPath = $setupFolderPath + $kvDevOpsPvtLinkDeployCommand
# Invoke-Expression -Command $kvDevOpsPvtLinkDeployPath

Write-Host "-----------Post-Config------------"
