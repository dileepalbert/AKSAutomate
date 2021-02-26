param([Parameter(Mandatory=$false)] [string] $rg,
      [Parameter(Mandatory=$false)] [string] $fpath,
      [Parameter(Mandatory=$false)] [string] $deployFileName,
      [Parameter(Mandatory=$false)] [string] $appgwName,
      [Parameter(Mandatory=$false)] [string] $projectName,
      [Parameter(Mandatory=$false)] [string] $vnetName,
      [Parameter(Mandatory=$false)] [string] $subnetName,
      [Parameter(Mandatory=$false)] [string] $hostName,
      [Parameter(Mandatory=$false)] [string] $listenerHostName,
      [Parameter(Mandatory=$false)] [string] $backendIPAddress)

Test-AzResourceGroupDeployment -ResourceGroupName $rg `
-TemplateFile "$fpath/AppGW/$deployFileName.json" `
-TemplateParameterFile "$fpath/AppGW/$deployFileName.parameters.json" `
-applicationGatewayName $appgwName `
-projectName $projectName `
-vnetName $vnetName -subnetName $subnetName `
-backendPoolHostName $hostName -listenerHostName $listenerHostName `
-backendIpAddress1 $backendIPAddress

New-AzResourceGroupDeployment -ResourceGroupName $rg `
-TemplateFile "$fpath/AppGW/$deployFileName.json" `
-TemplateParameterFile "$fpath/AppGW/$deployFileName.parameters.json" `
-applicationGatewayName $appgwName `
-projectName $projectName `
-vnetName $vnetName -subnetName $subnetName `
-backendPoolHostName $hostName -listenerHostName $listenerHostName `
-backendIpAddress1 $backendIPAddress