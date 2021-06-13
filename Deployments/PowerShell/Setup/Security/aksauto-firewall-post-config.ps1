param([Parameter(Mandatory=$true)] [string] $resourceGroup = "master-workshop-rg",
      [Parameter(Mandatory=$true)] [string] $fwName = "master-hub-workshop-fw",
      [Parameter(Mandatory=$true)] [string] $apiServerIP = "<api_Server_IP>",
      [Parameter(Mandatory=$true)] [string] $fwPublicIP = "<fw_Public_IP>",
      [Parameter(Mandatory=$true)] [string] $translatedIP = "<translated_IP>",
      [Parameter(Mandatory=$true)] [string] $subscriptionId = "<subscriptionId>")

$apiServerRulesCollectionName = "globalrules"
$natRulesCollectionName = "wkshp-appgw-nat-rules"

$subscription = Get-AzSubscription -SubscriptionId $subscriptionId
if (!$subscription)
{
      Write-Host "Error fetching Subscription information"
      return;
}

# PS Select Subscriotion 
Select-AzSubscription -SubscriptionId $subscriptionId

# CLI Select Subscriotion 
$subscriptionCommand = "az account set -s $subscriptionId"
Invoke-Expression -Command $subscriptionCommand

$fwExtensionCommand = "az extension add --name azure-firewall"
Invoke-Expression -Command $fwExtensionCommand

$firewall = Get-AzFirewall -Name $fwName -ResourceGroupName $resourceGroup
if ($firewall)
{

      $apiServerRulesCollection = $firewall.GetNetworkRuleCollectionByName($apiServerRulesCollectionName)
      if ($apiServerRulesCollection)
      {
            $apiServerRules = New-AzFirewallNetworkRule `
            -Name "allow-api-server" `
            -Description "allow api server" `
            -Protocol Any `
            -SourceAddress "*" `
            -DestinationAddress "$apiServerIP" `
            -DestinationPort "443"

            $apiServerRulesCollection.AddRule($apiServerRules)
            Set-AzFirewall -AzureFirewall $firewall

      }

      $natRulesCollection = $firewall.GetNetworkRuleCollectionByName($natRulesCollectionName)
      if (!$natRulesCollection)
      {
            $natRule = New-AzFirewallNatRule `
            -Name "translate-to-appgw" `
            -Description "translate to appgw" `
            -Protocol Any -SourceAddress "*" `
            -DestinationAddress "$fwPublicIP" `
            -DestinationPort "443" `
            -TranslatedAddress "$translatedIP" -TranslatedPort "80"

            $natRulesCollection = New-AzFirewallNatRuleCollection `
            -Name $natRulesCollectionName -Rule $natRule `
            -Priority 100 

            $firewall.AddNatRuleCollection(($natRulesCollection)
            Set-AzFirewall -AzureFirewall $firewall
            
      }
}

