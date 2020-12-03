param([Parameter(Mandatory=$true)] [string] $resourceGroup,
      [Parameter(Mandatory=$true)] [string] $clusterName,
      [Parameter(Mandatory=$true)] [bool]   $shouldEnable,
      [Parameter(Mandatory=$true)] [array]  $ipAddressList)

$aksUpdateCommand = "az aks update -g $resourceGroup -n $clusterName --api-server-authorized-ip-ranges="
$ipAddressString = '""'

if ($shouldEnable -eq $false)
{
    $aksUpdateCommand = $aksUpdateCommand + $ipAddressString
}
else
{
    
    $ipAddressString = $ipAddressList -join ","
    $aksUpdateCommand = $aksUpdateCommand + $ipAddressString

}

Write-Host $aksUpdateCommand
Invoke-Expression -Command $aksUpdateCommand