﻿#
# These variables are device properties.  For people who are very
# curious about this, you can download the Windows Driver Kit headers and
# look for pciprop.h.  All of these are contained in that file.
#
$devpkey_PciDevice_DeviceType = "{3AB22E31-8264-4b4e-9AF5-A8D2D8E33E62}  1"
$devpkey_PciDevice_RequiresReservedMemoryRegion = "{3AB22E31-8264-4b4e-9AF5-A8D2D8E33E62}  34"
$devpkey_PciDevice_AcsCompatibleUpHierarchy = "{3AB22E31-8264-4b4e-9AF5-A8D2D8E33E62}  31"

$devprop_PciDevice_DeviceType_PciConventional = 0
$devprop_PciDevice_DeviceType_PciX = 1
$devprop_PciDevice_DeviceType_PciExpressEndpoint = 2
$devprop_PciDevice_DeviceType_PciExpressLegacyEndpoint = 3
$devprop_PciDevice_DeviceType_PciExpressRootComplexIntegratedEndpoint = 4
$devprop_PciDevice_DeviceType_PciExpressTreatedAsPci = 5
$devprop_PciDevice_BridgeType_PciConventional = 6
$devprop_PciDevice_BridgeType_PciX = 7
$devprop_PciDevice_BridgeType_PciExpressRootPort = 8
$devprop_PciDevice_BridgeType_PciExpressUpstreamSwitchPort = 9
$devprop_PciDevice_BridgeType_PciExpressDownstreamSwitchPort = 10
$devprop_PciDevice_BridgeType_PciExpressToPciXBridge = 11
$devprop_PciDevice_BridgeType_PciXToExpressBridge = 12
$devprop_PciDevice_BridgeType_PciExpressTreatedAsPci = 13
$devprop_PciDevice_BridgeType_PciExpressEventCollector = 14

$devprop_PciDevice_AcsCompatibleUpHierarchy_NotSupported = 0
$devprop_PciDevice_AcsCompatibleUpHierarchy_SingleFunctionSupported = 1
$devprop_PciDevice_AcsCompatibleUpHierarchy_NoP2PSupported = 2
$devprop_PciDevice_AcsCompatibleUpHierarchy_Supported = 3


#write-host "Generating a list of PCI Express endpoint devices"
$pnpdevs = Get-PnpDevice -PresentOnly
$pcidevs = $pnpdevs | Where-Object { $_.InstanceId -like "PCI*" }
$counter = 0
foreach ($pcidev in $pcidevs)
{
    $counter = $counter + 1
    #if ($counter -gt 3){
    #    break
    #}


    Write-Host "########"
    #Write-Host ""
    Write-Host -ForegroundColor White -BackgroundColor Black $pcidev.FriendlyName

    $rmrr = ($pcidev | Get-PnpDeviceProperty $devpkey_PciDevice_RequiresReservedMemoryRegion).Data
    if ($rmrr -ne 0)
    {
        write-host -ForegroundColor Red -BackgroundColor Black "BIOS requires that this device remain attached to BIOS-owned memory.  Not assignable"
        continue
    }

    $acsUp = ($pcidev | Get-PnpDeviceProperty $devpkey_PciDevice_AcsCompatibleUpHierarchy).Data
    if ($acsUp -eq $devprop_PciDevice_AcsCompatibleUpHierarchy_NotSupported)
    {
        write-host -ForegroundColor Red -BackgroundColor Black "Traffic from this device may be redirected to other devices in the system.  Not assignable"
        continue
    }

    $devtype = ($pcidev | Get-PnpDeviceProperty $devpkey_PciDevice_DeviceType).Data
    if ($devtype -eq $devprop_PciDevice_DeviceType_PciExpressEndpoint)
    {
        # Write-Host "Express Endpoint -- more secure."
    }
    else
    {
        if ($devtype -eq $devprop_PciDevice_DeviceType_PciExpressRootComplexIntegratedEndpoint)
        {
            # Write-Host "Embedded Endpoint -- less secure."
        }
        else
        {
            if ($devtype -eq $devprop_PciDevice_DeviceType_PciExpressTreatedAsPci)
            {
                Write-Host -ForegroundColor Red -BackgroundColor Black "BIOS kept control of PCI Express for this device.  Not assignable"
            }
            else
            {
                Write-Host -ForegroundColor Red -BackgroundColor Black "Old-style PCI device, switch port, etc.  Not assignable"
            }
            continue
        }
    }

    $locationpath = ($pcidev | get-pnpdeviceproperty DEVPKEY_Device_LocationPaths).data[0]

    #
    # Now do a check for the interrupts that the device uses.  Line-based interrupts
    # aren't assignable.
    #
    $doubleslashDevId = "*" + $pcidev.PNPDeviceID.Replace("\", "\\") + "*"
    $irqAssignments = gwmi -query "select * from Win32_PnPAllocatedResource" | Where-Object { $_.__RELPATH -like "*Win32_IRQResource*" } | Where-Object { $_.Dependent -like $doubleslashDevId }

    #$irqAssignments | Format-Table -Property __RELPATH

    if ($irqAssignments.length -eq 0)
    {
        Write-Host -ForegroundColor Green -BackgroundColor Black "It has no interrupts at all. Assignment can work"
    }
    else
    {
        #
        # Find the message-signaled interrupts.  They are reported with a really big number in
        # decimal, one which always happens to start with "42949...".
        #
        $msiAssignments = $irqAssignments | Where-Object { $_.Antecedent -like "*IRQNumber=42949*" }

        #$msiAssignments | Format-Table -Property __RELPATH

        if ($msiAssignments.length -eq 0)
        {
            Write-Host -ForegroundColor Red -BackgroundColor Black "All of the interrupts are line-based. Not assignable"
            continue
        }
        else
        {
            Write-Host -ForegroundColor Green -BackgroundColor Black "Its interrupts are message-based. Assignment can work"
        }
    }

    #
    # Print out the location path, as that's the way to refer to this device that won't
    # change even if you add or remove devices from the machine or change the way that
    # the BIOS is configured.
    #
    $locationpath
}

#
# Now look at the host as a whole.  Asking whether the host supports SR-IOV
# is mostly equivalent to asking whether it supports Discrete Device
# Assignment.
#
if ((Get-VMHost).IovSupport -eq $false)
{
    #Write-Host ""
    #write-host "Unfortunately, this machine doesn't support using them in a VM."
    #Write-Host ""
    (Get-VMHost).IovSupportReasons
}
# SIG # Begin signature block
# MIIpeQYJKoZIhvcNAQcCoIIpajCCKWYCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCA5or5XxC3agQrZ
# aMZAXbR5pDRyaVldSlR+KSGpyxmrC6CCDmowggbNMIIEtaADAgECAhEAu/DMtbe4
# Mf0hrjJ3iuQMiTANBgkqhkiG9w0BAQwFADCBgDELMAkGA1UEBhMCUEwxIjAgBgNV
# BAoTGVVuaXpldG8gVGVjaG5vbG9naWVzIFMuQS4xJzAlBgNVBAsTHkNlcnR1bSBD
# ZXJ0aWZpY2F0aW9uIEF1dGhvcml0eTEkMCIGA1UEAxMbQ2VydHVtIFRydXN0ZWQg
# TmV0d29yayBDQSAyMB4XDTIxMDUxOTA1MzIxM1oXDTM2MDUxODA1MzIxM1owajEL
# MAkGA1UEBhMCUEwxITAfBgNVBAoTGEFzc2VjbyBEYXRhIFN5c3RlbXMgUy5BLjE4
# MDYGA1UEAxMvQ2VydHVtIEV4dGVuZGVkIFZhbGlkYXRpb24gQ29kZSBTaWduaW5n
# IDIwMjEgQ0EwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQCUvvjwlqjf
# 9eedRTK+NoavZlVxmQTPIN1nK5XQRUQWyPWwHD54wa2aD2kRDrAjBf71/T0XN9Oq
# ms5ML/Jolgryv3JW7/yahp7lg/wn3PDnNwzC1BlFMyCdEktQmUXMmE4mmxSutRY1
# OGGagENWPjbQ1R/x4HuTByWbG+TUV7dIPxE7TMy9Npco4f09DN6QFRXdk7bZTu58
# kxu6MFH6mzQkC3IXvExfo0c/CT4/hTZD2XknHjXLzi9jzInSHS9GQqeXd6nWbkwE
# u7znKpNEcSElorDSEcRhc1OSOLjUK0x0cOw8whzQ0fWGkPoqgCslbjZoko7U7kj/
# Fn4TWQ8s75LHjhVao+w2SWMP0ELWYIkq1ComGq3wqBD7VU6rtCDoUf237HkgRBxL
# XFjwp444oKWnchYMZ7epWX8jqntSr4QHeidL72c6XswQIIZsFglV4BO28jO02yS7
# w4iyY0c6PQs34GZ7SWphsN1DaiX9ysc6hovVYoVA94t+3p4TI1RtK9Ayh0atmfYP
# JqtBfk5kJ1h4nNax0lZmJL9chJjZQb+7XW8MQgstiQdsegaz2QL6Edm+94N8IW6T
# YaalyO9LeR35A9MoTLo79rdB04naTqWdPTBKh7DpS53ZAQn5dYs2per+m7ZeIxnE
# WaNcG+PbRh+ZslFb6M75JgN43szB+/VYVQIDAQABo4IBVTCCAVEwDwYDVR0TAQH/
# BAUwAwEB/zAdBgNVHQ4EFgQUrFfKCBbcP8UxHApN2/vx3pknLTQwHwYDVR0jBBgw
# FoAUtqFUOQLDoD+Oirz61PgcptE6Dv0wDgYDVR0PAQH/BAQDAgEGMBMGA1UdJQQM
# MAoGCCsGAQUFBwMDMDAGA1UdHwQpMCcwJaAjoCGGH2h0dHA6Ly9jcmwuY2VydHVt
# LnBsL2N0bmNhMi5jcmwwbAYIKwYBBQUHAQEEYDBeMCgGCCsGAQUFBzABhhxodHRw
# Oi8vc3ViY2Eub2NzcC1jZXJ0dW0uY29tMDIGCCsGAQUFBzAChiZodHRwOi8vcmVw
# b3NpdG9yeS5jZXJ0dW0ucGwvY3RuY2EyLmNlcjA5BgNVHSAEMjAwMC4GBFUdIAAw
# JjAkBggrBgEFBQcCARYYaHR0cDovL3d3dy5jZXJ0dW0ucGwvQ1BTMA0GCSqGSIb3
# DQEBDAUAA4ICAQC7khlZjFbU+gsRdcraFFJKj1PL63MVudnm/AILuNaxm7LIZOYt
# rZaRWEpR0qd3uhSpUEI29fMBZvuu3CHXJsM58hbJFo4YoHnyDJgTkeVmc10fd1NI
# //cI3nRD1/Alx09yWhPZlze0A/Bvwc3LcZtTywfsL5tD3QAL8ZqelrHt1Eb8AnDE
# nAzKNbm1mwYmD/5dy1XkIKfsM1pmRM2ZDcJ4qpwVewE7g+4e+Y+iq42LuaHPvNAk
# wq0daA9Hp3qemk0cRFfM5257MvEsu+6w8+44mpQUOgpASVIjY3l2vdf6BUfBJfsd
# 3pcp/2hfDnXaql9AoB7ps7eCZb9VXKm/u2lTRMf5esOcZFy4udsnGBaOwSSUe0ch
# YusfJ9IjsmpoMl4CW5E0R/U55Bz6TpDo+gaXQJL4i/zv0UR5papGsDguBASp9g/O
# fnvGTeWrS9l5orEktu9ExrFfPvAKxZK+4AO9bapPhMATraKo6kx6K51pS1ZO2pf1
# r3B+lXN5bTLgp8g/dygUZm2cmauBAzJA5v/iHOb0b4b4Muqc8dxgcX1jZRLtLvxn
# AWxkKIMfj7A4M0JrN4rLBUpPFM0+Bp2sR7rtFqNZW56huaDkxO75eNRN2z4A959R
# 5GBRnFWtgE65+B1RHAQQ/TOF4mU0Y3oIhVQr3rUh4tdSvIxr8QpsDKIvsDCCB5Uw
# ggV9oAMCAQICEFQ9mkv948CeDPCAPvnmOb0wDQYJKoZIhvcNAQELBQAwajELMAkG
# A1UEBhMCUEwxITAfBgNVBAoTGEFzc2VjbyBEYXRhIFN5c3RlbXMgUy5BLjE4MDYG
# A1UEAxMvQ2VydHVtIEV4dGVuZGVkIFZhbGlkYXRpb24gQ29kZSBTaWduaW5nIDIw
# MjEgQ0EwHhcNMjQwNTE2MDUyMTU5WhcNMjcwNTE2MDUyMTU4WjCCAR4xHTAbBgNV
# BA8TFFByaXZhdGUgT3JnYW5pemF0aW9uMRMwEQYLKwYBBAGCNzwCAQMTAkNOMRow
# GAYLKwYBBAGCNzwCAQIMCUd1YW5nZG9uZzEZMBcGCysGAQQBgjc8AgEBDAhTaGVu
# emhlbjEbMBkGA1UEBRMSOTE0NDAzMDBNQURKSlFEUFhMMQswCQYDVQQGEwJDTjES
# MBAGA1UECAwJR3Vhbmdkb25nMREwDwYDVQQHDAhTaGVuemhlbjEvMC0GA1UECgwm
# Rmlubm94IFRlY2hub2xvZ3kgKFNoZW56aGVuKSBDby4sIEx0ZC4xLzAtBgNVBAMM
# JkZpbm5veCBUZWNobm9sb2d5IChTaGVuemhlbikgQ28uLCBMdGQuMIICIjANBgkq
# hkiG9w0BAQEFAAOCAg8AMIICCgKCAgEA8dIB5SPqXLevmTIZAU0g5mt88QBgf7OF
# o5YJg4lwP/OGOczlxxRI8tjx+CO8vdp1ky3UKmSVcCHW6Vj7teWUlGyWapH4FdYC
# DEE+P6P092+QBIlMWR22YfnUkCbgV3k+UicYNuPByNhZuRO8GBdkwdvooSPeh+M+
# ueWDSqxi/WjljgISrfk85wzHA/rA0MvrgBnTq8rXM0bvPJlRrlM6AIAfs0LheVUR
# 9XTqVpp6BT/3GNc628ywSD98oQwxAHQ63aw/5+eMpdLgtpyeoBPU99iVlJlKqxJ8
# tdTdnD4dLuKfBlYRv6h13Sy2XAG3xwBUiwjJQ3wyLODIqjU4bCfBKOUxNeCWt395
# ZDRuWyve5f6rb8J9Z/7rChlH/rMT4u5IcbA4WENlvvKGaYC+smoU+T5573i9BPPl
# mH6VR9FvBUhft84doxJVWh2vRkYYKLQZYmfskuQzKNfPr+d9s/1tMymdKypSYQrf
# m8LqyjSA8QVLUBf+f8kCZFAlzuYaqybP4i/e3qrJGky0WBx3tKxvqkFbopcYqAsc
# dcf2p1KFru5stihU1SzycWtbf1Q+wLQIHGSXKX9uzqKKPjlPeo1jIPwQrKfx4/s+
# w42orSvDTYzMigvh29WcnWDm4D/HxHakN8gVkqsn7hUzrpRDAIgeZ3ajMhJsXkDt
# iMXg5/nmhPcCAwEAAaOCAX8wggF7MAwGA1UdEwEB/wQCMAAwQQYDVR0fBDowODA2
# oDSgMoYwaHR0cDovL2NldmNzY2EyMDIxLmNybC5jZXJ0dW0ucGwvY2V2Y3NjYTIw
# MjEuY3JsMHcGCCsGAQUFBwEBBGswaTAuBggrBgEFBQcwAYYiaHR0cDovL2NldmNz
# Y2EyMDIxLm9jc3AtY2VydHVtLmNvbTA3BggrBgEFBQcwAoYraHR0cDovL3JlcG9z
# aXRvcnkuY2VydHVtLnBsL2NldmNzY2EyMDIxLmNlcjAfBgNVHSMEGDAWgBSsV8oI
# Ftw/xTEcCk3b+/HemSctNDAdBgNVHQ4EFgQUAHnCTTXopORSrJ/2eSOiudq4O8gw
# SgYDVR0gBEMwQTAHBgVngQwBAzA2BgsqhGgBhvZ3AgUBBzAnMCUGCCsGAQUFBwIB
# FhlodHRwczovL3d3dy5jZXJ0dW0ucGwvQ1BTMBMGA1UdJQQMMAoGCCsGAQUFBwMD
# MA4GA1UdDwEB/wQEAwIHgDANBgkqhkiG9w0BAQsFAAOCAgEAIUP2XbGdUYAK1Mei
# ZFvYbfC5ITpaqvsZ2Mt3bQw2xPzE+STcXwEdVw23LQboxXY0CesdejvI/kTZkn2r
# F0mcjUrlQP+zFrP4Z4826Z5rVEWaOy0vngVb61MNfSINyU6JMQyNiBuYrFAPW1iE
# QYdEdnfsueM1YkRkFB57DeoQIfdICf4dgr0qMEv0cTwK7gAjeA7JMl0jLj7hLxjt
# rvnNX8eHKOszbhkmRe0FiETk4X19VmaBGMwJZreAcDnG9SsPFA+xSvbwlmcAAVs/
# K8YK30HLV4aknwyPMXRVJZ17yiYGCLnuUavr5M0pVK46O06mdPT1w1VQrBiQFwcg
# qu3jk23QUzhttPfDXzhQZWHyzzzGsrhnLeXBCiC5tnNIbUF4QqIZsEBa2L8oKA6U
# xqZiIWLQyUpiiR3fc13hDYSbnx1SmZBjN6IESzLfSn5h+716slI7Ik5xlosBX9n6
# UlcNPGTVQYb+xr8c6ZBVgwuvWOh92irKeULYMJOCEpNGmzWZWyZivive/IUwKoIy
# GJcUikaQuLR0Vee37Z8LiwwE3sY5Jx/4ldvQxt2dwM8foI+MhWLj6ApU/e8Asir4
# TeybMtV/mBYUvgHrjFdk6lDCC5ljYJBC064aOgzfqXNDair2lDiEp+Ptq3HFpneC
# QNzG8ko4/ZtEs4Odyi0KIcj5oTkxghplMIIaYQIBATB+MGoxCzAJBgNVBAYTAlBM
# MSEwHwYDVQQKExhBc3NlY28gRGF0YSBTeXN0ZW1zIFMuQS4xODA2BgNVBAMTL0Nl
# cnR1bSBFeHRlbmRlZCBWYWxpZGF0aW9uIENvZGUgU2lnbmluZyAyMDIxIENBAhBU
# PZpL/ePAngzwgD755jm9MA0GCWCGSAFlAwQCAQUAoHwwEAYKKwYBBAGCNwIBDDEC
# MAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEOMAwG
# CisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIA9gE1EjF8LuPDDOU2wcmLP8Fjsz
# jeYMdwJRCLc0fWU3MA0GCSqGSIb3DQEBAQUABIICAPCUYc5GWP8bVVd/fugYUuaX
# X8xz0kl+VU+BPKh8oXxS4C8h82wpzh2XP8VyPRv8f15UbFlxo/UmdJVph3O99gwf
# 1UquUzU63+Il9rbE8HjO5ZBwMMEYPxYxABCrrOiOPeLR2dpYV4Guln+qEmeP4Ths
# nGCD7VWACZCk+oOq2mAHtu7WillEe7QEm3YI/qmKOB6UUAJR3KiSEL1AvXrNvxbi
# RYB18ja00f/L61uXqmdDpXMfNyqvhLAisAW4STotyVPMTB+NqwPd5cKUphTTm4e3
# 2bNlQzt02pmST3PhPfCfTo12e2ejqdQFRpLue/XEk/FaZlUHaawGAfmFuF0iz3pD
# cL966qwMZpQQDcxX47MSA9kxPiKy1POicVtNyymNdN1+czRxQA85Ss+qJy1bZcDJ
# f4m20wNbGAb0AxYhHUL7R1hNrIRcEd/ZqFgyqNPBjCOw5gBXgWhkyZNOm8WZWLw4
# 9BALIZ6tlgIdoQW65DF/BBsTRqyVYq9rOUu1bfY/jJd7MGCnZwy1cfGw7qelZeEV
# 2/reuhFG6MWBxaYpzRC+STp/mlsK19AEd5hl7eZALB2VM+LIzgtB1FMkKC84PBJs
# SCdJe6nEH0Y7Rui2NnIDmjMp+B3qzaoursV1QSLlqtcyEyjb6GSYrDw9/0O0xAUj
# g9cbin6oHjrvd+EkM6NFoYIXOjCCFzYGCisGAQQBgjcDAwExghcmMIIXIgYJKoZI
# hvcNAQcCoIIXEzCCFw8CAQMxDzANBglghkgBZQMEAgEFADB4BgsqhkiG9w0BCRAB
# BKBpBGcwZQIBAQYJYIZIAYb9bAcBMDEwDQYJYIZIAWUDBAIBBQAEIL98Bdz3Jxa/
# oowuxR1vvESwjI8HUUQk/SaJYaGHbtIVAhEAhmYmpL3sGt1RJAizYpIfWhgPMjAy
# NTAzMzExMTQ5MjFaoIITAzCCBrwwggSkoAMCAQICEAuuZrxaun+Vh8b56QTjMwQw
# DQYJKoZIhvcNAQELBQAwYzELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lDZXJ0
# LCBJbmMuMTswOQYDVQQDEzJEaWdpQ2VydCBUcnVzdGVkIEc0IFJTQTQwOTYgU0hB
# MjU2IFRpbWVTdGFtcGluZyBDQTAeFw0yNDA5MjYwMDAwMDBaFw0zNTExMjUyMzU5
# NTlaMEIxCzAJBgNVBAYTAlVTMREwDwYDVQQKEwhEaWdpQ2VydDEgMB4GA1UEAxMX
# RGlnaUNlcnQgVGltZXN0YW1wIDIwMjQwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAw
# ggIKAoICAQC+anOf9pUhq5Ywultt5lmjtej9kR8YxIg7apnjpcH9CjAgQxK+CMR0
# Rne/i+utMeV5bUlYYSuuM4vQngvQepVHVzNLO9RDnEXvPghCaft0djvKKO+hDu6O
# bS7rJcXa/UKvNminKQPTv/1+kBPgHGlP28mgmoCw/xi6FG9+Un1h4eN6zh926SxM
# e6We2r1Z6VFZj75MU/HNmtsgtFjKfITLutLWUdAoWle+jYZ49+wxGE1/UXjWfISD
# mHuI5e/6+NfQrxGFSKx+rDdNMsePW6FLrphfYtk/FLihp/feun0eV+pIF496OVh4
# R1TvjQYpAztJpVIfdNsEvxHofBf1BWkadc+Up0Th8EifkEEWdX4rA/FE1Q0rqViT
# bLVZIqi6viEk3RIySho1XyHLIAOJfXG5PEppc3XYeBH7xa6VTZ3rOHNeiYnY+V4j
# 1XbJ+Z9dI8ZhqcaDHOoj5KGg4YuiYx3eYm33aebsyF6eD9MF5IDbPgjvwmnAalNE
# eJPvIeoGJXaeBQjIK13SlnzODdLtuThALhGtyconcVuPI8AaiCaiJnfdzUcb3dWn
# qUnjXkRFwLtsVAxFvGqsxUA2Jq/WTjbnNjIUzIs3ITVC6VBKAOlb2u29Vwgfta8b
# 2ypi6n2PzP0nVepsFk8nlcuWfyZLzBaZ0MucEdeBiXL+nUOGhCjl+QIDAQABo4IB
# izCCAYcwDgYDVR0PAQH/BAQDAgeAMAwGA1UdEwEB/wQCMAAwFgYDVR0lAQH/BAww
# CgYIKwYBBQUHAwgwIAYDVR0gBBkwFzAIBgZngQwBBAIwCwYJYIZIAYb9bAcBMB8G
# A1UdIwQYMBaAFLoW2W1NhS9zKXaaL3WMaiCPnshvMB0GA1UdDgQWBBSfVywDdw4o
# FZBmpWNe7k+SH3agWzBaBgNVHR8EUzBRME+gTaBLhklodHRwOi8vY3JsMy5kaWdp
# Y2VydC5jb20vRGlnaUNlcnRUcnVzdGVkRzRSU0E0MDk2U0hBMjU2VGltZVN0YW1w
# aW5nQ0EuY3JsMIGQBggrBgEFBQcBAQSBgzCBgDAkBggrBgEFBQcwAYYYaHR0cDov
# L29jc3AuZGlnaWNlcnQuY29tMFgGCCsGAQUFBzAChkxodHRwOi8vY2FjZXJ0cy5k
# aWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVkRzRSU0E0MDk2U0hBMjU2VGltZVN0
# YW1waW5nQ0EuY3J0MA0GCSqGSIb3DQEBCwUAA4ICAQA9rR4fdplb4ziEEkfZQ5H2
# EdubTggd0ShPz9Pce4FLJl6reNKLkZd5Y/vEIqFWKt4oKcKz7wZmXa5VgW9B76k9
# NJxUl4JlKwyjUkKhk3aYx7D8vi2mpU1tKlY71AYXB8wTLrQeh83pXnWwwsxc1Mt+
# FWqz57yFq6laICtKjPICYYf/qgxACHTvypGHrC8k1TqCeHk6u4I/VBQC9VK7iSpU
# 5wlWjNlHlFFv/M93748YTeoXU/fFa9hWJQkuzG2+B7+bMDvmgF8VlJt1qQcl7YFU
# MYgZU1WM6nyw23vT6QSgwX5Pq2m0xQ2V6FJHu8z4LXe/371k5QrN9FQBhLLISZi2
# yemW0P8ZZfx4zvSWzVXpAb9k4Hpvpi6bUe8iK6WonUSV6yPlMwerwJZP/Gtbu3CK
# ldMnn+LmmRTkTXpFIEB06nXZrDwhCGED+8RsWQSIXZpuG4WLFQOhtloDRWGoCwwc
# 6ZpPddOFkM2LlTbMcqFSzm4cd0boGhBq7vkqI1uHRz6Fq1IX7TaRQuR+0BGOzISk
# cqwXu7nMpFu3mgrlgbAW+BzikRVQ3K2YHcGkiKjA4gi4OA/kz1YCsdhIBHXqBzR0
# /Zd2QwQ/l4Gxftt/8wY3grcc/nS//TVkej9nmUYu83BDtccHHXKibMs/yXHhDXNk
# oPIdynhVAku7aRZOwqw6pDCCBq4wggSWoAMCAQICEAc2N7ckVHzYR6z9KGYqXlsw
# DQYJKoZIhvcNAQELBQAwYjELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0
# IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTEhMB8GA1UEAxMYRGlnaUNl
# cnQgVHJ1c3RlZCBSb290IEc0MB4XDTIyMDMyMzAwMDAwMFoXDTM3MDMyMjIzNTk1
# OVowYzELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJbmMuMTswOQYD
# VQQDEzJEaWdpQ2VydCBUcnVzdGVkIEc0IFJTQTQwOTYgU0hBMjU2IFRpbWVTdGFt
# cGluZyBDQTCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAMaGNQZJs8E9
# cklRVcclA8TykTepl1Gh1tKD0Z5Mom2gsMyD+Vr2EaFEFUJfpIjzaPp985yJC3+d
# H54PMx9QEwsmc5Zt+FeoAn39Q7SE2hHxc7Gz7iuAhIoiGN/r2j3EF3+rGSs+Qtxn
# jupRPfDWVtTnKC3r07G1decfBmWNlCnT2exp39mQh0YAe9tEQYncfGpXevA3eZ9d
# rMvohGS0UvJ2R/dhgxndX7RUCyFobjchu0CsX7LeSn3O9TkSZ+8OpWNs5KbFHc02
# DVzV5huowWR0QKfAcsW6Th+xtVhNef7Xj3OTrCw54qVI1vCwMROpVymWJy71h6aP
# TnYVVSZwmCZ/oBpHIEPjQ2OAe3VuJyWQmDo4EbP29p7mO1vsgd4iFNmCKseSv6De
# 4z6ic/rnH1pslPJSlRErWHRAKKtzQ87fSqEcazjFKfPKqpZzQmiftkaznTqj1QPg
# v/CiPMpC3BhIfxQ0z9JMq++bPf4OuGQq+nUoJEHtQr8FnGZJUlD0UfM2SU2LINIs
# VzV5K6jzRWC8I41Y99xh3pP+OcD5sjClTNfpmEpYPtMDiP6zj9NeS3YSUZPJjAw7
# W4oiqMEmCPkUEBIDfV8ju2TjY+Cm4T72wnSyPx4JduyrXUZ14mCjWAkBKAAOhFTu
# zuldyF4wEr1GnrXTdrnSDmuZDNIztM2xAgMBAAGjggFdMIIBWTASBgNVHRMBAf8E
# CDAGAQH/AgEAMB0GA1UdDgQWBBS6FtltTYUvcyl2mi91jGogj57IbzAfBgNVHSME
# GDAWgBTs1+OC0nFdZEzfLmc/57qYrhwPTzAOBgNVHQ8BAf8EBAMCAYYwEwYDVR0l
# BAwwCgYIKwYBBQUHAwgwdwYIKwYBBQUHAQEEazBpMCQGCCsGAQUFBzABhhhodHRw
# Oi8vb2NzcC5kaWdpY2VydC5jb20wQQYIKwYBBQUHMAKGNWh0dHA6Ly9jYWNlcnRz
# LmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0ZWRSb290RzQuY3J0MEMGA1UdHwQ8
# MDowOKA2oDSGMmh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0
# ZWRSb290RzQuY3JsMCAGA1UdIAQZMBcwCAYGZ4EMAQQCMAsGCWCGSAGG/WwHATAN
# BgkqhkiG9w0BAQsFAAOCAgEAfVmOwJO2b5ipRCIBfmbW2CFC4bAYLhBNE88wU86/
# GPvHUF3iSyn7cIoNqilp/GnBzx0H6T5gyNgL5Vxb122H+oQgJTQxZ822EpZvxFBM
# Yh0MCIKoFr2pVs8Vc40BIiXOlWk/R3f7cnQU1/+rT4osequFzUNf7WC2qk+RZp4s
# nuCKrOX9jLxkJodskr2dfNBwCnzvqLx1T7pa96kQsl3p/yhUifDVinF2ZdrM8HKj
# I/rAJ4JErpknG6skHibBt94q6/aesXmZgaNWhqsKRcnfxI2g55j7+6adcq/Ex8HB
# anHZxhOACcS2n82HhyS7T6NJuXdmkfFynOlLAlKnN36TU6w7HQhJD5TNOXrd/yVj
# mScsPT9rp/Fmw0HNT7ZAmyEhQNC3EyTN3B14OuSereU0cZLXJmvkOHOrpgFPvT87
# eK1MrfvElXvtCl8zOYdBeHo46Zzh3SP9HSjTx/no8Zhf+yvYfvJGnXUsHicsJttv
# FXseGYs2uJPU5vIXmVnKcPA3v5gA3yAWTyf7YGcWoWa63VXAOimGsJigK+2VQbc6
# 1RWYMbRiCQ8KvYHZE/6/pNHzV9m8BPqC3jLfBInwAM1dwvnQI38AC+R2AibZ8GV2
# QqYphwlHK+Z/GqSFD/yYlvZVVCsfgPrA8g4r5db7qS9EFUrnEw4d2zc4GqEr9u3W
# fPwwggWNMIIEdaADAgECAhAOmxiO+dAt5+/bUOIIQBhaMA0GCSqGSIb3DQEBDAUA
# MGUxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsT
# EHd3dy5kaWdpY2VydC5jb20xJDAiBgNVBAMTG0RpZ2lDZXJ0IEFzc3VyZWQgSUQg
# Um9vdCBDQTAeFw0yMjA4MDEwMDAwMDBaFw0zMTExMDkyMzU5NTlaMGIxCzAJBgNV
# BAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdp
# Y2VydC5jb20xITAfBgNVBAMTGERpZ2lDZXJ0IFRydXN0ZWQgUm9vdCBHNDCCAiIw
# DQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAL/mkHNo3rvkXUo8MCIwaTPswqcl
# LskhPfKK2FnC4SmnPVirdprNrnsbhA3EMB/zG6Q4FutWxpdtHauyefLKEdLkX9YF
# PFIPUh/GnhWlfr6fqVcWWVVyr2iTcMKyunWZanMylNEQRBAu34LzB4TmdDttceIt
# DBvuINXJIB1jKS3O7F5OyJP4IWGbNOsFxl7sWxq868nPzaw0QF+xembud8hIqGZX
# V59UWI4MK7dPpzDZVu7Ke13jrclPXuU15zHL2pNe3I6PgNq2kZhAkHnDeMe2scS1
# ahg4AxCN2NQ3pC4FfYj1gj4QkXCrVYJBMtfbBHMqbpEBfCFM1LyuGwN1XXhm2Tox
# RJozQL8I11pJpMLmqaBn3aQnvKFPObURWBf3JFxGj2T3wWmIdph2PVldQnaHiZdp
# ekjw4KISG2aadMreSx7nDmOu5tTvkpI6nj3cAORFJYm2mkQZK37AlLTSYW3rM9nF
# 30sEAMx9HJXDj/chsrIRt7t/8tWMcCxBYKqxYxhElRp2Yn72gLD76GSmM9GJB+G9
# t+ZDpBi4pncB4Q+UDCEdslQpJYls5Q5SUUd0viastkF13nqsX40/ybzTQRESW+UQ
# UOsxxcpyFiIJ33xMdT9j7CFfxCBRa2+xq4aLT8LWRV+dIPyhHsXAj6KxfgommfXk
# aS+YHS312amyHeUbAgMBAAGjggE6MIIBNjAPBgNVHRMBAf8EBTADAQH/MB0GA1Ud
# DgQWBBTs1+OC0nFdZEzfLmc/57qYrhwPTzAfBgNVHSMEGDAWgBRF66Kv9JLLgjEt
# UYunpyGd823IDzAOBgNVHQ8BAf8EBAMCAYYweQYIKwYBBQUHAQEEbTBrMCQGCCsG
# AQUFBzABhhhodHRwOi8vb2NzcC5kaWdpY2VydC5jb20wQwYIKwYBBQUHMAKGN2h0
# dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEFzc3VyZWRJRFJvb3RD
# QS5jcnQwRQYDVR0fBD4wPDA6oDigNoY0aHR0cDovL2NybDMuZGlnaWNlcnQuY29t
# L0RpZ2lDZXJ0QXNzdXJlZElEUm9vdENBLmNybDARBgNVHSAECjAIMAYGBFUdIAAw
# DQYJKoZIhvcNAQEMBQADggEBAHCgv0NcVec4X6CjdBs9thbX979XB72arKGHLOyF
# XqkauyL4hxppVCLtpIh3bb0aFPQTSnovLbc47/T/gLn4offyct4kvFIDyE7QKt76
# LVbP+fT3rDB6mouyXtTP0UNEm0Mh65ZyoUi0mcudT6cGAxN3J0TU53/oWajwvy8L
# punyNDzs9wPHh6jSTEAZNUZqaVSwuKFWjuyk1T3osdz9HNj0d1pcVIxv76FQPfx2
# CWiEn2/K2yCNNWAcAgPLILCsWKAOQGPFmCLBsln1VWvPJ6tsds5vIy30fnFqI2si
# /xK4VC0nftg62fC2h5b9W9FcrBjDTZ9ztwGpn1eqXijiuZQxggN2MIIDcgIBATB3
# MGMxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjE7MDkGA1UE
# AxMyRGlnaUNlcnQgVHJ1c3RlZCBHNCBSU0E0MDk2IFNIQTI1NiBUaW1lU3RhbXBp
# bmcgQ0ECEAuuZrxaun+Vh8b56QTjMwQwDQYJYIZIAWUDBAIBBQCggdEwGgYJKoZI
# hvcNAQkDMQ0GCyqGSIb3DQEJEAEEMBwGCSqGSIb3DQEJBTEPFw0yNTAzMzExMTQ5
# MjFaMCsGCyqGSIb3DQEJEAIMMRwwGjAYMBYEFNvThe5i29I+e+T2cUhQhyTVhltF
# MC8GCSqGSIb3DQEJBDEiBCCLatzxUrZamwu5bK0Um1id2ieHrp3Cwz36L7/shCOl
# ujA3BgsqhkiG9w0BCRACLzEoMCYwJDAiBCB2dp+o8mMvH0MLOiMwrtZWdf7Xc9sF
# 1mW5BZOYQ4+a2zANBgkqhkiG9w0BAQEFAASCAgAp4956q/Cik8kkWEv/ISWrfQHZ
# DNbWxeBK98JArM64IQGaPmz4n00LILtzVLSEjquGtz9kQC0JwHlFnNy81wfN4qKZ
# naGNQ2GWM5UzkTrjDjTHaAkRzNBwWQ9WMTPkzd1QDGDZbum9YNQT17W7CIq+YN8v
# D7F1ZlEXe0zDlFkKgUI8CAGiPNe6YirkKdYOkjE86HzsjDsmDkEJsF0yeb//rPeB
# fGkQIpgA5Ub0gpudRnopPsGv3tq9e39YoC260qC8lPJkDmyRvnJYhMouWikWPzg/
# F4f/+svn1Y47erLqhgE+CVQat2is7J9sBhIhtfBr4Q0UZMrRNGLx+CXQXqGqrj/G
# PldARyb8XgTiB39wpdOPqdLN3gXegTQQwmkD+9OAxEdq2aJh8jhxnrIUkcMqvNIa
# gHPzX4U8yrVnN67WdloqXG6MOsf16uRUb6cA0WZzPa39ksLGcSjZ6E+Q3ZwMugGo
# gzUnqJ/Pk7dEUw8ETrSrBwzMmVmT12bSkCAfgwIzGSzBH+6yhunExoaaVSiTXAxj
# vMY38ZalzlgV6i5o9appqBf8U69iEn6fVq65l9lBV919bO64Gk87Q5nizgErxtrF
# K9Pzs9ClxucuyevzsaALPlwNXC9Pzv5Du8ORsSeyomXHquR+HTMp+R9ZzDxfY6Qs
# PcQEFJZIPVITb990ZQ==
# SIG # End signature block
