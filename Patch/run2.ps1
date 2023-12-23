# Karakterk�dol�s be�ll�t�sa UTF-8-ra
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Alapvet� jumphostok defin�ci�ja
$DC01JH = "ss01afrrundeck02"
$DC02JH = "jumphostdc2.sf.priv"
$DC03JH = "jumphostdc3.sf.priv"
$DC30JH = "jumphostdc30.sf.priv"
$server_name = '$server_name'

$file_rm = "generalt_kod.txt"
Write-Host "------------------------------------------------------------" -ForegroundColor DarkMagenta
if (Test-Path $file_rm) {
    Remove-Item $file_rm -Force
    Write-Host "Elozo $file_rm sikeresen torolve."
}
Write-Host "------------------------------------------------------------" -ForegroundColor DarkMagenta

# Hostlist.txt beolvas�sa
$hostList = Get-Content -Path ".\hostlist.txt"

# Assoc array inicializ�l�sa a jumphostokhoz tartoz� szerverek t�rol�s�hoz
$jumphostToServers = @{}

# Szerverek p�ros�t�sa a megfelel� jumphostokhoz
foreach ($server in $hostList) {
    $jumphost = ""
    
    if ($server -match "dc01") {
        $jumphost = $DC01JH
    } elseif ($server -match "dc02") {
        $jumphost = $DC02JH
    } elseif ($server -match "dc03") {
        $jumphost = $DC03JH
    } elseif ($server -match "dc030") {
        $jumphost = $DC30JH
    } else {
        Write-Host "Nem talalhato megfelelo jumphost a(z) $server szerverhez." -ForegroundColor Red
        continue
    }

    # Szerverek hozz�ad�sa a jumphosthoz az assoc array-hez
    if (-not $jumphostToServers.ContainsKey($jumphost)) {
        $jumphostToServers[$jumphost] = @()
    }
    $jumphostToServers[$jumphost] += $server

    # Ki�rja a konzolra, hogy melyik DC-jumphost-hoz lett p�ros�tva a szerver
    Write-Host "$server szerver parositva lett $jumphost DC-jumphost-hoz."
}

# Men� megjelen�t�se
Write-Host "V�lassz egy funkci�t:"
Write-Host "1. Volt-e patch?"
Write-Host "2. Uptime lek�rdez�s "
Write-Host "3. Mi a firmware?"
$choice = Read-Host "Add meg a v�lasztott funkci� sz�m�t (1-3):"


# Az adott funkci� szerinti k�d gener�l�sa
switch ($choice) {
    1 {
        # Linux parancsok gener�l�sa �s elment�se
        $finalLinuxCommand = 'server_name=$(hostname); if '

        # Ellen�rzi, hogy a jelenlegi jumphost az utols�-e
        $isLastJumphost = $false

        foreach ($jumphost in $jumphostToServers.Keys) {
            $servers = $jumphostToServers[$jumphost] -join " "
        
            # Linux parancs gener�l�sa
            $linuxCommand = @"
[ "$server_name" == "$jumphost" ]; then sudo su - deployer -c "knife ssh -m '$servers' \"sudo less /opt/Tanium/TaniumClient/Tools/Patch/logs/patch-process.log | grep 'All update successfully installed.'\" && exit";
"@

            # Parancs hozz�ad�sa a v�gleges parancshoz
            $finalLinuxCommand += $linuxCommand

            # Ha a k�vetkez� jumphost ut�n van m�g egy m�sik jumphost, akkor hozz�adja az "elif"-et
            if ($isLastJumphost -eq $false) {
                $finalLinuxCommand += " elif "
            }

            # Ellen�rzi, hogy a jelenlegi jumphost az utols�-e
            $isLastJumphost = $true
        }

        # V�gleges parancs lez�r�sa a "fi" ut�n
        $finalLinuxCommand += " fi"
    }
    2 {
        # Linux parancsok gener�l�sa �s elment�se
        $finalLinuxCommand = 'server_name=$(hostname); if '

        # Ellen�rzi, hogy a jelenlegi jumphost az utols�-e
        $isLastJumphost = $false

        foreach ($jumphost in $jumphostToServers.Keys) {
            $servers = $jumphostToServers[$jumphost] -join " "
        
            # Linux parancs gener�l�sa
            $linuxCommand = @"
[ "$server_name" == "$jumphost" ]; then sudo su - deployer -c "knife ssh -m '$servers' \"uptime\" && exit";
"@

            # Parancs hozz�ad�sa a v�gleges parancshoz
            $finalLinuxCommand += $linuxCommand

            # Ha a k�vetkez� jumphost ut�n van m�g egy m�sik jumphost, akkor hozz�adja az "elif"-et
            if ($isLastJumphost -eq $false) {
                $finalLinuxCommand += " elif "
            }

            # Ellen�rzi, hogy a jelenlegi jumphost az utols�-e
            $isLastJumphost = $true
        }

        # V�gleges parancs lez�r�sa a "fi" ut�n
        $finalLinuxCommand += " fi"
    }
    3 {
        # Linux parancsok gener�l�sa �s elment�se
        $finalLinuxCommand = 'server_name=$(hostname); if '

        # Ellen�rzi, hogy a jelenlegi jumphost az utols�-e
        $isLastJumphost = $false

        foreach ($jumphost in $jumphostToServers.Keys) {
            $servers = $jumphostToServers[$jumphost] -join " "
        
            # Linux parancs gener�l�sa
            $linuxCommand = @"
[ "$server_name" == "$jumphost" ]; then sudo su - deployer -c "knife ssh -m '$servers' \"uname -r\" && exit";
"@

            # Parancs hozz�ad�sa a v�gleges parancshoz
            $finalLinuxCommand += $linuxCommand

            # Ha a k�vetkez� jumphost ut�n van m�g egy m�sik jumphost, akkor hozz�adja az "elif"-et
            if ($isLastJumphost -eq $false) {
                $finalLinuxCommand += " elif "
            }

            # Ellen�rzi, hogy a jelenlegi jumphost az utols�-e
            $isLastJumphost = $true
        }

        # V�gleges parancs lez�r�sa a "fi" ut�n
        $finalLinuxCommand += " fi"
    }
    default {
        Write-Host "�rv�nytelen v�laszt�s. Kil�p�s."
        return
    }
}

# K�d megjelen�t�se egy felugr� ablakban
$finalLinuxCommand | Out-GridView -Title "Gener�lt Linux Parancs" -PassThru | ForEach-Object {
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.Clipboard]::SetText($_)
}

# Parancs elment�se a txt f�jlba
$outputFileName = "generalt_kod.txt"
$finalLinuxCommand | Out-File -FilePath $outputFileName -Encoding utf8

Write-Host "------------------------------------------------------------" -ForegroundColor DarkMagenta
Write-Host "Linux parancs elkeszult es el lett mentve a $outputFileName fajlba." -ForegroundColor DarkGreen
Write-Host "------------------------------------------------------------" -ForegroundColor DarkMagenta

# Ki�rja a konzolra, hogy melyik DC-jumphostokat kell ind�tani
foreach ($dcJumphost in ($jumphostToServers.Keys | Select-Object -Unique)) {
    $jumphostNumber = $dcJumphost -replace 'jumphostdc(\d+)\.sf\.priv', '$1'
    $dcNumber = $jumphostNumber -replace 'ss(\d+)afrrundeck\d+', '$1'
    Write-Host "Inditsd el a DC$dcNumber-es jumphost-ot." -ForegroundColor Green
}
Write-Host "------------------------------------------------------------" -ForegroundColor DarkMagenta