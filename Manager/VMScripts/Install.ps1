#========================================================================
param(
    $rdp,
    $Parsec,
    $ParsecVDD,
    $DisableHVDD,
    $NumLock,
    $team_id,
    $key
) 
#========================================================================

#========================================================================
function Remove-File {
    param([Parameter(Mandatory = $true)][string]$Path)
    if (Test-Path $Path) { Remove-Item $Path -Force }
}
#========================================================================

#========================================================================
Remove-File "C:\unattend.xml"
Remove-File "C:\Windows\system32\GroupPolicy\User\Scripts\psscripts.ini"
Remove-File "C:\Windows\system32\GroupPolicy\User\Scripts\Logon\Install.ps1"

if ($NumLock -eq $true) {
    $WshShell = New-Object -ComObject WScript.Shell
    for ($i=0; $i -lt 5; $i++) {
        Start-Sleep -s 0.1
        if ([console]::NumberLock -eq $false) {
            $WshShell.SendKeys("{NUMLOCK}")
        } else { break }
    }
    $path = "$DriveLetter\Windows\system32\GroupPolicy\User\Scripts\psscripts.ini"
    "[Logon]"                                          >> $path
    "0CmdLine=NumLockEnable.ps1"                       >> $path
    "0Parameters="                                     >> $path
    
    $path = "$DriveLetter\Windows\system32\GroupPolicy\User\Scripts\Logon\NumLockEnable.ps1"
    "`$WshShell = New-Object -ComObject WScript.Shell" >> $path
    "for (`$i=0; `$i -lt 5; `$i++) {"                  >> $path
    "    Start-Sleep -s 0.1"                           >> $path
    "    if ([console]::NumberLock -eq `$false) {"     >> $path
    "        `$WshShell.SendKeys(`"{NUMLOCK}`")"       >> $path
    "    } else { break }"                             >> $path
    "}"                                                >> $path
}
#========================================================================

#========================================================================
function Set-RegistryPolicyItem {
    param(
        [Parameter(Mandatory = $true)]
        [string]
        [ValidateNotNullOrEmpty()]$path,
        [Parameter(Mandatory = $true)]
        [string]
        [ValidateNotNullOrEmpty()]$name,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]$value,
        [int]$type,
        [switch]$Force
    )

    $RegPolPath = "$env:SystemRoot\System32\GroupPolicy\Machine\Registry.pol"
    
    if ($type -eq 0) {
        $type = switch ($value.GetType().Fullname) {
            'System.String' { 1  }
            'System.Int32'  { 4  }
            'System.Int64'  { 11 }
            default { return }
        }
    }
    
    function PolToUpperCase {
        param(
            [int[]]$data
        ) 
        return $data | % -begin {$nameSection=$false} -process {
            if ($_ -eq 91)    { $nameSection = $true } 
            elseif($_ -eq 65) { $nameSection = $false }
            elseif($_ -ge 97 -and $_ -le 122 -and  $nameSection) { $_ -= 32 }
            $_
        }
    }
    
    function LastIndexOfBytesPattern {
        param (
            [int[]]$data,
            [int[]]$pattern
        )
        $i, $j = 0, 0
        ForEach ($byte in $data) {
            if($byte -eq $pattern[$j++]) { 
                if($j -eq $pattern.Count) { return $i } 
            } else {
                $j = 0
            } 
            $i++
        } 
        return -1
    }
    
    if (Test-path -path $RegPolPath) {
        $rawData = [io.file]::ReadAllBytes($RegPolPath)
    } else {
        $rawData = @(80, 82, 101, 103, 1, 0, 0, 0)
    }
    
    $isUptoDate = $true
    $keyData    = [System.Text.Encoding]::Unicode.GetBytes($path)
    $NameData   = [System.Text.Encoding]::Unicode.GetBytes($name)
    
    switch ($true) {        
        ($type -eq 4 -or $type -eq 11) { $valueData  = [BitConverter]::GetBytes($value) }
        $default { $valueData  = [System.Text.Encoding]::Unicode.GetBytes($value) }
    }
    
    $pattern    = @(91, 0) + $keyData +  @(0, 0, 59, 0) + $NameData + @(0, 0, 59, 0)
    $PolicyTypeOffset = (LastIndexOfBytesPattern (PolToUpperCase $rawData) (PolToUpperCase $pattern)) + 1
    
    if ($PolicyTypeOffset -gt 0) {
        $ValueOffset = 12 + $PolicyTypeOffset
        if ($rawData[$PolicyTypeOffset] -ne $type) {
            return
        }
        for ($i = 0; $i -lt $valueData.Count; $i++) {
            if ($rawData[$i + $ValueOffset] -ne $valueData[$i]) { 
                $isUptoDate = $false 
            }
            $rawData[$i + $ValueOffset] = $valueData[$i]
        }
    } else {
        $isUptoDate = $false
        $rawData += $pattern + @($type, 0, 0, 0, 59, 0, $type, 0, 0, 0, 59, 0) + $valueData + @(93, 0)
    }
    
    if ($isUptoDate -eq $false) {
        [io.file]::WriteAllBytes($RegPolPath, $rawData)
        if ($Force -eq $true) { 
            Start-Process -FilePath "gpupdate" -ArgumentList "/force" -NoNewWindow -Wait 
        }
    }
}
#========================================================================

#========================================================================
function Set-AllowInBoundConnections {
    param()
    if ((Get-NetFirewallProfile -Profile Domain).DefaultInboundAction -ne 'Allow') {
        Set-NetFirewallProfile -Profile Domain -DefaultInboundAction 'Allow'
    }
    if ((Get-NetFirewallProfile -Profile Private).DefaultInboundAction -ne 'Allow') {
        Set-NetFirewallProfile -Profile Private -DefaultInboundAction 'Allow'
    }
    if ((Get-NetFirewallProfile -Profile Public).DefaultInboundAction -ne 'Allow') {
        Set-NetFirewallProfile -Profile Public -DefaultInboundAction 'Allow'
    }
    Set-RegistryPolicyItem -Path "SOFTWARE\Policies\Microsoft\Windows Defender Security Center\Notifications" -Name "DisableNotifications" -Value 1
    Set-RegistryPolicyItem -Path "SOFTWARE\Policies\Microsoft\Windows Defender Security Center\Notifications" -Name "DisableEnhancedNotifications" -Value 1
    Set-RegistryPolicyItem -Path "SOFTWARE\Policies\Microsoft\Windows Defender Security Center\Firewall and network protection" -Name "UILockdown" -Value 1
    Set-RegistryPolicyItem -Path "Software\Policies\Microsoft\Windows NT\Terminal Services" -Name "ColorDepth" -Value 4
    Set-RegistryPolicyItem -Path "Software\Policies\Microsoft\Windows NT\Terminal Services" -Name "bEnumerateHWBeforeSW" -Value 1
    Set-RegistryPolicyItem -Path "Software\Policies\Microsoft\Windows NT\Terminal Services" -Name "fEnableVirtualizedGraphics" -Value 1
    Set-RegistryPolicyItem -Path "Software\Policies\Microsoft\Windows NT\Terminal Services" -Name "AVC444ModePreferred" -Value 1
    Set-RegistryPolicyItem -Path "Software\Policies\Microsoft\Windows NT\Terminal Services" -Name "fEnableWddmDriver" -Value 0 -Force
}
#========================================================================

#========================================================================
function Install-VBCable {
    param()
    if (!(Get-WmiObject Win32_SoundDevice | Where-Object name -like "VB-Audio Virtual Cable")) {
        (New-Object System.Net.WebClient).DownloadFile("https://download.vb-audio.com/Download_CABLE/VBCABLE_Driver_Pack43.zip", "C:\Users\$env:USERNAME\Downloads\VBCable.zip")
        New-Item -Path "C:\Users\$env:Username\Downloads\VBCable" -ItemType Directory| Out-Null
        Expand-Archive -Path "C:\Users\$env:USERNAME\Downloads\VBCable.zip" -DestinationPath "C:\Users\$env:USERNAME\Downloads\VBCable"
        $pathToCatFile = "C:\Users\$env:USERNAME\Downloads\VBCable\vbaudio_cable64_win7.cat"
        $FullCertificateExportPath = "C:\Users\$env:USERNAME\Downloads\VBCable\VBCert.cer"
        $VB = @{}
        $VB.DriverFile = $pathToCatFile;
        $VB.CertName = $FullCertificateExportPath;
        $VB.ExportType = [System.Security.Cryptography.X509Certificates.X509ContentType]::Cert;
        $VB.Cert = (Get-AuthenticodeSignature -filepath $VB.DriverFile).SignerCertificate;
        [System.IO.File]::WriteAllBytes($VB.CertName, $VB.Cert.Export($VB.ExportType))
        while (((Get-ChildItem Cert:\LocalMachine\TrustedPublisher) | Where-Object {$_.Subject -like '*Vincent Burel*'}) -eq $NULL) {
            certutil -Enterprise -Addstore "TrustedPublisher" $VB.CertName
            Start-Sleep -s 5
        }
        Start-Process -FilePath "C:\Users\$env:Username\Downloads\VBCable\VBCABLE_Setup_x64.exe" -ArgumentList '-i','-h'
    }
}
#========================================================================

#========================================================================
function Install-ParsecVDD {
    param()
    if (!(Get-WmiObject Win32_VideoController | Where-Object name -like "Parsec Virtual Display Adapter")) {
        (New-Object System.Net.WebClient).DownloadFile("https://builds.Parsec.app/vdd/Parsec-vdd-0.41.0.0.exe", "C:\Users\$env:USERNAME\Downloads\Parsec-vdd.exe")
        while (((Get-ChildItem Cert:\LocalMachine\TrustedPublisher) | Where-Object {$_.Subject -like '*Parsec*'}) -eq $NULL) {
            certutil -Enterprise -Addstore "TrustedPublisher" C:\ProgramData\Easy-GPU-P\ParsecPublic.cer
            Start-Sleep -s 5
        }
        if ($DisableHVDD -eq $true) {
            Get-PnpDevice | Where-Object {($_.Instanceid | Select-String -Pattern "VMBUS") -and $_.Class -like "Display" -and $_.status -eq "OK"} | Disable-PnpDevice -confirm:$false
        }
        Start-Process "C:\Users\$env:USERNAME\Downloads\Parsec-vdd.exe" -ArgumentList "/s"
    } 
}
#========================================================================

#========================================================================
function Set-EasyGPUPScheduledTask {
    param (
        [switch]$RunOnce,
        [string]$TaskName,
        [string]$Path
    )
    if(!(Get-ScheduledTask | Where-Object { $_.TaskName -like "$($TaskName)" })) {
        $principal = New-ScheduledTaskPrincipal -UserID "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount -RunLevel Highest
        $Action    = New-ScheduledTaskAction -Execute "C:\WINDOWS\system32\WindowsPowerShell\v1.0\powershell.exe" -Argument "-file $Path"
        $Trigger   = New-ScheduledTaskTrigger -AtStartup
        New-ScheduledTask -Action $Action -Trigger $Trigger -Principal $principal | Register-ScheduledTask -TaskName "$TaskName"
    } elseif ($RunOnce -eq $true) {
        Unregister-ScheduledTask -TaskName "$TaskName" -Confirm:$false
    }
}
#========================================================================

#========================================================================
while(!(Test-NetConnection Google.com).PingSucceeded) {
    Start-Sleep -Seconds 1
}

Get-ChildItem -Path C:\ProgramData\Easy-GPU-P -Recurse | Unblock-File

if ($Parsec -eq $true) {
    if ((Test-Path HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Parsec) -eq $false) {
        (New-Object System.Net.WebClient).DownloadFile("https://builds.parsecgaming.com/package/parsec-windows.exe", "C:\Users\$env:USERNAME\Downloads\Parsec-windows.exe")
        Start-Process "C:\Users\$env:USERNAME\Downloads\Parsec-windows.exe" -ArgumentList "/silent", "/shared","/team_id=$team_id","/team_computer_key=$key" -wait
        while (!(Test-Path C:\ProgramData\Parsec\config.txt)) {
            Start-Sleep -s 1
        }
        $configfile  = Get-Content C:\ProgramData\Parsec\config.txt
        $configfile += "host_virtual_monitors = 1"
        $configfile += "host_privacy_mode = 1"
        $configfile | Out-File C:\ProgramData\Parsec\config.txt -Encoding ascii
        Copy-Item -Path "C:\ProgramData\Easy-GPU-P\Parsec.lnk" -Destination "C:\Users\Public\Desktop"
        try {
            Stop-Process Parsecd -Force
        } catch {
        }
    }
    if ($ParsecVDD -eq $true) {
        Install-ParsecVDD
    }
    Install-VBCable 
    if ($ParsecVDD -eq $true) {
        Set-EasyGPUPScheduledTask -TaskName "Monitor Parsec VDD State" -Path "%programdata%\Easy-GPU-P\VDDMonitor.ps1"
    }
}

if ($rdp -eq $true) {
    Set-AllowInBoundConnections
}
#========================================================================

# SIG # Begin signature block
# MIItPAYJKoZIhvcNAQcCoIItLTCCLSkCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBvxEeEzKq03GS1
# GZgeGTSnDFWyji10+VMH1lzf8qoS9qCCEiEwggVvMIIEV6ADAgECAhBI/JO0YFWU
# jTanyYqJ1pQWMA0GCSqGSIb3DQEBDAUAMHsxCzAJBgNVBAYTAkdCMRswGQYDVQQI
# DBJHcmVhdGVyIE1hbmNoZXN0ZXIxEDAOBgNVBAcMB1NhbGZvcmQxGjAYBgNVBAoM
# EUNvbW9kbyBDQSBMaW1pdGVkMSEwHwYDVQQDDBhBQUEgQ2VydGlmaWNhdGUgU2Vy
# dmljZXMwHhcNMjEwNTI1MDAwMDAwWhcNMjgxMjMxMjM1OTU5WjBWMQswCQYDVQQG
# EwJHQjEYMBYGA1UEChMPU2VjdGlnbyBMaW1pdGVkMS0wKwYDVQQDEyRTZWN0aWdv
# IFB1YmxpYyBDb2RlIFNpZ25pbmcgUm9vdCBSNDYwggIiMA0GCSqGSIb3DQEBAQUA
# A4ICDwAwggIKAoICAQCN55QSIgQkdC7/FiMCkoq2rjaFrEfUI5ErPtx94jGgUW+s
# hJHjUoq14pbe0IdjJImK/+8Skzt9u7aKvb0Ffyeba2XTpQxpsbxJOZrxbW6q5KCD
# J9qaDStQ6Utbs7hkNqR+Sj2pcaths3OzPAsM79szV+W+NDfjlxtd/R8SPYIDdub7
# P2bSlDFp+m2zNKzBenjcklDyZMeqLQSrw2rq4C+np9xu1+j/2iGrQL+57g2extme
# me/G3h+pDHazJyCh1rr9gOcB0u/rgimVcI3/uxXP/tEPNqIuTzKQdEZrRzUTdwUz
# T2MuuC3hv2WnBGsY2HH6zAjybYmZELGt2z4s5KoYsMYHAXVn3m3pY2MeNn9pib6q
# RT5uWl+PoVvLnTCGMOgDs0DGDQ84zWeoU4j6uDBl+m/H5x2xg3RpPqzEaDux5mcz
# mrYI4IAFSEDu9oJkRqj1c7AGlfJsZZ+/VVscnFcax3hGfHCqlBuCF6yH6bbJDoEc
# QNYWFyn8XJwYK+pF9e+91WdPKF4F7pBMeufG9ND8+s0+MkYTIDaKBOq3qgdGnA2T
# OglmmVhcKaO5DKYwODzQRjY1fJy67sPV+Qp2+n4FG0DKkjXp1XrRtX8ArqmQqsV/
# AZwQsRb8zG4Y3G9i/qZQp7h7uJ0VP/4gDHXIIloTlRmQAOka1cKG8eOO7F/05QID
# AQABo4IBEjCCAQ4wHwYDVR0jBBgwFoAUoBEKIz6W8Qfs4q8p74Klf9AwpLQwHQYD
# VR0OBBYEFDLrkpr/NZZILyhAQnAgNpFcF4XmMA4GA1UdDwEB/wQEAwIBhjAPBgNV
# HRMBAf8EBTADAQH/MBMGA1UdJQQMMAoGCCsGAQUFBwMDMBsGA1UdIAQUMBIwBgYE
# VR0gADAIBgZngQwBBAEwQwYDVR0fBDwwOjA4oDagNIYyaHR0cDovL2NybC5jb21v
# ZG9jYS5jb20vQUFBQ2VydGlmaWNhdGVTZXJ2aWNlcy5jcmwwNAYIKwYBBQUHAQEE
# KDAmMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5jb21vZG9jYS5jb20wDQYJKoZI
# hvcNAQEMBQADggEBABK/oe+LdJqYRLhpRrWrJAoMpIpnuDqBv0WKfVIHqI0fTiGF
# OaNrXi0ghr8QuK55O1PNtPvYRL4G2VxjZ9RAFodEhnIq1jIV9RKDwvnhXRFAZ/ZC
# J3LFI+ICOBpMIOLbAffNRk8monxmwFE2tokCVMf8WPtsAO7+mKYulaEMUykfb9gZ
# pk+e96wJ6l2CxouvgKe9gUhShDHaMuwV5KZMPWw5c9QLhTkg4IUaaOGnSDip0TYl
# d8GNGRbFiExmfS9jzpjoad+sPKhdnckcW67Y8y90z7h+9teDnRGWYpquRRPaf9xH
# +9/DUp/mBlXpnYzyOmJRvOwkDynUWICE5EV7WtgwggYaMIIEAqADAgECAhBiHW0M
# UgGeO5B5FSCJIRwKMA0GCSqGSIb3DQEBDAUAMFYxCzAJBgNVBAYTAkdCMRgwFgYD
# VQQKEw9TZWN0aWdvIExpbWl0ZWQxLTArBgNVBAMTJFNlY3RpZ28gUHVibGljIENv
# ZGUgU2lnbmluZyBSb290IFI0NjAeFw0yMTAzMjIwMDAwMDBaFw0zNjAzMjEyMzU5
# NTlaMFQxCzAJBgNVBAYTAkdCMRgwFgYDVQQKEw9TZWN0aWdvIExpbWl0ZWQxKzAp
# BgNVBAMTIlNlY3RpZ28gUHVibGljIENvZGUgU2lnbmluZyBDQSBSMzYwggGiMA0G
# CSqGSIb3DQEBAQUAA4IBjwAwggGKAoIBgQCbK51T+jU/jmAGQ2rAz/V/9shTUxjI
# ztNsfvxYB5UXeWUzCxEeAEZGbEN4QMgCsJLZUKhWThj/yPqy0iSZhXkZ6Pg2A2NV
# DgFigOMYzB2OKhdqfWGVoYW3haT29PSTahYkwmMv0b/83nbeECbiMXhSOtbam+/3
# 6F09fy1tsB8je/RV0mIk8XL/tfCK6cPuYHE215wzrK0h1SWHTxPbPuYkRdkP05Zw
# mRmTnAO5/arnY83jeNzhP06ShdnRqtZlV59+8yv+KIhE5ILMqgOZYAENHNX9SJDm
# +qxp4VqpB3MV/h53yl41aHU5pledi9lCBbH9JeIkNFICiVHNkRmq4TpxtwfvjsUe
# dyz8rNyfQJy/aOs5b4s+ac7IH60B+Ja7TVM+EKv1WuTGwcLmoU3FpOFMbmPj8pz4
# 4MPZ1f9+YEQIQty/NQd/2yGgW+ufflcZ/ZE9o1M7a5Jnqf2i2/uMSWymR8r2oQBM
# dlyh2n5HirY4jKnFH/9gRvd+QOfdRrJZb1sCAwEAAaOCAWQwggFgMB8GA1UdIwQY
# MBaAFDLrkpr/NZZILyhAQnAgNpFcF4XmMB0GA1UdDgQWBBQPKssghyi47G9IritU
# pimqF6TNDDAOBgNVHQ8BAf8EBAMCAYYwEgYDVR0TAQH/BAgwBgEB/wIBADATBgNV
# HSUEDDAKBggrBgEFBQcDAzAbBgNVHSAEFDASMAYGBFUdIAAwCAYGZ4EMAQQBMEsG
# A1UdHwREMEIwQKA+oDyGOmh0dHA6Ly9jcmwuc2VjdGlnby5jb20vU2VjdGlnb1B1
# YmxpY0NvZGVTaWduaW5nUm9vdFI0Ni5jcmwwewYIKwYBBQUHAQEEbzBtMEYGCCsG
# AQUFBzAChjpodHRwOi8vY3J0LnNlY3RpZ28uY29tL1NlY3RpZ29QdWJsaWNDb2Rl
# U2lnbmluZ1Jvb3RSNDYucDdjMCMGCCsGAQUFBzABhhdodHRwOi8vb2NzcC5zZWN0
# aWdvLmNvbTANBgkqhkiG9w0BAQwFAAOCAgEABv+C4XdjNm57oRUgmxP/BP6YdURh
# w1aVcdGRP4Wh60BAscjW4HL9hcpkOTz5jUug2oeunbYAowbFC2AKK+cMcXIBD0Zd
# OaWTsyNyBBsMLHqafvIhrCymlaS98+QpoBCyKppP0OcxYEdU0hpsaqBBIZOtBajj
# cw5+w/KeFvPYfLF/ldYpmlG+vd0xqlqd099iChnyIMvY5HexjO2AmtsbpVn0OhNc
# WbWDRF/3sBp6fWXhz7DcML4iTAWS+MVXeNLj1lJziVKEoroGs9Mlizg0bUMbOalO
# hOfCipnx8CaLZeVme5yELg09Jlo8BMe80jO37PU8ejfkP9/uPak7VLwELKxAMcJs
# zkyeiaerlphwoKx1uHRzNyE6bxuSKcutisqmKL5OTunAvtONEoteSiabkPVSZ2z7
# 6mKnzAfZxCl/3dq3dUNw4rg3sTCggkHSRqTqlLMS7gjrhTqBmzu1L90Y1KWN/Y5J
# KdGvspbOrTfOXyXvmPL6E52z1NZJ6ctuMFBQZH3pwWvqURR8AgQdULUvrxjUYbHH
# j95Ejza63zdrEcxWLDX6xWls/GDnVNueKjWUH3fTv1Y8Wdho698YADR7TNx8X8z2
# Bev6SivBBOHY+uqiirZtg0y9ShQoPzmCcn63Syatatvx157YK9hlcPmVoa1oDE5/
# L9Uo2bC5a4CH2RwwggaMMIIE9KADAgECAhEAyULVSsRo8WfjxoGooT+uUTANBgkq
# hkiG9w0BAQwFADBUMQswCQYDVQQGEwJHQjEYMBYGA1UEChMPU2VjdGlnbyBMaW1p
# dGVkMSswKQYDVQQDEyJTZWN0aWdvIFB1YmxpYyBDb2RlIFNpZ25pbmcgQ0EgUjM2
# MB4XDTIyMTAyMDAwMDAwMFoXDTI1MTAxOTIzNTk1OVowgaExCzAJBgNVBAYTAkNO
# MRIwEAYDVQQIDAnmsZ/oi4/nnIExPjA8BgNVBAoMNUFpcnNwYWNlIEludGVsbGln
# ZW50IFRlY2hub2xvZ3kgKENoYW5nemhvdSkgQ28uLCBMdGQuMT4wPAYDVQQDDDVB
# aXJzcGFjZSBJbnRlbGxpZ2VudCBUZWNobm9sb2d5IChDaGFuZ3pob3UpIENvLiwg
# THRkLjCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAKLlR6fmTlhiSs9t
# 0NvBI+v6bJfw7ryPzVIKowDFcsBir3u+Lgx+nXL8Fw7QeGnstNr2XkO6KglALMQ1
# 7h9YPlWA+XOxNxRFzPs7UNkylBg5p71O2BJSTTMKeKkbHHt66q9Tx/Me4DbFJ0MB
# AXQnqDcUe8GSvg/1EN49WffFtw1nQrRrRzm11mQ01g0vPGaC9XFPyetI+Lw+IVm0
# WzvA+TddHnl/V95zyc1Tuw6anP18+O2/FVV2no4v5Ki/B7yvr8bCT+Z0gp/1G86G
# 0n4WaBrxPr+plgijrTnKHqufXGhCfCVRGBqfZRDgJWuSiitVffl6ZEz9n9gLpVXH
# oa8Ooy034rYwjI6AfelMqxFCxzsX5UnpOF+2L0JUyUHcpneMIScPTyh1hqMUozzB
# cQnMtc2UiNuGC2tZ2vumcTyRTtxI9Rb4SUp4laINBEpapJXwGOz490d6SiuoBuki
# 3HLDU3GxKcBlL6AMyvTQD6SuG9Yg5sdxZggBF8fUFcqbZx12aE1BuOzPvsqXgoJ9
# oX2tp+oyU9BHDZB/GiW2Eu8p5V5KO6dHC9y9cAN1t7K/QEY/wSbMmupYSEW6nCqV
# 6XMae1lsg+latVMYaNiLtiubCByzuGTuGwJpZCrHVRWhrTAHNkPTZANyaPbPt/xP
# cJT0xuZWdGv81Pj7LABzhmoeoSH1AgMBAAGjggGJMIIBhTAfBgNVHSMEGDAWgBQP
# Kssghyi47G9IritUpimqF6TNDDAdBgNVHQ4EFgQU6fp3oeeo/J5rW+H3wN4LEbtV
# gmUwDgYDVR0PAQH/BAQDAgeAMAwGA1UdEwEB/wQCMAAwEwYDVR0lBAwwCgYIKwYB
# BQUHAwMwSgYDVR0gBEMwQTA1BgwrBgEEAbIxAQIBAwIwJTAjBggrBgEFBQcCARYX
# aHR0cHM6Ly9zZWN0aWdvLmNvbS9DUFMwCAYGZ4EMAQQBMEkGA1UdHwRCMEAwPqA8
# oDqGOGh0dHA6Ly9jcmwuc2VjdGlnby5jb20vU2VjdGlnb1B1YmxpY0NvZGVTaWdu
# aW5nQ0FSMzYuY3JsMHkGCCsGAQUFBwEBBG0wazBEBggrBgEFBQcwAoY4aHR0cDov
# L2NydC5zZWN0aWdvLmNvbS9TZWN0aWdvUHVibGljQ29kZVNpZ25pbmdDQVIzNi5j
# cnQwIwYIKwYBBQUHMAGGF2h0dHA6Ly9vY3NwLnNlY3RpZ28uY29tMA0GCSqGSIb3
# DQEBDAUAA4IBgQCEg5TG0MwJG3zIRjP7LLdUhOzATfSxF48MTkEOqv8vxiaF1Gay
# edcSucyhV4ynFy8TGvljfW5K9Q2aZCnIJC3yLV0O6preeKa4n/5YyBqyPPuYjdoz
# cTPrlmuEOI/WrR34PWRU10AWKtEQna/Z3m94bUrLzxBMMk8inHbRwcUWy5Dj6o+o
# TWooT7tiBkuhtk3A7pEtmNCViZHOglrzRW+7n+8BMWfQKnvBb6HO9TeI4RgwNxUr
# FaYDMrAZY1mOGq4azyq3bjfTazguSek6biGsYdcimYvDAQXNaPD/67GdXWA8vwZu
# FvryW31HsOmTcEmoDizfIRiv6xk54q/CcqpuWXgthjDeyK6rFG/TV1a7hqJhCr5q
# ji3lI0TpriIspXSADXdzLkuQy4edUmud1Wy2b6Y9jWj9uMy6Tl3wX5CM2maZ210O
# HFZVmO7brniCrN7IQg0xtz0KPOvVPYa2R1YVqIWC4RQosrzcJg/WJUpf1itxBC66
# PlmEocQbOuqUqdExghpxMIIabQIBATBpMFQxCzAJBgNVBAYTAkdCMRgwFgYDVQQK
# Ew9TZWN0aWdvIExpbWl0ZWQxKzApBgNVBAMTIlNlY3RpZ28gUHVibGljIENvZGUg
# U2lnbmluZyBDQSBSMzYCEQDJQtVKxGjxZ+PGgaihP65RMA0GCWCGSAFlAwQCAQUA
# oHwwEAYKKwYBBAGCNwIBDDECMAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQw
# HAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIACB
# DQjSTUr+CbTOZVXJQh53bgN22uuG8op44rgg/PiJMA0GCSqGSIb3DQEBAQUABIIC
# AEvQ+MPvYX/f1tMd7t1Q3AwVOVMC0X3STXayv4ITSYcsyWHgnSjJxUPWWOfhe8jf
# xmybJCyLf540qbnrwzWUKcfSpMWBsQegFJYJ4HE5JvheQDcWIr1963WQOO8Kq2xG
# m/VIxkFoN7EVWMglcYM2Wed/owOL4rujK39vNPgtxneu625Wk/c+7DiYpr3O4gWL
# 4mN90r+FM0ZZD2fYq80p7DlJT3niwCyjdj3GFere/vGi/s4C0L7rs8FFmnjcGY1V
# rlwXQPaiu+uqck+4BOt9Q13UiMYiBuHDLGr/kYPUHSncSBlTOTJtvjOVMhvlIZkJ
# ndMnV0yiW22fw23MD4tnTDiT+qqMMaiTStSrjsE4bSSmrymdl7GUMXWfnqulJjC6
# KpvVzyFn1xWtzTmNv9ALDtzMlRcopnqo0wtWAS17VsgXafHU4l1UGIoxgHCi/oxB
# FN6yLpcUCHrRrvcay7PeAMehJT7xB1anUqRwH119VCHj4c7gN8FkzDD45CR5DdPW
# 4RAkrZYC0/NkoeFsSIneaJpsTWJaFIIrtq/iveAszjGfhRpM1zZDvg0T/Upj4N5e
# bXxpG6jj5YYJJJfv+Zo9nO9dCdnT5wXfERM2LXc+3lJIZqWO9tEX/Cvmdx2hwb0y
# ccA9003ni8Z3ZKcTgM0HCWqmb7s6B7uDyPpU68CAm4hooYIXWzCCF1cGCisGAQQB
# gjcDAwExghdHMIIXQwYJKoZIhvcNAQcCoIIXNDCCFzACAQMxDzANBglghkgBZQME
# AgIFADCBiAYLKoZIhvcNAQkQAQSgeQR3MHUCAQEGCWCGSAGG/WwHATBBMA0GCWCG
# SAFlAwQCAgUABDAJR1DOEftmmaj+syswFnovMzkPY6JL9AifkiqEbVgquizRdVX5
# 7x8rTrI8b5akAfgCEQCzaGbybnOFulwS1lKIlVqnGA8yMDI0MTIxMTEwMDY0N1qg
# ghMDMIIGvDCCBKSgAwIBAgIQC65mvFq6f5WHxvnpBOMzBDANBgkqhkiG9w0BAQsF
# ADBjMQswCQYDVQQGEwJVUzEXMBUGA1UEChMORGlnaUNlcnQsIEluYy4xOzA5BgNV
# BAMTMkRpZ2lDZXJ0IFRydXN0ZWQgRzQgUlNBNDA5NiBTSEEyNTYgVGltZVN0YW1w
# aW5nIENBMB4XDTI0MDkyNjAwMDAwMFoXDTM1MTEyNTIzNTk1OVowQjELMAkGA1UE
# BhMCVVMxETAPBgNVBAoTCERpZ2lDZXJ0MSAwHgYDVQQDExdEaWdpQ2VydCBUaW1l
# c3RhbXAgMjAyNDCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAL5qc5/2
# lSGrljC6W23mWaO16P2RHxjEiDtqmeOlwf0KMCBDEr4IxHRGd7+L660x5XltSVhh
# K64zi9CeC9B6lUdXM0s71EOcRe8+CEJp+3R2O8oo76EO7o5tLuslxdr9Qq82aKcp
# A9O//X6QE+AcaU/byaCagLD/GLoUb35SfWHh43rOH3bpLEx7pZ7avVnpUVmPvkxT
# 8c2a2yC0WMp8hMu60tZR0ChaV76Nhnj37DEYTX9ReNZ8hIOYe4jl7/r419CvEYVI
# rH6sN00yx49boUuumF9i2T8UuKGn9966fR5X6kgXj3o5WHhHVO+NBikDO0mlUh90
# 2wS/Eeh8F/UFaRp1z5SnROHwSJ+QQRZ1fisD8UTVDSupWJNstVkiqLq+ISTdEjJK
# GjVfIcsgA4l9cbk8Smlzddh4EfvFrpVNnes4c16Jidj5XiPVdsn5n10jxmGpxoMc
# 6iPkoaDhi6JjHd5ibfdp5uzIXp4P0wXkgNs+CO/CacBqU0R4k+8h6gYldp4FCMgr
# XdKWfM4N0u25OEAuEa3JyidxW48jwBqIJqImd93NRxvd1aepSeNeREXAu2xUDEW8
# aqzFQDYmr9ZONuc2MhTMizchNULpUEoA6Vva7b1XCB+1rxvbKmLqfY/M/SdV6mwW
# TyeVy5Z/JkvMFpnQy5wR14GJcv6dQ4aEKOX5AgMBAAGjggGLMIIBhzAOBgNVHQ8B
# Af8EBAMCB4AwDAYDVR0TAQH/BAIwADAWBgNVHSUBAf8EDDAKBggrBgEFBQcDCDAg
# BgNVHSAEGTAXMAgGBmeBDAEEAjALBglghkgBhv1sBwEwHwYDVR0jBBgwFoAUuhbZ
# bU2FL3MpdpovdYxqII+eyG8wHQYDVR0OBBYEFJ9XLAN3DigVkGalY17uT5IfdqBb
# MFoGA1UdHwRTMFEwT6BNoEuGSWh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdp
# Q2VydFRydXN0ZWRHNFJTQTQwOTZTSEEyNTZUaW1lU3RhbXBpbmdDQS5jcmwwgZAG
# CCsGAQUFBwEBBIGDMIGAMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdpY2Vy
# dC5jb20wWAYIKwYBBQUHMAKGTGh0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9E
# aWdpQ2VydFRydXN0ZWRHNFJTQTQwOTZTSEEyNTZUaW1lU3RhbXBpbmdDQS5jcnQw
# DQYJKoZIhvcNAQELBQADggIBAD2tHh92mVvjOIQSR9lDkfYR25tOCB3RKE/P09x7
# gUsmXqt40ouRl3lj+8QioVYq3igpwrPvBmZdrlWBb0HvqT00nFSXgmUrDKNSQqGT
# dpjHsPy+LaalTW0qVjvUBhcHzBMutB6HzeledbDCzFzUy34VarPnvIWrqVogK0qM
# 8gJhh/+qDEAIdO/KkYesLyTVOoJ4eTq7gj9UFAL1UruJKlTnCVaM2UeUUW/8z3fv
# jxhN6hdT98Vr2FYlCS7Mbb4Hv5swO+aAXxWUm3WpByXtgVQxiBlTVYzqfLDbe9Pp
# BKDBfk+rabTFDZXoUke7zPgtd7/fvWTlCs30VAGEsshJmLbJ6ZbQ/xll/HjO9JbN
# VekBv2Tgem+mLptR7yIrpaidRJXrI+UzB6vAlk/8a1u7cIqV0yef4uaZFORNekUg
# QHTqddmsPCEIYQP7xGxZBIhdmm4bhYsVA6G2WgNFYagLDBzpmk9104WQzYuVNsxy
# oVLObhx3RugaEGru+SojW4dHPoWrUhftNpFC5H7QEY7MhKRyrBe7ucykW7eaCuWB
# sBb4HOKRFVDcrZgdwaSIqMDiCLg4D+TPVgKx2EgEdeoHNHT9l3ZDBD+XgbF+23/z
# BjeCtxz+dL/9NWR6P2eZRi7zcEO1xwcdcqJsyz/JceENc2Sg8h3KeFUCS7tpFk7C
# rDqkMIIGrjCCBJagAwIBAgIQBzY3tyRUfNhHrP0oZipeWzANBgkqhkiG9w0BAQsF
# ADBiMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQL
# ExB3d3cuZGlnaWNlcnQuY29tMSEwHwYDVQQDExhEaWdpQ2VydCBUcnVzdGVkIFJv
# b3QgRzQwHhcNMjIwMzIzMDAwMDAwWhcNMzcwMzIyMjM1OTU5WjBjMQswCQYDVQQG
# EwJVUzEXMBUGA1UEChMORGlnaUNlcnQsIEluYy4xOzA5BgNVBAMTMkRpZ2lDZXJ0
# IFRydXN0ZWQgRzQgUlNBNDA5NiBTSEEyNTYgVGltZVN0YW1waW5nIENBMIICIjAN
# BgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAxoY1BkmzwT1ySVFVxyUDxPKRN6mX
# UaHW0oPRnkyibaCwzIP5WvYRoUQVQl+kiPNo+n3znIkLf50fng8zH1ATCyZzlm34
# V6gCff1DtITaEfFzsbPuK4CEiiIY3+vaPcQXf6sZKz5C3GeO6lE98NZW1OcoLevT
# sbV15x8GZY2UKdPZ7Gnf2ZCHRgB720RBidx8ald68Dd5n12sy+iEZLRS8nZH92GD
# Gd1ftFQLIWhuNyG7QKxfst5Kfc71ORJn7w6lY2zkpsUdzTYNXNXmG6jBZHRAp8By
# xbpOH7G1WE15/tePc5OsLDnipUjW8LAxE6lXKZYnLvWHpo9OdhVVJnCYJn+gGkcg
# Q+NDY4B7dW4nJZCYOjgRs/b2nuY7W+yB3iIU2YIqx5K/oN7jPqJz+ucfWmyU8lKV
# EStYdEAoq3NDzt9KoRxrOMUp88qqlnNCaJ+2RrOdOqPVA+C/8KI8ykLcGEh/FDTP
# 0kyr75s9/g64ZCr6dSgkQe1CvwWcZklSUPRR8zZJTYsg0ixXNXkrqPNFYLwjjVj3
# 3GHek/45wPmyMKVM1+mYSlg+0wOI/rOP015LdhJRk8mMDDtbiiKowSYI+RQQEgN9
# XyO7ZONj4KbhPvbCdLI/Hgl27KtdRnXiYKNYCQEoAA6EVO7O6V3IXjASvUaetdN2
# udIOa5kM0jO0zbECAwEAAaOCAV0wggFZMBIGA1UdEwEB/wQIMAYBAf8CAQAwHQYD
# VR0OBBYEFLoW2W1NhS9zKXaaL3WMaiCPnshvMB8GA1UdIwQYMBaAFOzX44LScV1k
# TN8uZz/nupiuHA9PMA4GA1UdDwEB/wQEAwIBhjATBgNVHSUEDDAKBggrBgEFBQcD
# CDB3BggrBgEFBQcBAQRrMGkwJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmRpZ2lj
# ZXJ0LmNvbTBBBggrBgEFBQcwAoY1aHR0cDovL2NhY2VydHMuZGlnaWNlcnQuY29t
# L0RpZ2lDZXJ0VHJ1c3RlZFJvb3RHNC5jcnQwQwYDVR0fBDwwOjA4oDagNIYyaHR0
# cDovL2NybDMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0VHJ1c3RlZFJvb3RHNC5jcmww
# IAYDVR0gBBkwFzAIBgZngQwBBAIwCwYJYIZIAYb9bAcBMA0GCSqGSIb3DQEBCwUA
# A4ICAQB9WY7Ak7ZvmKlEIgF+ZtbYIULhsBguEE0TzzBTzr8Y+8dQXeJLKftwig2q
# KWn8acHPHQfpPmDI2AvlXFvXbYf6hCAlNDFnzbYSlm/EUExiHQwIgqgWvalWzxVz
# jQEiJc6VaT9Hd/tydBTX/6tPiix6q4XNQ1/tYLaqT5Fmniye4Iqs5f2MvGQmh2yS
# vZ180HAKfO+ovHVPulr3qRCyXen/KFSJ8NWKcXZl2szwcqMj+sAngkSumScbqyQe
# JsG33irr9p6xeZmBo1aGqwpFyd/EjaDnmPv7pp1yr8THwcFqcdnGE4AJxLafzYeH
# JLtPo0m5d2aR8XKc6UsCUqc3fpNTrDsdCEkPlM05et3/JWOZJyw9P2un8WbDQc1P
# tkCbISFA0LcTJM3cHXg65J6t5TRxktcma+Q4c6umAU+9Pzt4rUyt+8SVe+0KXzM5
# h0F4ejjpnOHdI/0dKNPH+ejxmF/7K9h+8kaddSweJywm228Vex4Ziza4k9Tm8heZ
# Wcpw8De/mADfIBZPJ/tgZxahZrrdVcA6KYawmKAr7ZVBtzrVFZgxtGIJDwq9gdkT
# /r+k0fNX2bwE+oLeMt8EifAAzV3C+dAjfwAL5HYCJtnwZXZCpimHCUcr5n8apIUP
# /JiW9lVUKx+A+sDyDivl1vupL0QVSucTDh3bNzgaoSv27dZ8/DCCBY0wggR1oAMC
# AQICEA6bGI750C3n79tQ4ghAGFowDQYJKoZIhvcNAQEMBQAwZTELMAkGA1UEBhMC
# VVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0
# LmNvbTEkMCIGA1UEAxMbRGlnaUNlcnQgQXNzdXJlZCBJRCBSb290IENBMB4XDTIy
# MDgwMTAwMDAwMFoXDTMxMTEwOTIzNTk1OVowYjELMAkGA1UEBhMCVVMxFTATBgNV
# BAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTEhMB8G
# A1UEAxMYRGlnaUNlcnQgVHJ1c3RlZCBSb290IEc0MIICIjANBgkqhkiG9w0BAQEF
# AAOCAg8AMIICCgKCAgEAv+aQc2jeu+RdSjwwIjBpM+zCpyUuySE98orYWcLhKac9
# WKt2ms2uexuEDcQwH/MbpDgW61bGl20dq7J58soR0uRf1gU8Ug9SH8aeFaV+vp+p
# VxZZVXKvaJNwwrK6dZlqczKU0RBEEC7fgvMHhOZ0O21x4i0MG+4g1ckgHWMpLc7s
# Xk7Ik/ghYZs06wXGXuxbGrzryc/NrDRAX7F6Zu53yEioZldXn1RYjgwrt0+nMNlW
# 7sp7XeOtyU9e5TXnMcvak17cjo+A2raRmECQecN4x7axxLVqGDgDEI3Y1DekLgV9
# iPWCPhCRcKtVgkEy19sEcypukQF8IUzUvK4bA3VdeGbZOjFEmjNAvwjXWkmkwuap
# oGfdpCe8oU85tRFYF/ckXEaPZPfBaYh2mHY9WV1CdoeJl2l6SPDgohIbZpp0yt5L
# HucOY67m1O+SkjqePdwA5EUlibaaRBkrfsCUtNJhbesz2cXfSwQAzH0clcOP9yGy
# shG3u3/y1YxwLEFgqrFjGESVGnZifvaAsPvoZKYz0YkH4b235kOkGLimdwHhD5QM
# IR2yVCkliWzlDlJRR3S+Jqy2QXXeeqxfjT/JvNNBERJb5RBQ6zHFynIWIgnffEx1
# P2PsIV/EIFFrb7GrhotPwtZFX50g/KEexcCPorF+CiaZ9eRpL5gdLfXZqbId5RsC
# AwEAAaOCATowggE2MA8GA1UdEwEB/wQFMAMBAf8wHQYDVR0OBBYEFOzX44LScV1k
# TN8uZz/nupiuHA9PMB8GA1UdIwQYMBaAFEXroq/0ksuCMS1Ri6enIZ3zbcgPMA4G
# A1UdDwEB/wQEAwIBhjB5BggrBgEFBQcBAQRtMGswJAYIKwYBBQUHMAGGGGh0dHA6
# Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBDBggrBgEFBQcwAoY3aHR0cDovL2NhY2VydHMu
# ZGlnaWNlcnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElEUm9vdENBLmNydDBFBgNVHR8E
# PjA8MDqgOKA2hjRodHRwOi8vY3JsMy5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1
# cmVkSURSb290Q0EuY3JsMBEGA1UdIAQKMAgwBgYEVR0gADANBgkqhkiG9w0BAQwF
# AAOCAQEAcKC/Q1xV5zhfoKN0Gz22Ftf3v1cHvZqsoYcs7IVeqRq7IviHGmlUIu2k
# iHdtvRoU9BNKei8ttzjv9P+Aufih9/Jy3iS8UgPITtAq3votVs/59PesMHqai7Je
# 1M/RQ0SbQyHrlnKhSLSZy51PpwYDE3cnRNTnf+hZqPC/Lwum6fI0POz3A8eHqNJM
# QBk1RmppVLC4oVaO7KTVPeix3P0c2PR3WlxUjG/voVA9/HYJaISfb8rbII01YBwC
# A8sgsKxYoA5AY8WYIsGyWfVVa88nq2x2zm8jLfR+cWojayL/ErhULSd+2DrZ8LaH
# lv1b0VysGMNNn3O3AamfV6peKOK5lDGCA4YwggOCAgEBMHcwYzELMAkGA1UEBhMC
# VVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJbmMuMTswOQYDVQQDEzJEaWdpQ2VydCBU
# cnVzdGVkIEc0IFJTQTQwOTYgU0hBMjU2IFRpbWVTdGFtcGluZyBDQQIQC65mvFq6
# f5WHxvnpBOMzBDANBglghkgBZQMEAgIFAKCB4TAaBgkqhkiG9w0BCQMxDQYLKoZI
# hvcNAQkQAQQwHAYJKoZIhvcNAQkFMQ8XDTI0MTIxMTEwMDY0N1owKwYLKoZIhvcN
# AQkQAgwxHDAaMBgwFgQU29OF7mLb0j575PZxSFCHJNWGW0UwNwYLKoZIhvcNAQkQ
# Ai8xKDAmMCQwIgQgdnafqPJjLx9DCzojMK7WVnX+13PbBdZluQWTmEOPmtswPwYJ
# KoZIhvcNAQkEMTIEMHYvxPxE5H5TyN3pc9A1XFWvPA9z+nLgiZ9RaG7X8wEZfbQg
# J9yqwDljzSVb+M5vZjANBgkqhkiG9w0BAQEFAASCAgCGXN8ABJmEt+58MV/w1lKO
# E2qSmqci45CEaa5xlEXpKm7V4CsIptso8Fi5SOkKEsMMhiawu/M31hHKOoxtked8
# pF/WSQaVn+liBJRZyJZg8jskItigo4c2++1wnw0Lpu1X+zQiwixyXjpSEDkmpe7P
# JPACfjwCw3ejIcE/IoK7oiCZyg99/C1aOmJB83cZ1+Vc2qCv/6t1Tb69wMk2A4z1
# /ba2u77lj4p9V2Y2BG7r84+c/Ke6KlIhv4J6BboV3T9YM+LqDYN8HM8IZNB8nCdB
# Zn8M448i0IzYIg2FjYQOXLQStmVPQZQ1YuMx3VdqXaNeThvESkzVlB6/NKATLmv7
# KfQKwmz56pHT+h4mVouEDCtkSPtiG+PBWlP8kWCCjn7xNqyVjLAo7B7NjowWtSJd
# VE9ZzafiweNu7RxDbSYHmDRsXHIIr/u222u7nNt6S3CJlAoR7ctRe+gGZ0h5KRkE
# zPoMKYmedzg1+e2oUJ3bVKG0tgOy1LNLrxg51CuPGo3FSf50uizXlWp4CZRi3R9d
# pfwZMe9afr2digos6qAQfi6oqMmm6TohC/ycGCJU1sdlkvTXNV4/zfEjc90uYdVT
# XyQe3WBZTQQWvGCwbP7qUoaANlNOy5DUP3l/Abt/4B9G9xO0CLW7KvHvPZ2N4qyh
# qCkS+xvKRRcMjEqEWcIkyQ==
# SIG # End signature block
