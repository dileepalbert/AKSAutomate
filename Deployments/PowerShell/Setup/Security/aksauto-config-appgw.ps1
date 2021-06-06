param([Parameter(Mandatory=$true)] [string] $resourceGroup,
      [Parameter(Mandatory=$true)] [string] $keyVaultName,
      [Parameter(Mandatory=$true)] [string] $certDataSecretName,
      [Parameter(Mandatory=$true)] [string] $certSecretName,
      [Parameter(Mandatory=$true)] [string] $rootCertDataSecretName,
      [Parameter(Mandatory=$true)] [array]  $httpsListeners,
      [Parameter(Mandatory=$true)] [array]  $httpListeners,
      [Parameter(Mandatory=$true)] [string] $appgwName,  
      [Parameter(Mandatory=$true)] [string] $appgwVNetName,
      [Parameter(Mandatory=$true)] [string] $appgwSubnetName,
      [Parameter(Mandatory=$true)] [string] $appgwTemplateFileName,
      [Parameter(Mandatory=$true)] [string] $backendIpAddress,
      [Parameter(Mandatory=$true)] [string] $backendPoolHostName,
      [Parameter(Mandatory=$true)] [string] $listenerHostName,
      [Parameter(Mandatory=$true)] [string] $healthProbeHostName,
      [Parameter(Mandatory=$true)] [string] $healthProbePath,
      [Parameter(Mandatory=$true)] [string] $baseFolderPath)

$templatesFolderPath = $baseFolderPath + "/PowerShell/Templates"

$processedListeners = @()
foreach ($listener in $httpsListeners)
{
      $processedListeners += "'$listener'"
}
$processedListeners = $processedListeners -join ","

$certDataInfo = Get-AzKeyVaultSecret -VaultName $keyVaultName -Name $certDataSecretName
$certDataSecuredInfo = $certDataInfo.SecretValue | ConvertFrom-SecureString -AsPlainText

$certPasswordInfo = Get-AzKeyVaultSecret -VaultName $keyVaultName -Name $certSecretName
$certPasswordSecuredInfo = $certPasswordInfo.SecretValue | ConvertFrom-SecureString -AsPlainText

$appgwParameters = "-appgwName $appgwName -vnetName $appgwVNetName -subnetName $appgwSubnetName -httpsListenerNames @($processedListeners) -listenerHostName $listenerHostName -backendPoolHostName $backendPoolHostName -backendIpAddress $backendIpAddress -healthProbeHostName $healthProbeHostName -healthProbePath $healthProbePath"
if ($rootCertDataSecretName)
{

      $appgwParameters = $appgwParameters + " -backendProtocol Https -backendPort 443"

}

$appgwSecuredParameters = "-certDataSecured $certDataSecuredInfo -certSecretSecured $certPasswordSecuredInfo"
$appgwDeployCommand = "/AppGW/$appgwTemplateFileName.ps1 -rg $resourceGroup -fpath $templatesFolderPath -deployFileName $appgwTemplateFileName $appgwParameters $appgwSecuredParameters"
$appgwDeployPath = $templatesFolderPath + $appgwDeployCommand
Invoke-Expression -Command $appgwDeployPath

$applicationGateway = Get-AzApplicationGateway -Name $appgwName -ResourceGroupName $resourceGroup
if (!$applicationGateway)
{

      Write-Host "Error fetching Application Gateway"
      return;

}

if ($rootCertDataSecretName)
{

      $rootCertDataInfo = Get-AzKeyVaultSecret -VaultName $keyVaultName -Name $rootCertDataSecretName
      $keyvaultSecretId = $rootCertDataInfo.Id
      $appgwRootCertCommand = "az network application-gateway root-cert create --gateway-name $appgwName --name $rootCertDataSecretName --resource-group $resourceGroup --keyvault-secret $keyvaultSecretId"
      Invoke-Expression -Command $appgwRootCertCommand

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
