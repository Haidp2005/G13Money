param(
  [Parameter(Mandatory = $true)]
  [string]$ProjectId,

  [Parameter(Mandatory = $true)]
  [string]$ServiceAccountJsonPath,

  [Parameter(Mandatory = $true)]
  [string]$DeviceToken,

  [string]$Title = "G13 Money",
  [string]$Body = "Thong bao thu nghiem tu FCM"
)

$ErrorActionPreference = 'Stop'

function Convert-ToBase64Url([byte[]]$bytes) {
  $base64 = [Convert]::ToBase64String($bytes)
  return $base64.TrimEnd('=').Replace('+', '-').Replace('/', '_')
}

function New-Jwt {
  param(
    [string]$ClientEmail,
    [string]$PrivateKeyPem,
    [string]$Scope,
    [string]$Audience
  )

  $header = @{ alg = 'RS256'; typ = 'JWT' } | ConvertTo-Json -Compress

  $now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
  $payload = @{
    iss = $ClientEmail
    scope = $Scope
    aud = $Audience
    iat = $now
    exp = $now + 3600
  } | ConvertTo-Json -Compress

  $headerB64 = Convert-ToBase64Url([Text.Encoding]::UTF8.GetBytes($header))
  $payloadB64 = Convert-ToBase64Url([Text.Encoding]::UTF8.GetBytes($payload))
  $unsignedJwt = "$headerB64.$payloadB64"

  $privateKey = [System.Security.Cryptography.RSA]::Create()
  $privateKey.ImportFromPem($PrivateKeyPem)

  $signatureBytes = $privateKey.SignData(
    [Text.Encoding]::UTF8.GetBytes($unsignedJwt),
    [System.Security.Cryptography.HashAlgorithmName]::SHA256,
    [System.Security.Cryptography.RSASignaturePadding]::Pkcs1
  )

  $signatureB64 = Convert-ToBase64Url($signatureBytes)
  return "$unsignedJwt.$signatureB64"
}

if (!(Test-Path $ServiceAccountJsonPath)) {
  throw "Service account file not found: $ServiceAccountJsonPath"
}

$serviceAccount = Get-Content $ServiceAccountJsonPath -Raw | ConvertFrom-Json
$jwt = New-Jwt \
  -ClientEmail $serviceAccount.client_email \
  -PrivateKeyPem $serviceAccount.private_key \
  -Scope 'https://www.googleapis.com/auth/firebase.messaging' \
  -Audience 'https://oauth2.googleapis.com/token'

$tokenResponse = Invoke-RestMethod \
  -Method Post \
  -Uri 'https://oauth2.googleapis.com/token' \
  -ContentType 'application/x-www-form-urlencoded' \
  -Body "grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=$jwt"

$accessToken = $tokenResponse.access_token

$message = @{
  message = @{
    token = $DeviceToken
    notification = @{
      title = $Title
      body = $Body
    }
    android = @{
      priority = 'high'
      notification = @{
        channel_id = 'g13money_default_channel'
      }
    }
    data = @{
      source = 'manual-test'
      sentAt = (Get-Date).ToUniversalTime().ToString('o')
    }
  }
} | ConvertTo-Json -Depth 10

$fcmEndpoint = "https://fcm.googleapis.com/v1/projects/$ProjectId/messages:send"

$response = Invoke-RestMethod \
  -Method Post \
  -Uri $fcmEndpoint \
  -Headers @{ Authorization = "Bearer $accessToken" } \
  -ContentType 'application/json' \
  -Body $message

Write-Output "Push sent successfully"
Write-Output ($response | ConvertTo-Json -Depth 5)
