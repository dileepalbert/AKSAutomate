param([Parameter(Mandatory=$true)] [string] $secretName,      
        [Parameter(Mandatory=$true)] [string] $namespaceName)

$secretName = "'" + $secretName + "'"
$secretNameCommand = "kubectl get secrets -n $namespaceName -o=jsonpath=""{.items[?(@.metadata.name==$secretName)].metadata.name}"""
$existingSecretName = Invoke-Expression -Command $secretNameCommand 
$existingSecretName = "'" + $existingSecretName + "'"

if ($existingSecretName -ne $secretName)
{
    return;
}

$deleteDockerSecretCommand = "kubectl delete secrets/$secretName -n $namespaceName"
Invoke-Expression -Command $deleteDockerSecretCommand