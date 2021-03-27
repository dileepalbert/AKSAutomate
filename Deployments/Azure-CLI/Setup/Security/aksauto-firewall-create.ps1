param([Parameter(Mandatory=$false)] [string] $resourceGroup = "master-workshop-rg",
      [Parameter(Mandatory=$false)] [string] $location = "eastus",
      [Parameter(Mandatory=$false)] [string] $fwName = "master-hub-workshop-fw",
      [Parameter(Mandatory=$false)] [string] $vnetName = "master-hub-vnet",
      [Parameter(Mandatory=$false)] [string] $subscriptionId = "6bdcc705-8db6-4029-953a-e749070e6db6")

# $fwPublicIPCommand = "az network public-ip show -n $fwName-pip -g $resourceGroup --query 'ipAddress'"
# $fwPrivateIPCommand = "az network firewall show -n $fwName -g $resourceGroup --query 'ipConfigurations[0].privateIpAddress'"

$subscriptionCommand = "az account set -s $subscriptionId"
Invoke-Expression -Command $subscriptionCommand

$fwExtensionCommand = "az extension add --name azure-firewall"
Invoke-Expression -Command $fwExtensionCommand

$pipShowCommand = "az network public-ip show -g $resourceGroup -n $fwName-pip --query 'id'"
$pipCreateCommand = "az network public-ip create -g $resourceGroup -n $fwName-pip --sku Standard"
$pipId = Invoke-Expression -Command $pipShowCommand
if (!$pipId)
{

      Invoke-Expression -Command $pipCreateCommand

}

$fwShowCommand = "az network firewall show --name $fwName --resource-group $resourceGroup --query 'id'"
$fwCreateCommand = "az network firewall create --name $fwName --resource-group $resourceGroup --location $location"
$fwId = Invoke-Expression -Command $fwShowCommand
if (!$fwId)
{

      Invoke-Expression -Command $fwCreateCommand

}

$ipcShowCommand = "az network firewall ip-config show --firewall-name $fwName --name $fwName-ipc --resource-group $resourceGroup --query 'id'"
$ipcCreateCommand = "az network firewall ip-config create --firewall-name $fwName --name $fwName-ipc --public-ip-address $fwName-pip --resource-group $resourceGroup --vnet-name $vnetName"
$ipcId = Invoke-Expression -Command $ipcShowCommand
if (!$ipcId)
{

      Invoke-Expression -Command $ipcCreateCommand

}

$fwPublicIPCommand = "az network public-ip show -n $fwName-pip -g $resourceGroup --query 'ipAddress'"
$fwPublicIP = Invoke-Expression -Command $fwPublicIPCommand
Write-Host $fwPublicIP

$fwPrivateIPCommand = "az network firewall show -n $fwName -g $resourceGroup --query 'ipConfigurations[0].privateIpAddress'"
$fwPrivateIP = Invoke-Expression -Command $fwPrivateIPCommand
Write-Host $fwPrivateIP

$timeRuleShowCommand = "az network firewall network-rule collection show --collection-name 'time' --firewall-name $fwName -g $resourceGroup --query 'id'"
$timeRuleCreateCommand = "az network firewall network-rule create --firewall-name $fwName --collection-name 'time' --destination-addresses '*'  --destination-ports 123 --name 'allow ntp' --protocols 'UDP' --resource-group $resourceGroup --source-addresses '*' --action 'Allow' --description 'aks node time sync rule' --priority 101"
$timeCollId = Invoke-Expression -Command $timeRuleShowCommand
if (!$timeCollId)
{

      Invoke-Expression -Command $timeRuleCreateCommand

}

$dnsRuleShowCommand = "az network firewall network-rule collection show --collection-name 'dns' --firewall-name $fwName --resource-group $resourceGroup --query 'id'"
$dnsRuleCreateCommand = "az network firewall network-rule create --firewall-name $fwName --collection-name 'dns' --destination-addresses '*'  --destination-ports 53 --name 'allow dns' --protocols 'UDP' --resource-group $resourceGroup --source-addresses '*' --action 'Allow' --description 'aks node dns rule' --priority 102"
$dnsCollId = Invoke-Expression -Command $dnsRuleShowCommand
if (!$dnsCollId)
{

      Invoke-Expression -Command $dnsRuleCreateCommand

}

$globalRulesShowCommand = "az network firewall network-rule collection show --firewall-name $fwName --collection-name 'globalrules' --resource-group $resourceGroup --query 'id'"
$globalRulesCreateCommand = "az network firewall network-rule create --firewall-name $fwName --collection-name 'globalrules' --destination-addresses 'AzureContainerRegistry' 'MicrosoftContainerRegistry' 'AzureActiveDirectory' 'AzureMonitor'  --destination-ports '*' --name 'allow azure services' --protocols 'Any' --resource-group $resourceGroup --source-addresses '*' --action 'Allow' --description 'allow azure services' --priority 103"
$glblCollId = Invoke-Expression -Command $globalRulesShowCommand
if (!$glblCollId)
{

      Invoke-Expression -Command $globalRulesCreateCommand

}

$controlPlaneShowCommand = "az network firewall network-rule show --firewall-name $fwName --collection-name 'globalrules' -n 'allow control plane' --resource-group $resourceGroup --query 'name'"
$controlPlaneCreateCommand = "az network firewall network-rule create --firewall-name $fwName --collection-name 'globalrules' --destination-addresses 'AzureCloud.$location'  --destination-ports 1194 9000 --name 'allow control plane' --protocols 'ANY'  --resource-group $resourceGroup --source-addresses '*'"
$clpnCollId = Invoke-Expression -Command $controlPlaneShowCommand
if (!$clpnCollId)
{

      Invoke-Expression -Command $controlPlaneCreateCommand

}

$aksRuleShowCommand = "az network firewall application-rule collection show --firewall-name $fwName --resource-group $resourceGroup --collection-name 'aksrule' --query 'id'"
$aksRuleCreateCommand = "az network firewall application-rule create --firewall-name $fwName --resource-group $resourceGroup --collection-name 'aksrule' -n 'fqdn' --source-addresses '*' --protocols 'http=80' 'https=443' --fqdn-tags 'AzureKubernetesService' --action allow --priority 101"
$alsCollId = Invoke-Expression -Command $aksRuleShowCommand
if (!$alsCollId)
{

      Invoke-Expression -Command $aksRuleCreateCommand

}

$osRuleShowCommand = "az network firewall application-rule Collection show  --firewall-name $fwName --collection-name 'osupdates' --resource-group $resourceGroup --query 'id'"
$osRuleCreateCommand = "az network firewall application-rule create --firewall-name $fwName --collection-name 'osupdates' --name 'allow os updates' --protocols 'http=80' 'https=443' --source-addresses '*' --resource-group $resourceGroup --action 'Allow' --target-fqdns 'download.opensuse.org' 'security.ubuntu.com' 'packages.microsoft.com' 'azure.archive.ubuntu.co' 'changelogs.ubuntu.com' 'snapcraft.io' 'api.snapcraft.io' 'motd.ubuntu.com'  --priority 102"
$osCollId = Invoke-Expression -Command $osRuleShowCommand
if (!$osCollId)
{

      Invoke-Expression -Command $osRuleCreateCommand

}

$globalRulesShowCommand = "az network firewall application-rule Collection show  --firewall-name $fwName --collection-name 'globalrules' --resource-group $resourceGroup --query 'id'"
$globalRulesCreateCommand = "az network firewall application-rule create  --firewall-name $fwName --collection-name 'globalrules' --name 'allow global rules' --protocols 'https=443' --source-addresses '*' --resource-group $resourceGroup --action 'Allow' --target-fqdns '*.hcp.$location.azmk8s.io' 'mcr.microsoft.com' '*.data.mcr.microsoft.com' 'management.azure.com' 'login.microsoftonline.com' 'acs-mirror.azureedge.net' --priority 103"
$glblCollId = Invoke-Expression -Command $globalRulesShowCommand
if (!$glblCollId)
{

      Invoke-Expression -Command $globalRulesCreateCommand

}

$chkipRulesShowCommand = "az network firewall application-rule show  --firewall-name $fwName --collection-name 'globalrules' -n 'allow checking ip' --resource-group $resourceGroup --query 'name'"
$chkipRulesCreateCommand = "az network firewall application-rule create --firewall-name $fwName --collection-name 'globalrules' --name 'allow checking ip' --protocols 'https=443' --source-addresses '*' --resource-group $resourceGroup --target-fqdns 'checkip.dyndns.org'"
$chkipId = Invoke-Expression -Command $chkipRulesShowCommand
if (!$chkipId)
{

      Invoke-Expression -Command $chkipRulesCreateCommand

}

$ciRulesShowCommand = "az network firewall application-rule Collection show  --firewall-name $fwName --collection-name 'containerimages' --resource-group $resourceGroup --query 'id'"
$ciRulesCreateCommand = "az network firewall application-rule create  --firewall-name $fwName --collection-name 'containerimages' --name 'allow dockerhub' --protocols 'https=443' --source-addresses '*' --resource-group $resourceGroup --action 'Allow' --target-fqdns '*auth.docker.io' '*cloudflare.docker.io' '*cloudflare.docker.com' '*registry-1.docker.io' '*.azurecr.io' '*.blob.core.windows.net' --priority 104"
$ciCollId = Invoke-Expression -Command $ciRulesShowCommand
if (!$ciCollId)
{

      Invoke-Expression -Command $ciRulesCreateCommand

}

$helmRulesShowCommand = "az network firewall application-rule show  --firewall-name $fwName --collection-name 'containerimages' -n 'allow helm' --resource-group $resourceGroup --query 'name'"
$helmRulesCreateCommand = "az network firewall application-rule create --firewall-name $fwName --collection-name 'containerimages' --name 'allow helm' --protocols 'https=443' --source-addresses '*' --resource-group $resourceGroup --target-fqdns 'gcr.io' 'k8s.gcr.io' 'storage.googleapis.com'"
$helmId = Invoke-Expression -Command $helmRulesShowCommand
if (!$helmId)
{

      Invoke-Expression -Command $helmRulesCreateCommand

}

