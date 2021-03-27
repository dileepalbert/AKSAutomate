param([Parameter(Mandatory=$false)] [string] $resourceGroup = "master-workshop-rg",
      [Parameter(Mandatory=$false)] [string] $fwName = "master-hub-workshop-fw",
      [Parameter(Mandatory=$false)] [string] $apiServerIP = "20.43.100.103",
      [Parameter(Mandatory=$false)] [string] $fwPublicIP = "52.191.36.103",
      [Parameter(Mandatory=$false)] [string] $translatedIP = "173.0.0.100",
      [Parameter(Mandatory=$false)] [string] $subscriptionId = "6bdcc705-8db6-4029-953a-e749070e6db6")

$subscriptionCommand = "az account set -s $subscriptionId"
Invoke-Expression -Command $subscriptionCommand

$fwExtensionCommand = "az extension add --name azure-firewall"
Invoke-Expression -Command $fwExtensionCommand

$apiRuleShowCommand = "az network firewall network-rule show --firewall-name $fwName --collection-name 'globalrules' --name 'allow api server' --resource-group $resourceGroup --query 'name'"
$apiRuleCreateCommand = "az network firewall network-rule create --firewall-name $fwName --collection-name 'globalrules' --name 'allow api server' --destination-addresses $apiServerIP  --destination-ports 443 --protocols 'ANY' --resource-group $resourceGroup --source-addresses '*'"
$apiId = Invoke-Expression -Command $apiRuleShowCommand
if (!$apiId)
{

      Invoke-Expression -Command $apiRuleCreateCommand

}

$natRuleShowCommand = "az network firewall nat-rule show --firewall-name $fwName --collection-name 'wkshp-appgw-nat-rules' --name 'translate to wkshp appgw' --resource-group $resourceGroup --query 'name'"
$natRuleCreateCommand = "az network firewall nat-rule create --firewall-name $fwName --collection-name 'wkshp-appgw-nat-rules' --name 'translate to wkshp appgw' --destination-addresses $fwPublicIP  --destination-ports 443 --protocols 'ANY'  --resource-group $resourceGroup --source-addresses '*' --translated-port 80 --translated-address $translatedIP --action Dnat --priority 100"
$natId = Invoke-Expression -Command $natRuleShowCommand
if (!$natId)
{

      Invoke-Expression -Command $natRuleCreateCommand

}