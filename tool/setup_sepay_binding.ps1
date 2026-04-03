param(
  [string]$ProjectId = "g13pals",
  [string]$ApiKey = "",
  [string]$Email = "seed@g13money.com",
  [string]$Password = "12345678",
  [string]$AccountNumber = "123456789",
  [string]$BankCode = "VCB",
  [string]$WalletId = "acc_vcb",
  [string]$WalletName = "Vietcombank",
  [string]$CategoryId = "cat_salary",
  [string]$CategoryName = "Luong",
  [string]$BindingId = "binding_seed_vcb"
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($ApiKey)) {
  throw "ApiKey is required. Pass it via -ApiKey."
}

function Convert-ToFirestoreValue {
  param([Parameter(ValueFromPipeline = $true)] $Value)

  if ($null -eq $Value) {
    return @{ nullValue = "NULL_VALUE" }
  }

  if ($Value -is [string]) {
    return @{ stringValue = $Value }
  }

  if ($Value -is [bool]) {
    return @{ booleanValue = $Value }
  }

  if ($Value -is [int] -or $Value -is [long]) {
    return @{ integerValue = "$Value" }
  }

  if ($Value -is [double] -or $Value -is [float] -or $Value -is [decimal]) {
    return @{ doubleValue = [double]$Value }
  }

  if ($Value -is [datetime]) {
    $utc = $Value.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    return @{ timestampValue = $utc }
  }

  if ($Value -is [System.Collections.IDictionary]) {
    $fields = @{}
    foreach ($key in $Value.Keys) {
      $fields[$key] = Convert-ToFirestoreValue -Value $Value[$key]
    }
    return @{ mapValue = @{ fields = $fields } }
  }

  if ($Value -is [System.Collections.IEnumerable] -and -not ($Value -is [string])) {
    $arr = @()
    foreach ($item in $Value) {
      $arr += ,(Convert-ToFirestoreValue -Value $item)
    }
    return @{ arrayValue = @{ values = $arr } }
  }

  return @{ stringValue = "$Value" }
}

function Convert-ToFirestoreFields {
  param([hashtable]$Data)
  $fields = @{}
  foreach ($key in $Data.Keys) {
    $fields[$key] = Convert-ToFirestoreValue -Value $Data[$key]
  }
  return $fields
}

function Invoke-FirestorePatch {
  param(
    [string]$DocPath,
    [hashtable]$Data,
    [string]$IdToken,
    [string]$ProjectId
  )

  $url = "https://firestore.googleapis.com/v1/projects/$ProjectId/databases/(default)/documents/$DocPath"
  $body = @{ fields = (Convert-ToFirestoreFields -Data $Data) } | ConvertTo-Json -Depth 20

  Invoke-RestMethod -Method Patch -Uri $url -Headers @{ Authorization = "Bearer $IdToken" } -ContentType "application/json" -Body $body | Out-Null
}

function Get-IdToken {
  param(
    [string]$ApiKey,
    [string]$Email,
    [string]$Password
  )

  $signInUrl = "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$ApiKey"
  $authPayload = @{ email = $Email; password = $Password; returnSecureToken = $true } | ConvertTo-Json
  $signIn = Invoke-RestMethod -Method Post -Uri $signInUrl -ContentType "application/json" -Body $authPayload
  return @{ IdToken = $signIn.idToken; Uid = $signIn.localId }
}

$auth = Get-IdToken -ApiKey $ApiKey -Email $Email -Password $Password
$uid = $auth.Uid
$idToken = $auth.IdToken
$now = Get-Date

Invoke-FirestorePatch -ProjectId $ProjectId -IdToken $idToken -DocPath "sepay_bindings/$BindingId" -Data @{
  uid = $uid
  accountNumber = $AccountNumber
  bankCode = $BankCode
  walletId = $WalletId
  walletName = $WalletName
  categoryId = $CategoryId
  categoryName = $CategoryName
  active = $true
  updatedAt = $now
  createdAt = $now
}

Write-Output "SePay binding upserted successfully."
Write-Output "UID: $uid"
Write-Output "BindingId: $BindingId"
Write-Output "AccountNumber: $AccountNumber"
