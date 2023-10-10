# Get an access token
$tenantId = "<Your Azure AD tenant ID>"
$appId = "<Your app ID>"
$appSecret = "<Your app secret>"
$body = @{
    grant_type    = "client_credentials"
    client_id     = $appId
    client_secret = $appSecret
    resource      = "https://graph.microsoft.com"
}
$tokenResponse = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$tenantId/oauth2/token" -Method Post -Body $body
$accessToken = $tokenResponse.access_token

# Upload the CSV file
$csvContent = Get-Content -Path "C:\HWID\AutopilotHWID.csv" -Raw
$encodedCsvContent = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($csvContent))
$uri = "https://graph.microsoft.com/beta/deviceManagement/importedWindowsAutopilotDeviceIdentities/import"
$body = @{
    importedWindowsAutopilotDeviceIdentities = @(
        @{
            deviceName = "<Device name>"
            hardwareIdentifier = $encodedCsvContent
        }
    )
}
$headers = @{
    Authorization = "Bearer $accessToken"
    "Content-Type" = "application/json"
}
Invoke-RestMethod -Uri $uri -Method Post -Body ($body | ConvertTo-Json) -Headers $headers

$deviceSerialNumber = "<Device Serial Number>"

# Create the device enrollment
$uri = "https://graph.microsoft.com/beta/deviceManagement/importedAppleDeviceIdentities"
$body = @{
    serialNumber = $deviceSerialNumber
    orderIdentifier = "<Order Identifier>"
}

$headers = @{
    Authorization = "Bearer $accessToken"
    "Content-Type" = "application/json"
}

Invoke-RestMethod -Uri $uri -Method Post -Body ($body | ConvertTo-Json) -Headers $headers
