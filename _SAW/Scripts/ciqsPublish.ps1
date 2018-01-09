param (
    [Parameter(Mandatory = $true)]
    [string]$template,
    [Parameter(Mandatory = $true)]
    [string]$solutionStorageConnectionString,
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

$tenantId = (Get-AzureRmContext).Tenant.TenantId
$subscription = (Get-AzureRmContext).Subscription.SubscriptionId
$token = Get-AccessToken $tenantId

$header = @{
    'Content-Type'  = 'application\json'
    'Authorization' = "Bearer $token"
    'SolutionStorageConnectionString' = $solutionStorageConnectionString
}

Invoke-RestMethod "${endpoint}api/template/publish/${template}/assetupload" -Headers $header -Method POST -ContentType "application/json"

do
{
    Sleep -m 5000
    $publishStatus = Invoke-RestMethod "${endpoint}api/template/publish/${template}/assetupload" -Headers $header -Method GET -ContentType "application/json"
    $publishStatus
    $status = $publishStatus.Status
}
while ($status -notlike 'complete' -and $status -notlike 'unauthorized')

if ($status -eq 'complete') {
    Write-Host "Published!"
} else {
    Write-Host $publishStatus.Info
}
