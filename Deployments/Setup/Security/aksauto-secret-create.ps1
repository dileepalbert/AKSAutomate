param([Parameter(Mandatory=$true)]    [string] $secretName,
        [Parameter(Mandatory=$true)]  [array]  $secretKeys,
        [Parameter(Mandatory=$true)]  [array]  $secretValues,
        [Parameter(Mandatory=$true)]  [string] $namespaceName,
        [Parameter(Mandatory=$false)] [bool]   $isDockerSecret = $false)

$index = 0
$secretTokensList = [System.Collections.ArrayList]@()

$secretName = "'" + $secretName + "'"
$secretNameCommand = "kubectl get secrets -n $namespaceName -o=jsonpath=""{.items[?(@.metadata.name==$secretName)].metadata.name}"""
$existingSecretName = Invoke-Expression -Command $secretNameCommand 
$existingSecretName = "'" + $existingSecretName + "'"

if ($existingSecretName -eq $secretName)
{
    return;
}

if ($isDockerSecret -eq $true)
{
        foreach($key in $secretKeys)
        {
                $tokens = "--" + $key + "=" + "'" + $secretValues[$index++] + "'"
                $secretTokensList.Add($tokens)
        }

        $secretTokens = $secretTokensList -join " "
        $dockerSecretCommand = "kubectl create secret docker-registry $secretName $secretTokens -n $namespaceName"
        Invoke-Expression -Command $dockerSecretCommand 
}
else
{
        foreach($key in $secretKeys)
        {
                $tokens = "--from-literal=" + $key + "=" + "'" + $secretValues[$index++] + "'"
                $secretTokensList.Add($tokens)
        }

        $secretTokens =  $secretTokensList -join " "
        $genericSecretCommand = "kubectl create secret generic $secretName $secretTokens -n $namespaceName"
        Invoke-Expression -Command $genericSecretCommand 

}

