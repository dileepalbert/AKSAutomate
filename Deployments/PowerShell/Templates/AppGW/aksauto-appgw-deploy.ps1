param([Parameter(Mandatory=$false)] [string] $rg,
      [Parameter(Mandatory=$false)] [string] $fpath,
      [Parameter(Mandatory=$false)] [string] $deployFileName,
      [Parameter(Mandatory=$false)] [string] $vnetName,
      [Parameter(Mandatory=$false)] [string] $subnetName,
      [Parameter(Mandatory=$false)] [string] $appgwName,
      [Parameter(Mandatory=$false)] [array]  $httpsListenerNames,
      [Parameter(Mandatory=$false)] [string] $listenerHostName,
      [Parameter(Mandatory=$false)] [string] $backendPoolHostName,
      [Parameter(Mandatory=$false)] [string] $backendIpAddress,      
      [Parameter(Mandatory=$false)] [string] $healthProbeHostName,
      [Parameter(Mandatory=$false)] [string] $healthProbePath,
      [Parameter(Mandatory=$false)] [string] $certDataSecured,
      [Parameter(Mandatory=$false)] [string] $certSecretSecured)

$certData = $certDataSecured | ConvertTo-SecureString -AsPlainText -Force
$certPassword = $certSecretSecured | ConvertTo-SecureString -AsPlainText -Force

Test-AzResourceGroupDeployment -ResourceGroupName $rg `
-TemplateFile "$fpath/AppGW/$deployFileName.tls.json" `
-TemplateParameterFile "$fpath/AppGW/$deployFileName.tls.parameters.json" `
-applicationGatewayName $appgwName `
-vnetName $vnetName -subnetName $subnetName `
-httpsListenerNames $httpsListenerNames `
-listenerHostName $listenerHostName `
-backendPoolHostName $backendPoolHostName `
-backendIpAddress $backendIpAddress `
-backendProtocol "Https" `
-backendPort 443 `
-healthProbeHostName $healthProbeHostName `
-healthProbePath $healthProbePath `
-certData $certData -certPassword $certPassword

New-AzResourceGroupDeployment -ResourceGroupName $rg `
-TemplateFile "$fpath/AppGW/$deployFileName.tls.json" `
-TemplateParameterFile "$fpath/AppGW/$deployFileName.tls.parameters.json" `
-applicationGatewayName $appgwName `
-vnetName $vnetName -subnetName $subnetName `
-httpsListenerNames $httpsListenerNames `
-listenerHostName $listenerHostName `
-backendPoolHostName $backendPoolHostName `
-backendIpAddress $backendIpAddress `
-backendProtocol "Https" `
-backendPort 443 `
-healthProbeHostName $healthProbeHostName `
-healthProbePath $healthProbePath `
-certData $certData -certPassword $certPassword