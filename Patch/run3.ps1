Add-Type -AssemblyName System.Windows.Forms

# Főablak létrehozása
$mainForm = New-Object System.Windows.Forms.Form
$mainForm.Text = "PowerShell UI"
$mainForm.Size = New-Object System.Drawing.Size(500, 300)

# Hostlist TextBox hozzáadása
$hostListTextBox = New-Object System.Windows.Forms.TextBox
$hostListTextBox.Location = New-Object System.Drawing.Point(10, 20)
$hostListTextBox.Size = New-Object System.Drawing.Size(200, 20)
$mainForm.Controls.Add($hostListTextBox)

# Gomb a hostlist betöltéséhez
$loadHostListButton = New-Object System.Windows.Forms.Button
$loadHostListButton.Location = New-Object System.Drawing.Point(220, 20)
$loadHostListButton.Size = New-Object System.Drawing.Size(100, 23)
$loadHostListButton.Text = "Hostlist Betöltése"
$loadHostListButton.Add_Click({
    $global:hostList = Get-Content -Path $hostListTextBox.Text
})
$mainForm.Controls.Add($loadHostListButton)

# Funkciók ListBox hozzáadása
$optionsListBox = New-Object System.Windows.Forms.ListBox
$optionsListBox.Location = New-Object System.Drawing.Point(10, 60)
$optionsListBox.Size = New-Object System.Drawing.Size(200, 120)
$optionsListBox.SelectionMode = "MultiSimple"
$optionsListBox.Items.AddRange("Volt-e patch?", "Uptime lekérdezés", "Mi a firmware?")
$mainForm.Controls.Add($optionsListBox)

# Gomb a generáláshoz
$generateButton = New-Object System.Windows.Forms.Button
$generateButton.Location = New-Object System.Drawing.Point(220, 60)
$generateButton.Size = New-Object System.Drawing.Size(100, 23)
$generateButton.Text = "Generálás"
$generateButton.Add_Click({
    $selectedOptions = $optionsListBox.SelectedItems
    . {
        # Eredeti PowerShell kód itt
        # Példa: Write-Host "Kiválasztott opciók: $selectedOptions"
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

        $jumphostToServers = @{}
        
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
        
            if (-not $jumphostToServers.ContainsKey($jumphost)) {
                $jumphostToServers[$jumphost] = @()
            }
            $jumphostToServers[$jumphost] += $server
        
            Write-Host "$server szerver parositva lett $jumphost DC-jumphost-hoz."
        }

        switch ($selectedOptions) {
            "Volt-e patch?" {
                $finalLinuxCommand = 'server_name=$(hostname); if '
                $isLastJumphost = $false

                foreach ($jumphost in $jumphostToServers.Keys) {
                    $servers = $jumphostToServers[$jumphost] -join " "
                
                    $linuxCommand = @"
[ "$server_name" == "$jumphost" ]; then sudo su - deployer -c "knife ssh -m '$servers' \"sudo less /opt/Tanium/TaniumClient/Tools/Patch/logs/patch-process.log | grep 'All update successfully installed.'\" && exit";
"@

                    $finalLinuxCommand += $linuxCommand

                    if ($isLastJumphost -eq $false) {
                        $finalLinuxCommand += " elif "
                    }

                    $isLastJumphost = $true
                }

                $finalLinuxCommand += " fi"
            }
            "Uptime lekérdezés" {
                $finalLinuxCommand = 'server_name=$(hostname); if '
                $isLastJumphost = $false

                foreach ($jumphost in $jumphostToServers.Keys) {
                    $servers = $jumphostToServers[$jumphost] -join " "
                
                    $linuxCommand = @"
[ "$server_name" == "$jumphost" ]; then sudo su - deployer -c "knife ssh -m '$servers' \"uptime\" && exit";
"@

                    $finalLinuxCommand += $linuxCommand

                    if ($isLastJumphost -eq $false) {
                        $finalLinuxCommand += " elif "
                    }

                    $isLastJumphost = $true
                }

                $finalLinuxCommand += " fi"
            }
            "Mi a firmware?" {
                $finalLinuxCommand = 'server_name=$(hostname); if '
                $isLastJumphost = $false

                foreach ($jumphost in $jumphostToServers.Keys) {
                    $servers = $jumphostToServers[$jumphost] -join " "
                
                    $linuxCommand = @"
[ "$server_name" == "$jumphost" ]; then sudo su - deployer -c "knife ssh -m '$servers' \"uname -r\" && exit";
"@

                    $finalLinuxCommand += $linuxCommand

                    if ($isLastJumphost -eq $false) {
                        $finalLinuxCommand += " elif "
                    }

                    $isLastJumphost = $true
                }

                $finalLinuxCommand += " fi"
            }
            default {
                Write-Host "Érvénytelen választás. Kilépés."
                return
            }
        }

        $outputFileName = "generalt_kod.txt"
        $finalLinuxCommand | Out-File -FilePath $outputFileName -Encoding utf8

        Write-Host "------------------------------------------------------------" -ForegroundColor DarkMagenta
        Write-Host "Linux parancs elkeszult es el lett mentve a $outputFileName fajlba." -ForegroundColor DarkGreen
        Write-Host "------------------------------------------------------------" -ForegroundColor DarkMagenta

        foreach ($dcJumphost in ($jumphostToServers.Keys | Select-Object -Unique)) {
            $jumphostNumber = $dcJumphost -replace 'jumphostdc(\d+)\.sf\.priv', '$1'
            $dcNumber = $jumphostNumber -replace 'ss(\d+)afrrundeck\d+', '$1'
            Write-Host "Inditsd el a DC$dcNumber-es jumphost-ot." -ForegroundColor Green
        }
        Write-Host "------------------------------------------------------------" -ForegroundColor DarkMagenta
    }
})
$mainForm.Controls.Add($generateButton)

# Főablak megjelenítése
[Windows.Forms.Application]::Run($mainForm)
