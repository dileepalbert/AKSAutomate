param([Parameter(Mandatory=$true)] [string] $resourceGroup = "master-workshop-rg",
      [Parameter(Mandatory=$true)] [string] $fwName = "master-hub-workshop-fw",
      [Parameter(Mandatory=$true)] [string] $apiServerIP = "<api_Server_IP>")

$apiServerRulesCollectionName = "globalrules"
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

      # $natRulesCollectionName = "wkshp-appgw-nat-rules"
      # $fwPrivateIP = $firewall.IpConfigurations[0].PrivateIPAddress
      # $natRulesCollection = $firewall.GetNetworkRuleCollectionByName($natRulesCollectionName)
      # if (!$natRulesCollection)
      # {
      #       $natRule = New-AzFirewallNatRule `
      #       -Name "translate-to-appgw" `
      #       -Description "translate to appgw" `
      #       -Protocol Any -SourceAddress "*" `
      #       -DestinationAddress "$fwPrivateIP" `
      #       -DestinationPort "443" `
      #       -TranslatedAddress "$translatedIP" `
      #       -TranslatedPort $translatedPort

      #       $natRulesCollection = New-AzFirewallNatRuleCollection `
      #       -Name $natRulesCollectionName -Rule $natRule `
      #       -Priority 100 

      #       $firewall.AddNatRuleCollection($natRulesCollection)
      #       Set-AzFirewall -AzureFirewall $firewall
            
      # }
}

