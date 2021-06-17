param([Parameter(Mandatory=$true)] [string] $fwResourceGroup = "master-workshop-rg",
      [Parameter(Mandatory=$true)] [string] $location = "eastus",
      [Parameter(Mandatory=$true)] [string] $fwName = "master-hub-workshop-fw",
      [Parameter(Mandatory=$true)] [string] $fwVnetName = "master-hub-vnet",
      [Parameter(Mandatory=$true)] [string] $subscriptionId = "6bdcc705-8db6-4029-953a-e749070e6db6")

$timeRulesCollectionName = "time"
$dnsRulesCollectionName = "dns"
$globalRulesCollectionName = "globalrules"
$aksRulesCollectionName = "aksrules"
$osRulesCollectionName  = "osupdates"
$serverRulesCollectionName = "serverrules"
$ciRulesCollectionName = "containerrules"
$policyRulesCollectionName = "policyrules"

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

$publicIP = Get-AzPublicIpAddress -Name $fwName-pip -ResourceGroupName $fwResourceGroup
if (!$publicIP)
{

      New-AzPublicIpAddress -Name $fwName-pip -ResourceGroupName $fwResourceGroup `
      -Sku Standard -AllocationMethod Static -Location $location

      $publicIP = Get-AzPublicIpAddress -Name $fwName-pip `
      -ResourceGroupName $fwResourceGroup

}

$firewall = Get-AzFirewall -Name $fwName -ResourceGroupName $fwResourceGroup
if (!$firewall)
{

      $fwVNet = Get-AzVirtualNetwork -Name $fwVnetName `
      -ResourceGroupName $fwResourceGroup
      
      $firewall = New-AzFirewall -Name $fwName -ResourceGroupName $fwResourceGroup `
      -Location $location -VirtualNetwork $fwVNet `
      -PublicIpAddress $publicIP

}

$timeRulesCollection = $firewall.GetNetworkRuleCollectionByName($timeRulesCollectionName)
if (!$timeRulesCollection)
{
      $ntpRule = New-AzFirewallNetworkRule -Name "allow-ntp" `
      -Description "aks node time sync rule" `
      -Protocol UDP -SourceAddress "*" -DestinationAddress "*" `
      -DestinationPort "123"

      $timeRulesCollection = New-AzFirewallNetworkRuleCollection `
      -Name $timeRulesCollectionName -Rule $ntpRule `
      -Priority 101 -ActionType "Allow"

      $firewall.NetworkRuleCollections.Add($timeRulesCollection)
      Set-AzFirewall -AzureFirewall $firewall
      
}

$dnsRulesCollection = $firewall.GetNetworkRuleCollectionByName($dnsRulesCollectionName)
if (!$dnsRulesCollection)
{
      $dnsRule = New-AzFirewallNetworkRule -Name "allow-dns" `
      -Description "aks node dns rule" `
      -Protocol UDP -SourceAddress "*" -DestinationAddress "*" `
      -DestinationPort "53"

      $dnsRulesCollection = New-AzFirewallNetworkRuleCollection `
      -Name $dnsRulesCollectionName -Rule $dnsRule -Priority 102 `
      -ActionType "Allow"

      $firewall.NetworkRuleCollections.Add($dnsRulesCollection)
      Set-AzFirewall -AzureFirewall $firewall

}

$globalRulesCollection = $firewall.GetNetworkRuleCollectionByName($globalRulesCollectionName)
if (!$globalRulesCollection)
{
      $azureRules = New-AzFirewallNetworkRule -Name "allow-azure-services" `
      -Description "allow azure services" -Protocol Any -SourceAddress "*" `
      -DestinationAddress @("AzureContainerRegistry", "MicrosoftContainerRegistry", "AzureActiveDirectory", "AzureMonitor") `
      -DestinationPort "*"

      $controlPlaneRules = New-AzFirewallNetworkRule `
      -Name "allow-control-plane" -Protocol Any -SourceAddress "*" `
      -DestinationAddress "AzureCloud.$location" `
      -DestinationPort @("1194", "9000")

      $globalRulesCollection = New-AzFirewallNetworkRuleCollection `
      -Name $globalRulesCollectionName `
      -Rule $azureRules -Priority 103 -ActionType "Allow"

      $globalRulesCollection.AddRule($controlPlaneRules)

      $firewall.NetworkRuleCollections.Add($globalRulesCollection)
      Set-AzFirewall -AzureFirewall $firewall

}

$aksRulesCollection = $firewall.GetApplicationRuleCollectionByName($aksRulesCollectionName)
if (!$aksRulesCollection)
{
      $fqdnRules = New-AzFirewallApplicationRule -Name "fqdn" `
      -Protocol @("http:80", "https:443") -Description "aks rules" `
      -SourceAddress "*" -TargetFqdn "AzureKubernetesService"

      $aksRulesCollection = New-AzFirewallApplicationRuleCollection `
      -Name $aksRulesCollectionName -Priority 101 -Rule $fqdnRules `
      -ActionType "Allow"

      $firewall.AddApplicationRuleCollection($aksRulesCollection)
      Set-AzFirewall -AzureFirewall $firewall

}

$osRulesCollection = $firewall.GetApplicationRuleCollectionByName($osRulesCollectionName)
if (!$osRulesCollection)
{
      $osUpdateRules = New-AzFirewallApplicationRule -Name "allow-os-updates" `
      -Protocol @("http:80", "https:443") -Description "allow os updates" `
      -SourceAddress "*" `
      -TargetFqdn @("download.opensuse.org", "security.ubuntu.com", "packages.microsoft.com", "azure.archive.ubuntu.com", "changelogs.ubuntu.com", "snapcraft.io", "api.snapcraft.io", "motd.ubuntu.com")

      $osRulesCollection = New-AzFirewallApplicationRuleCollection `
      -Name $osRulesCollectionName -Priority 102 -Rule $osUpdateRules `
      -ActionType "Allow"

      $firewall.AddApplicationRuleCollection($osRulesCollection)
      Set-AzFirewall -AzureFirewall $firewall
      
}

$serverRulesCollection = $firewall.GetApplicationRuleCollectionByName($serverRulesCollectionName)
if (!$serverRulesCollection)
{
      $serverRules = New-AzFirewallApplicationRule -Name "allow-server-rules" -Protocol @("https:443") `
      -Description "allow global rules" -SourceAddress "*" `
      -TargetFqdn @("*.hcp.$location.azmk8s.io", "mcr.microsoft.com", "*.data.mcr.microsoft.com", "management.azure.com", "login.microsoftonline.com", "acs-mirror.azureedge.net")

      $checkipRules = New-AzFirewallApplicationRule -Name "allow-chcking-ip" `
      -Protocol @("http:80") -Description "allow global rules" -SourceAddress "*" `
      -TargetFqdn @("checkip.dyndns.org")

      $serverRulesCollection = New-AzFirewallApplicationRuleCollection `
      -Name $serverRulesCollectionName -Priority 103 -Rule $serverRules `
      -ActionType "Allow"

      $serverRulesCollection.AddRule($checkipRules)
      $firewall.AddApplicationRuleCollection($serverRulesCollection)
      Set-AzFirewall -AzureFirewall $firewall

}

$ciRulesCollection = $firewall.GetApplicationRuleCollectionByName($ciRulesCollectionName)
if (!$ciRulesCollection)
{
      $dockerHubRules = New-AzFirewallApplicationRule -Name "allow-dockerhub" `
      -Protocol @("https:443") -Description "allow dockerhub" -SourceAddress "*" `
      -TargetFqdn @("*auth.docker.io", "*cloudflare.docker.io", "*cloudflare.docker.com", "*registry-1.docker.io", "*.azurecr.io", "*.blob.core.windows.net")

      $helmRules = New-AzFirewallApplicationRule -Name "allow-helm" `
      -Protocol @("https:443") -Description "allow helm" -SourceAddress "*" `
      -TargetFqdn @("gcr.io", "k8s.gcr.io", "storage.googleapis.com")

      $ciRulesCollection = New-AzFirewallApplicationRuleCollection `
      -Name $ciRulesCollectionName -Priority 104 -Rule $dockerHubRules `
      -ActionType "Allow"

      $ciRulesCollection.AddRule($helmRules)
      $firewall.AddApplicationRuleCollection($ciRulesCollection)
      Set-AzFirewall -AzureFirewall $firewall
      
}

$policyRulesCollection = $firewall.GetApplicationRuleCollectionByName($policyRulesCollectionName)
if (!$policyRulesCollection)
{
      $policyRules = New-AzFirewallApplicationRule -Name "allow-policy-rules" `
      -Protocol @("https:443") -Description "allow policy rules" -SourceAddress "*" `
      -TargetFqdn @("data.policy.core.windows.net", "store.policy.core.windows.net", "dc.services.visualstudio.com")

      $policyRulesCollection = New-AzFirewallApplicationRuleCollection `
      -Name $policyRulesCollectionName -Priority 105 -Rule $policyRules `
      -ActionType "Allow"

      $firewall.AddApplicationRuleCollection($policyRulesCollection)
      Set-AzFirewall -AzureFirewall $firewall
      
}