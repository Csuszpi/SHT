# Adat bekérése és változóba mentése
$username1 = Read-Host "Kérem, adja meg a felhasználónevet"
$pw1 = Read-Host "Kérem, adja meg a jelszót"

# Adatok titkosítása
$securePassword = ConvertTo-SecureString -String "$pw1" -AsPlainText -Force

# Adatok kiírása egy fájlba
$securePassword | ConvertFrom-SecureString | Out-File -FilePath ".\encrypted_data.txt"

# Adatok beolvasása
$encryptedData = Get-Content -Path ".\encrypted_data.txt" | ConvertTo-SecureString

# Felhasználói név és jelszó kiolvasása
$username = $username1
$password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($encryptedData))

# Használat
Write-Host "Felhasználónév: $username"
Write-Host "Jelszó: $password"
