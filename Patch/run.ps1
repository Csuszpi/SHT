# Karakterkódolás beállítása UTF-8-ra
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Alapvető jumphostok definíciója
$DC01JH = "ss01afrrundeck02"
$DC02JH = "jumphostdc2.sf.priv"
$DC03JH = "jumphostdc3.sf.priv"
$server_name = '$server_name'

$file_rm = "generalt_kod.txt"
Write-Host "------------------------------------------------------------" -ForegroundColor DarkMagenta
if (Test-Path $file_rm) {
    Remove-Item $file_rm -Force
    Write-Host "Elozo $file_rm sikeresen torolve."
}
Write-Host "------------------------------------------------------------" -ForegroundColor DarkMagenta

# Hostlist.txt beolvasása
$hostList = Get-Content -Path ".\hostlist.txt"

# Assoc array inicializálása a jumphostokhoz tartozó szerverek tárolásához
$jumphostToServers = @{}

# Szerverek párosítása a megfelelő jumphostokhoz
foreach ($server in $hostList) {
    $jumphost = ""
    
    if ($server -match "dc01") {
        $jumphost = $DC01JH
    } elseif ($server -match "dc02") {
        $jumphost = $DC02JH
    } elseif ($server -match "dc03") {
        $jumphost = $DC03JH
    } else {
        Write-Host "Nem talalhato megfelelo jumphost a(z) $server szerverhez." -ForegroundColor Red
        continue
    }

    # Szerverek hozzáadása a jumphosthoz az assoc array-hez
    if (-not $jumphostToServers.ContainsKey($jumphost)) {
        $jumphostToServers[$jumphost] = @()
    }
    $jumphostToServers[$jumphost] += $server

    # Kiírja a konzolra, hogy melyik DC-jumphost-hoz lett párosítva a szerver
    Write-Host "$server szerver parositva lett $jumphost DC-jumphost-hoz."
}

# Linux parancsok generálása és elmentése
$finalLinuxCommand = 'server_name=$(hostname); if '

# Ellenőrzi, hogy a jelenlegi jumphost az utolsó-e
$isLastJumphost = $false

foreach ($jumphost in $jumphostToServers.Keys) {
    $servers = $jumphostToServers[$jumphost] -join " "

    # Linux parancs generálása
    $linuxCommand = @"
[ "$server_name" == "$jumphost" ]; then sudo su - deployer -c "knife ssh -m '$servers' \"sudo less /opt/Tanium/TaniumClient/Tools/Patch/logs/patch-process.log | grep 'All update successfully installed.'\" && exit";
"@

    # Parancs hozzáadása a végleges parancshoz
    $finalLinuxCommand += $linuxCommand

    # Ha a következő jumphost után van még egy másik jumphost, akkor hozzáadja az "elif"-et
    if ($isLastJumphost -eq $false) {
        $finalLinuxCommand += " elif "
    }

    # Ellenőrzi, hogy a jelenlegi jumphost az utolsó-e
    $isLastJumphost = $true
}

# Végleges parancs lezárása a "fi" után
$finalLinuxCommand += " fi"

# Parancs elmentése a txt fájlba
$outputFileName = "generalt_kod.txt"
$finalLinuxCommand | Out-File -FilePath $outputFileName -Encoding utf8

Write-Host "------------------------------------------------------------" -ForegroundColor DarkMagenta
Write-Host "Linux parancs elkeszult es el lett mentve a $outputFileName fajlba." -ForegroundColor DarkGreen
Write-Host "------------------------------------------------------------" -ForegroundColor DarkMagenta

# Kiírja a konzolra, hogy melyik DC-jumphostokat kell indítani
foreach ($dcJumphost in ($jumphostToServers.Keys | Select-Object -Unique)) {
    $jumphostNumber = $dcJumphost -replace 'jumphostdc(\d+)\.sf\.priv', '$1'
    $dcNumber = $jumphostNumber -replace 'ss(\d+)afrrundeck\d+', '$1'
    Write-Host "Inditsd el a DC$dcNumber-es jumphost-ot." -ForegroundColor Green
}
Write-Host "------------------------------------------------------------" -ForegroundColor DarkMagenta