﻿param(
$team_id,
$key
)

while(!(Test-NetConnection Google.com).PingSucceeded){
    Start-Sleep -Seconds 1
    }

Get-ChildItem -Path C:\ProgramData\Easy-GPU-P -Recurse | Unblock-File

if (Test-Path HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Parsec) 
    {}
    else {
    (New-Object System.Net.WebClient).DownloadFile("https://builds.parsecgaming.com/package/parsec-windows.exe", "C:\Users\$env:USERNAME\Downloads\parsec-windows.exe")
    Start-Process "C:\Users\$env:USERNAME\Downloads\parsec-windows.exe" -ArgumentList "/silent", "/shared","/team_id=$team_id","/team_computer_key=$key" -wait
    While (!(Test-Path C:\ProgramData\Parsec\config.txt)){
        Start-Sleep -s 1
        }
    $configfile = Get-Content C:\ProgramData\Parsec\config.txt
    $configfile += "host_virtual_monitors = 1"
    $configfile += "host_privacy_mode = 1"
    $configfile | Out-File C:\ProgramData\Parsec\config.txt -Encoding ascii
    Copy-Item -Path "C:\ProgramData\Easy-GPU-P\Parsec.lnk" -Destination "C:\Users\Public\Desktop"
    Stop-Process parsecd -Force
    }

Function ParsecVDDMonitorSetupScheduledTask {
$XML = @"
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.2" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo>
    <Description>Monitors the state of Parsec Virtual Display and repairs if broken</Description>
    <URI>\Monitor Parsec VDD State</URI>
  </RegistrationInfo>
  <Triggers>
    <LogonTrigger>
      <Enabled>true</Enabled>
      <UserId>$(([System.Security.Principal.WindowsIdentity]::GetCurrent()).Name)</UserId>
      <Delay>PT2M</Delay>
    </LogonTrigger>
  </Triggers>
  <Principals>
    <Principal id="Author">
      <UserId>$(([System.Security.Principal.WindowsIdentity]::GetCurrent()).User.Value)</UserId>
      <LogonType>S4U</LogonType>
      <RunLevel>HighestAvailable</RunLevel>
    </Principal>
  </Principals>
  <Settings>
    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>true</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>true</StopIfGoingOnBatteries>
    <AllowHardTerminate>true</AllowHardTerminate>
    <StartWhenAvailable>false</StartWhenAvailable>
    <RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>
    <IdleSettings>
      <StopOnIdleEnd>true</StopOnIdleEnd>
      <RestartOnIdle>false</RestartOnIdle>
    </IdleSettings>
    <AllowStartOnDemand>true</AllowStartOnDemand>
    <Enabled>true</Enabled>
    <Hidden>false</Hidden>
    <RunOnlyIfIdle>false</RunOnlyIfIdle>
    <WakeToRun>false</WakeToRun>
    <ExecutionTimeLimit>PT72H</ExecutionTimeLimit>
    <Priority>7</Priority>
  </Settings>
  <Actions Context="Author">
    <Exec>
      <Command>C:\WINDOWS\system32\WindowsPowerShell\v1.0\powershell.exe</Command>
      <Arguments>-file %programdata%\Easy-GPU-P\VDDMonitor.ps1</Arguments>
    </Exec>
  </Actions>
</Task>
"@

    try {
        Get-ScheduledTask -TaskName "Monitor Parsec VDD State" -ErrorAction Stop | Out-Null
        Unregister-ScheduledTask -TaskName "Monitor Parsec VDD State" -Confirm:$false
        }
    catch {}
    $action = New-ScheduledTaskAction -Execute 'C:\WINDOWS\system32\WindowsPowerShell\v1.0\powershell.exe' -Argument '-file %programdata%\Easy-GPU-P\VDDMonitor.ps1'
    $trigger =  New-ScheduledTaskTrigger -AtStartup
    Register-ScheduledTask -XML $XML -TaskName "Monitor Parsec VDD State" | Out-Null
    }
Function VBCableInstallSetupScheduledTask {
$XML = @"
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.2" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo>
    <Description>Install VB Cable</Description>
    <URI>\Install VB Cable</URI>
  </RegistrationInfo>
  <Triggers>
    <LogonTrigger>
      <Enabled>true</Enabled>
      <UserId>$(([System.Security.Principal.WindowsIdentity]::GetCurrent()).Name)</UserId>
      <Delay>PT2M</Delay>
    </LogonTrigger>
  </Triggers>
  <Principals>
    <Principal id="Author">
      <UserId>$(([System.Security.Principal.WindowsIdentity]::GetCurrent()).User.Value)</UserId>
      <LogonType>S4U</LogonType>
      <RunLevel>HighestAvailable</RunLevel>
    </Principal>
  </Principals>
  <Settings>
    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>true</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>true</StopIfGoingOnBatteries>
    <AllowHardTerminate>true</AllowHardTerminate>
    <StartWhenAvailable>false</StartWhenAvailable>
    <RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>
    <IdleSettings>
      <StopOnIdleEnd>true</StopOnIdleEnd>
      <RestartOnIdle>false</RestartOnIdle>
    </IdleSettings>
    <AllowStartOnDemand>true</AllowStartOnDemand>
    <Enabled>true</Enabled>
    <Hidden>false</Hidden>
    <RunOnlyIfIdle>false</RunOnlyIfIdle>
    <WakeToRun>false</WakeToRun>
    <ExecutionTimeLimit>PT72H</ExecutionTimeLimit>
    <Priority>7</Priority>
  </Settings>
  <Actions Context="Author">
    <Exec>
      <Command>C:\WINDOWS\system32\WindowsPowerShell\v1.0\powershell.exe</Command>
      <Arguments>-file %programdata%\Easy-GPU-P\VBCableInstall.ps1</Arguments>
    </Exec>
  </Actions>
</Task>
"@

    try {
        Get-ScheduledTask -TaskName "Install VB Cable" -ErrorAction Stop | Out-Null
        Unregister-ScheduledTask -TaskName "Install VB Cable" -Confirm:$false
        }
    catch {}
    $action = New-ScheduledTaskAction -Execute 'C:\WINDOWS\system32\WindowsPowerShell\v1.0\powershell.exe' -Argument '-file %programdata%\Easy-GPU-P\VBCableInstall.ps1'
    $trigger =  New-ScheduledTaskTrigger -AtStartup
    Register-ScheduledTask -XML $XML -TaskName "Install VB Cable" | Out-Null
    }
Function ParsecVDDInstallSetupScheduledTask {
$XML = @"
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.2" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo>
    <Description>Install Parsec Virtual Display Driver</Description>
    <URI>\Install Parsec Virtual Display Driver</URI>
  </RegistrationInfo>
  <Triggers>
    <LogonTrigger>
      <Enabled>true</Enabled>
      <UserId>$(([System.Security.Principal.WindowsIdentity]::GetCurrent()).Name)</UserId>
      <Delay>PT2M</Delay>
    </LogonTrigger>
  </Triggers>
  <Principals>
    <Principal id="Author">
      <UserId>$(([System.Security.Principal.WindowsIdentity]::GetCurrent()).User.Value)</UserId>
      <LogonType>S4U</LogonType>
      <RunLevel>HighestAvailable</RunLevel>
    </Principal>
  </Principals>
  <Settings>
    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>true</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>true</StopIfGoingOnBatteries>
    <AllowHardTerminate>true</AllowHardTerminate>
    <StartWhenAvailable>false</StartWhenAvailable>
    <RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>
    <IdleSettings>
      <StopOnIdleEnd>true</StopOnIdleEnd>
      <RestartOnIdle>false</RestartOnIdle>
    </IdleSettings>
    <AllowStartOnDemand>true</AllowStartOnDemand>
    <Enabled>true</Enabled>
    <Hidden>false</Hidden>
    <RunOnlyIfIdle>false</RunOnlyIfIdle>
    <WakeToRun>false</WakeToRun>
    <ExecutionTimeLimit>PT72H</ExecutionTimeLimit>
    <Priority>7</Priority>
  </Settings>
  <Actions Context="Author">
    <Exec>
      <Command>C:\WINDOWS\system32\WindowsPowerShell\v1.0\powershell.exe</Command>
      <Arguments>-file %programdata%\Easy-GPU-P\ParsecVDDInstall.ps1</Arguments>
    </Exec>
  </Actions>
</Task>
"@

    try {
        Get-ScheduledTask -TaskName "Install Parsec Virtual Display Driver" -ErrorAction Stop | Out-Null
        Unregister-ScheduledTask -TaskName "Install Parsec Virtual Display Driver" -Confirm:$false
        }
    catch {}
    $action = New-ScheduledTaskAction -Execute 'C:\WINDOWS\system32\WindowsPowerShell\v1.0\powershell.exe' -Argument '-file %programdata%\Easy-GPU-P\ParsecVDDInstall.ps1'
    $trigger =  New-ScheduledTaskTrigger -AtStartup
    Register-ScheduledTask -XML $XML -TaskName "Install Parsec Virtual Display Driver" | Out-Null
    }

ParsecVDDMonitorSetupScheduledTask
VBCableInstallSetupScheduledTask
ParsecVDDInstallSetupScheduledTask

Start-ScheduledTask -TaskName "Install VB Cable"
Start-ScheduledTask -TaskName "Install Parsec Virtual Display Driver"
Start-ScheduledTask -TaskName "Monitor Parsec VDD State"
# SIG # Begin signature block
# MIItPAYJKoZIhvcNAQcCoIItLTCCLSkCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCv0H2TJ59M/FQa
# KNYNiPbxQey+xuvxInWCnmn+rSyepqCCEiEwggVvMIIEV6ADAgECAhBI/JO0YFWU
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
# HAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIPc9
# gKYpNOE8YJYsQV78TgWvGq7Eznqlophxic3e8tALMA0GCSqGSIb3DQEBAQUABIIC
# AIhcoKTgYB7YkRoNZnZIdICpJksKTGthCDyp0bBPzvk3ue5QH+V46j+bFdUX+yYw
# lMPfsspTFgADAxvaREqenY4RTca48/MrOpzxl8uhBHG7Kx0P/kIIXQSs81JAASBE
# jhF7IUfnuoNORAQI26GZ2kXOaO7cFuxzx6ymAoWNaeckW7JWrdhUFDQw3zqLV1T5
# szFcn3Az+rXhb5id/L+HCuAO0AnkWLK5HHbRn/flNe7paL3xocN6bN1ZZwhKXIGi
# K09jWSoFddGSl0/pD52zBjpbYYmfEo4+heStIJrQVs3B2JczDFncJ0BuI75fvKJv
# /MBlxurPbc71/slEpCNGUrskcmW1qfd4U6QDQ39UbzUD8PidQD7bDG9VpQD25XZu
# jlW1HYPHE76wdFcdPqqBJ4tGkhKmb6nyOCi7XlOWZuJ0bof3DoVnEzioSJfqes1a
# TydnJk9dmg01ohnKM1JnPj4l5pa8tebDwKCrKgX9vjc9097r3v4WzqdP3H1wAK79
# kO/3Uosc+ZRqNuhAOVQXw/mYceTNxAmXQ7hMVYRK4ODFGqYG4lIAbOhz5AOrWIsp
# Zemgehdq9z/saEqKVPl8GrPGPltnw03oN6tW8uPmS0DMo1lp5HvjvoFbIP1ZqtH4
# al5ewweNn2rBhVDcdB896z4jJJBmtULeIqv7KVAGFuBmoYIXWzCCF1cGCisGAQQB
# gjcDAwExghdHMIIXQwYJKoZIhvcNAQcCoIIXNDCCFzACAQMxDzANBglghkgBZQME
# AgIFADCBiAYLKoZIhvcNAQkQAQSgeQR3MHUCAQEGCWCGSAGG/WwHATBBMA0GCWCG
# SAFlAwQCAgUABDAXh8fDFVmqay6mNfbHm47P11zUZmzij3Uy3y/2dt735cXv6Lv6
# R2iDGOr3jx/p61MCEQDEUQIGF3aNmdCMAz03HtsoGA8yMDI0MTIxMTAzMDkwMlqg
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
# hvcNAQkQAQQwHAYJKoZIhvcNAQkFMQ8XDTI0MTIxMTAzMDkwMlowKwYLKoZIhvcN
# AQkQAgwxHDAaMBgwFgQU29OF7mLb0j575PZxSFCHJNWGW0UwNwYLKoZIhvcNAQkQ
# Ai8xKDAmMCQwIgQgdnafqPJjLx9DCzojMK7WVnX+13PbBdZluQWTmEOPmtswPwYJ
# KoZIhvcNAQkEMTIEMEFEcIpa+0JDn86G+vkT4024yzvLBN3e+r4U7lJregHypVrB
# aCtYMziL6HvlelqDATANBgkqhkiG9w0BAQEFAASCAgB3VpJgSrlkWSHkSXsy15W2
# gYWqh95nAQHkGwaGYxTapjP6RhEgZt6PdCt/oMmgfm+UeCH825JGFOBglqV5wkQV
# TXm3KzuokBEg7qlqx9kdgSkjoG/MMAKJohKOpPgtaULVoNqT+h1WbwMbg8/JsNwF
# J3Z8gUZWUrxfHPFIQoqZcjLAhGbXtEIH7iFLHF5G6pZ0TaFA6zkOUoUTMWVnPWuA
# fm+sbCEg9/j7SnwWRE1m5fTwWUijw5xkOWJPFvhoSBeEDhqkv3/eVAOE8Zcz+o9T
# 9hrwdtwtE66+3ie3nXj+wVSwlu7XA1ubVDd7SuLjkj+z+6sZAFA25b8V/DBzGm4o
# juklw0hMKgtkaFGzp/6s0mel1O9gCzE5zveiGhUUCE9VFGjOJvw3441WFD9kQdvv
# Wf/70tSm817yurz8AL/tzPDozM1jpFO72J4XIQ9tUDFSLzdbHxoSSYhUfELlddl2
# fkbV0mjyxuaPRC/an4PN3qcMiIfMqlXf7LrJusiZAiea0zA5kLaaH9hHskPQGdGa
# Qe4QzCf8CJ8anbRQ6e/vzM7vLlozK56EjdMyEAwZEh4OSLklVbUr4GLMOFvHTQ3+
# qAikT66rTgpSZb7JVuFmz4LCG1hTM658bMXh9sQaXotZWSNWCOwd67f7EK8Uk5IG
# UzS5IXndLShqc7fI9CHyLA==
# SIG # End signature block
