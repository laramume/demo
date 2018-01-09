param (
    [Parameter(Mandatory = $true)]
    [string]$deploymentName,
    [switch]$noWait = $false,
    [string]$endpoint = "https://ciqs-api-westus.azurewebsites.net/"
)

$ErrorActionPreference = 'Stop'

function Get-AccessToken($tenantId) {
    $cache = [Microsoft.IdentityModel.Clients.ActiveDirectory.TokenCache]::DefaultShared
    $cacheItem = $cache.ReadItems() | Where {$_.TenantId -eq $tenantId} | Select-Object -First 1
    if ($cacheItem -eq $null) {
        $cacheItem = $cache.ReadItems() | Select-Object -First 1
    }
    
    return $cacheItem.AccessToken
}

function WaitForDeployment {
    param
    (
        [Parameter(Mandatory = $true)]
        $Subscrption,
         
        [Parameter(Mandatory = $true)]
        $UniqueId 
    )

    do
    {
        Start-Sleep -m 1000
        $deploymentDetails = Invoke-RestMethod "${endpoint}api/deployments/${Subscription}/${UniqueId}" -Headers $header -Method GET -ContentType "application/json"
        $deployment = $deploymentDetails.deployment
        $provisioningSteps = $deploymentDetails.provisioningSteps
        $status = $deployment.status
        

        if ($provisioningSteps -ne $null) {
            $currentProvisioningStep = $provisioningSteps[$deployment.currentProvisioningStep]                
            $message = $currentProvisioningStep.Title
            if ($status -notlike 'ready') {
                $message = "$message..."
            } else {
                $message = "$message!"
            }
        } else {
            $message = "Deployment is being created..."
        }

        if ($oldMessage -ne $message) {
            Write-Host $message
        }

        $oldMessage = $message
    }
    while ($status -notlike 'failed' -and $status -notlike 'actionRequired' -and $status -notlike 'ready' -and $status -notlike 'deleted')
    
    return $deploymentDetails
}

$tenantId = (Get-AzureRmContext).Tenant.TenantId
$subscription = (Get-AzureRmContext).Subscription.SubscriptionId
$token = Get-AccessToken $tenantId

$header = @{
    'Content-Type'  = 'application\json'
    'Authorization' = "Bearer $token"
}

$deployments = Invoke-RestMethod "${endpoint}api/deployments/${subscription}" -Headers $header -Method GET -ContentType "application/json"

$deployment = $deployments | Where {$_. Name -eq $deploymentName} | Select-Object -First 1

$uniqueId = $deployment.uniqueId

Write-Host "Deleting deployment ${deploymentName}/${uniqueid}"

$ignore = Invoke-RestMethod "${endpoint}api/deployments/${subscription}/${uniqueId}" -Headers $header -Method DELETE -ContentType "application/json"

if ($noWait -eq $false) {
    $deploymentDetails = WaitForDeployment -Subscrption $subscription -UniqueId $uniqueId
    $deploymentDetails.deployment.status
}