### Passwords & Credentials ###

# Create credential object using GUI
$MyCredential = Get-Credential
$MyCredential.UserName
$MyCredential.Password

# Read input and hide text
$user = Read-Host "Enter Username"
$pass = Read-Host "Enter Password" -AsSecureString

# Store string as password
$pw = "1qaz2wsx" | ConvertTo-SecureString -AsPlainText -Force

# Using AES key file
$AESKey = New-Object Byte[] 32
[Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($AESKey)
Set-Content $aesKeyFile $AESKey
$pw = Read-Host "Enter Password" -AsSecureString | ConvertFrom-SecureString -Key $AESKey
Add-Content $pwdFile $pw
# Read in credential file, decrypt password.
$securePwd = Get-Content $pwdFile | ConvertTo-SecureString -Key $(Get-Content $aesKeyFile)
$credObject = New-Object System.Management.Automation.PSCredential -ArgumentList $un, $securePwd
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecurePwd)
$pw = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

