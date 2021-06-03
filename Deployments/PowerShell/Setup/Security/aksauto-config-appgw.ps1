param([Parameter(Mandatory=$false)] [string] $resourceGroup,
      [Parameter(Mandatory=$false)] [array]  $httpsListeners,
      [Parameter(Mandatory=$false)] [array]  $httpListeners,
      [Parameter(Mandatory=$false)] [string] $appgwName,  
      [Parameter(Mandatory=$false)] [string] $appgwVNetName,
      [Parameter(Mandatory=$false)] [string] $appgwSubnetName,
      [Parameter(Mandatory=$false)] [string] $appgwTemplateFileName,
      [Parameter(Mandatory=$false)] [string] $backendIpAddress,
      [Parameter(Mandatory=$false)] [string] $backendPoolHostName,
      [Parameter(Mandatory=$false)] [string] $listenerHostName,
      [Parameter(Mandatory=$false)] [string] $healthProbeHostName,
      [Parameter(Mandatory=$false)] [string] $healthProbePath,
      [Parameter(Mandatory=$false)] [string] $baseFolderPath)

$templatesFolderPath = $baseFolderPath + "/PowerShell/Templates"

$processedListeners = @()
foreach ($listener in $httpsListeners)
{
      $processedListeners += "'$listener'"
}
$processedListeners = $processedListeners -join ","

$appgwParameters = "-appgwName $appgwName -vnetName $appgwVNetName -subnetName $appgwSubnetName -httpsListenerNames @($processedListeners) -listenerHostName $listenerHostName -backendPoolHostName $backendPoolHostName -backendIpAddress $backendIpAddress -healthProbeHostName $healthProbeHostName -healthProbePath $healthProbePath"
$appgwDeployCommand = "/AppGW/$appgwTemplateFileName.ps1 -rg $resourceGroup -fpath $templatesFolderPath -deployFileName $appgwTemplateFileName $appgwParameters"
$appgwDeployPath = $templatesFolderPath + $appgwDeployCommand
Invoke-Expression -Command $appgwDeployPath

$applicationGateway = Get-AzApplicationGateway -Name $appgwName -ResourceGroupName $resourceGroup
if (!$applicationGateway)
{

      Write-Host "Error fetching Application Gateway"
      return;

}

$backendPoolName  = $appgwName + "-bkend-pool"
$backendPool = Get-AzApplicationGatewayBackendAddressPool -Name $backendPoolName `
-ApplicationGateway $applicationGateway

$frontendIPConfigName = $appgwName + "-fre-ipc"
$frontendIPConfig = Get-AzApplicationGatewayFrontendIPConfig -Name $frontendIPConfigName `
-ApplicationGateway $applicationGateway

$frontendPortName = $appgwName + "-http-port"
Add-AzApplicationGatewayFrontendPort -Name $frontendPortName `
-ApplicationGateway $applicationGateway -Port 80

$frontendPort = Get-AzApplicationGatewayFrontendPort -Name $frontendPortName `
-ApplicationGateway $applicationGateway

foreach ($listener in $httpListeners)
{

      $backendHttpSettingsName = $listener + "-" + $appgwName + "-bkend-http-settings"
      $backendHttpSettings = Get-AzApplicationGatewayBackendHttpSetting -Name $backendHttpSettingsName `
      -ApplicationGateway $applicationGateway

      $httpListenerName = $listener + "-" + $appgwName + "-http-listener"
      $httpListenerHostName = $listener + $listenerHostName

      $httpListener = Get-AzApplicationGatewayHttpListener -Name $httpListenerName `
      -ApplicationGateway $applicationGateway

      if (!$httpListener)
      {

            Add-AzApplicationGatewayHttpListener -Name $httpListenerName `
            -ApplicationGateway $applicationGateway -Protocol "Http" `
            -FrontendPort $frontendPort -HostName $httpListenerHostName `
            -FrontendIPConfiguration $frontendIPConfig

            $httpListener = Get-AzApplicationGatewayHttpListener -Name $httpListenerName `
            -ApplicationGateway $applicationGateway

      }

      $httpRuleName = $listener + "-" + $appgwName + "-http-rule"

      $httpRule = Get-AzApplicationGatewayRequestRoutingRule -Name $httpRuleName `
      -ApplicationGateway $applicationGateway

      if (!$httpRule)
      {

            Add-AzApplicationGatewayRequestRoutingRule -Name $httpRuleName `
            -ApplicationGateway $applicationGateway -RuleType "Basic" `
            -BackendHttpSettings $backendHttpSettings -HttpListener $httpListener `
            -BackendAddressPool $backendPool

      }
}

Set-AzApplicationGateway -ApplicationGateway $applicationGateway

Write-Host "-----------Post-Config------------"
