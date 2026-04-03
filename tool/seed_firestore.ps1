param(
  [string]$ProjectId = "g13pals",
  [string]$ApiKey = "",
  [string]$Email = "seed@g13money.com",
  [string]$Password = "12345678"
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
  $body = @{ fields = (Convert-ToFirestoreFields -Data $Data) } | ConvertTo-Json -Depth 30

  Invoke-RestMethod -Method Patch -Uri $url -Headers @{ Authorization = "Bearer $IdToken" } -ContentType "application/json" -Body $body | Out-Null
}

function Get-IdToken {
  param(
    [string]$ApiKey,
    [string]$Email,
    [string]$Password
  )

  $signInUrl = "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$ApiKey"
  $signUpUrl = "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$ApiKey"
  $authPayload = @{ email = $Email; password = $Password; returnSecureToken = $true } | ConvertTo-Json

  try {
    $signIn = Invoke-RestMethod -Method Post -Uri $signInUrl -ContentType "application/json" -Body $authPayload
    return @{ IdToken = $signIn.idToken; Uid = $signIn.localId; Mode = "signin" }
  }
  catch {
    try {
      $signUp = Invoke-RestMethod -Method Post -Uri $signUpUrl -ContentType "application/json" -Body $authPayload
      return @{ IdToken = $signUp.idToken; Uid = $signUp.localId; Mode = "signup" }
    }
    catch {
      $responseBody = $null
      if ($_.Exception.Response -and $_.Exception.Response.GetResponseStream()) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $responseBody = $reader.ReadToEnd()
      }
      if ($responseBody) {
        Write-Warning "Email/password auth unavailable: $responseBody"
      }

      # Fallback: anonymous auth token (creates an anonymous Firebase user)
      $anonymousPayload = @{ returnSecureToken = $true } | ConvertTo-Json
      $anonymousSignUp = Invoke-RestMethod -Method Post -Uri $signUpUrl -ContentType "application/json" -Body $anonymousPayload
      return @{ IdToken = $anonymousSignUp.idToken; Uid = $anonymousSignUp.localId; Mode = "anonymous" }
    }
  }
}

$auth = Get-IdToken -ApiKey $ApiKey -Email $Email -Password $Password
$idToken = $auth.IdToken
$uid = $auth.Uid
$now = Get-Date
$yearMonth = "{0:D4}-{1:D2}" -f $now.Year, $now.Month

Invoke-FirestorePatch -ProjectId $ProjectId -IdToken $idToken -DocPath "users/$uid" -Data @{
  fullName = "G13 Demo User"
  email = $Email
  phone = "0900000000"
  avatarInitials = "GD"
  currency = "VND"
  locale = "vi"
  joinedAt = $now
  createdAt = $now
  updatedAt = $now
}

Invoke-FirestorePatch -ProjectId $ProjectId -IdToken $idToken -DocPath "users/$uid/accounts/acc_cash" -Data @{
  name = "Tien mat"
  type = "cash"
  balance = 2500000
  colorHex = "#F2994A"
  isArchived = $false
  createdAt = $now
  updatedAt = $now
}

Invoke-FirestorePatch -ProjectId $ProjectId -IdToken $idToken -DocPath "users/$uid/accounts/acc_vcb" -Data @{
  name = "Vietcombank"
  type = "bank"
  balance = 12000000
  colorHex = "#27AE60"
  isArchived = $false
  createdAt = $now
  updatedAt = $now
}

Invoke-FirestorePatch -ProjectId $ProjectId -IdToken $idToken -DocPath "users/$uid/categories/cat_food" -Data @{
  name = "An uong"
  type = "expense"
  iconKey = "restaurant"
  colorHex = "#E07A5F"
  isDefault = $true
  createdAt = $now
  updatedAt = $now
}

Invoke-FirestorePatch -ProjectId $ProjectId -IdToken $idToken -DocPath "users/$uid/categories/cat_salary" -Data @{
  name = "Luong"
  type = "income"
  iconKey = "payments"
  colorHex = "#22B45E"
  isDefault = $true
  createdAt = $now
  updatedAt = $now
}

Invoke-FirestorePatch -ProjectId $ProjectId -IdToken $idToken -DocPath "users/$uid/categories/cat_transport" -Data @{
  name = "Di chuyen"
  type = "expense"
  iconKey = "directions_car"
  colorHex = "#4E79A7"
  isDefault = $true
  createdAt = $now
  updatedAt = $now
}

Invoke-FirestorePatch -ProjectId $ProjectId -IdToken $idToken -DocPath "users/$uid/categories/cat_shopping" -Data @{
  name = "Mua sam"
  type = "expense"
  iconKey = "shopping_bag"
  colorHex = "#B07AA1"
  isDefault = $true
  createdAt = $now
  updatedAt = $now
}

Invoke-FirestorePatch -ProjectId $ProjectId -IdToken $idToken -DocPath "users/$uid/categories/cat_home" -Data @{
  name = "Nha cua"
  type = "expense"
  iconKey = "home"
  colorHex = "#9C755F"
  isDefault = $true
  createdAt = $now
  updatedAt = $now
}

Invoke-FirestorePatch -ProjectId $ProjectId -IdToken $idToken -DocPath "users/$uid/categories/cat_bonus" -Data @{
  name = "Thuong"
  type = "income"
  iconKey = "card_giftcard"
  colorHex = "#59A14F"
  isDefault = $true
  createdAt = $now
  updatedAt = $now
}

Invoke-FirestorePatch -ProjectId $ProjectId -IdToken $idToken -DocPath "users/$uid/categories/cat_investment" -Data @{
  name = "Dau tu"
  type = "income"
  iconKey = "trending_up"
  colorHex = "#2EC4B6"
  isDefault = $true
  createdAt = $now
  updatedAt = $now
}

Invoke-FirestorePatch -ProjectId $ProjectId -IdToken $idToken -DocPath "users/$uid/transactions/txn_income_seed_001" -Data @{
  title = "Luong thang"
  note = "Seed data"
  amount = 12000000
  type = "income"
  isIncome = $true
  categoryId = "cat_salary"
  categoryName = "Luong"
  walletId = "acc_vcb"
  walletName = "Vietcombank"
  date = (Get-Date -Year $now.Year -Month $now.Month -Day 1)
  attachmentUrls = @()
  tags = @("seed")
  year = $now.Year
  month = $now.Month
  day = 1
  yearMonth = $yearMonth
  createdAt = $now
  updatedAt = $now
}

Invoke-FirestorePatch -ProjectId $ProjectId -IdToken $idToken -DocPath "users/$uid/GiaoDich/txn_income_seed_001" -Data @{
  title = "Luong thang"
  note = "Seed data"
  amount = 12000000
  type = "income"
  isIncome = $true
  categoryId = "cat_salary"
  categoryName = "Luong"
  walletId = "acc_vcb"
  walletName = "Vietcombank"
  date = (Get-Date -Year $now.Year -Month $now.Month -Day 1)
  attachmentUrls = @()
  tags = @("seed")
  year = $now.Year
  month = $now.Month
  day = 1
  yearMonth = $yearMonth
  createdAt = $now
  updatedAt = $now
}

Invoke-FirestorePatch -ProjectId $ProjectId -IdToken $idToken -DocPath "users/$uid/transactions/txn_expense_seed_001" -Data @{
  title = "An uong"
  note = "Seed data"
  amount = 180000
  type = "expense"
  isIncome = $false
  categoryId = "cat_food"
  categoryName = "An uong"
  walletId = "acc_cash"
  walletName = "Tien mat"
  date = (Get-Date -Year $now.Year -Month $now.Month -Day 2)
  attachmentUrls = @()
  tags = @("seed")
  year = $now.Year
  month = $now.Month
  day = 2
  yearMonth = $yearMonth
  createdAt = $now
  updatedAt = $now
}

Invoke-FirestorePatch -ProjectId $ProjectId -IdToken $idToken -DocPath "users/$uid/GiaoDich/txn_expense_seed_001" -Data @{
  title = "An uong"
  note = "Seed data"
  amount = 180000
  type = "expense"
  isIncome = $false
  categoryId = "cat_food"
  categoryName = "An uong"
  walletId = "acc_cash"
  walletName = "Tien mat"
  date = (Get-Date -Year $now.Year -Month $now.Month -Day 2)
  attachmentUrls = @()
  tags = @("seed")
  year = $now.Year
  month = $now.Month
  day = 2
  yearMonth = $yearMonth
  createdAt = $now
  updatedAt = $now
}

Invoke-FirestorePatch -ProjectId $ProjectId -IdToken $idToken -DocPath "users/$uid/budgets/budget_food_seed_001" -Data @{
  title = "An uong thang nay"
  categoryId = "cat_food"
  categoryName = "An uong"
  walletId = "ALL"
  walletName = "Tat ca vi"
  limit = 3000000
  spent = 180000
  startDate = (Get-Date -Year $now.Year -Month $now.Month -Day 1)
  endDate = (Get-Date -Year $now.Year -Month $now.Month -Day ([DateTime]::DaysInMonth($now.Year, $now.Month)))
  periodKey = $yearMonth
  colorHex = "#E07A5F"
  iconKey = "restaurant"
  isActive = $true
  createdAt = $now
  updatedAt = $now
}

Invoke-FirestorePatch -ProjectId $ProjectId -IdToken $idToken -DocPath "users/$uid/notifications/noti_seed_001" -Data @{
  type = "system"
  title = "Khoi tao du lieu mau"
  body = "Da tao thanh cong collection Firestore cho nguoi dung demo."
  isRead = $false
  meta = @{ source = "seed_script" }
  createdAt = $now
}

Invoke-FirestorePatch -ProjectId $ProjectId -IdToken $idToken -DocPath "users/$uid/settings/profile" -Data @{
  fullName = "G13 Demo User"
  phone = "0900000000"
  avatarUrl = ""
  updatedAt = $now
}

Invoke-FirestorePatch -ProjectId $ProjectId -IdToken $idToken -DocPath "users/$uid/settings/preferences" -Data @{
  language = "vi"
  themeMode = "system"
  budgetAlerts = $true
  dailyReminder = $false
  billReminder = $false
  updatedAt = $now
}

Write-Output "Seed Firestore completed."
Write-Output "Auth mode: $($auth.Mode)"
Write-Output "UID: $uid"
Write-Output "Email: $Email"
