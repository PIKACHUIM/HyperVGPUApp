#
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
# MIItOwYJKoZIhvcNAQcCoIItLDCCLSgCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCA5or5XxC3agQrZ
# aMZAXbR5pDRyaVldSlR+KSGpyxmrC6CCEiEwggVvMIIEV6ADAgECAhBI/JO0YFWU
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
# PlmEocQbOuqUqdExghpwMIIabAIBATBpMFQxCzAJBgNVBAYTAkdCMRgwFgYDVQQK
# Ew9TZWN0aWdvIExpbWl0ZWQxKzApBgNVBAMTIlNlY3RpZ28gUHVibGljIENvZGUg
# U2lnbmluZyBDQSBSMzYCEQDJQtVKxGjxZ+PGgaihP65RMA0GCWCGSAFlAwQCAQUA
# oHwwEAYKKwYBBAGCNwIBDDECMAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQw
# HAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIA9g
# E1EjF8LuPDDOU2wcmLP8FjszjeYMdwJRCLc0fWU3MA0GCSqGSIb3DQEBAQUABIIC
# AEr78LgyuIF2WI7OCvxcLdnykMcgSUGUJedLTKq4FekdRTASCBGQYtIScGUFFZDk
# i10ZvxFkNJHUgJoh51roclYUtTTRFTj7R8HpvsyDUbUces5QTqGjwo6bVjyOqbAo
# P4xdNjJTYtvyMc++QbyK/G1usD5eglXSCb1PXXZ/zoERdOjGsTA1B8l8xCy8k/GN
# U2ZHqwy6ZDRFcJ2+kZP3UBImBD6q1SQ7SqOP6xPeBg4J7p4oPOHYKErTYQ1cBw/c
# 4GlOS66+Uz9j9+2Kxq0bAc8sEgXzBaNGrAitZ05qPlBsjGgaRc178p4yG2lP9oAC
# KtMu3kRRXl3byMTyvw2XnXJvS8XweMllXMqodzGii0CpnWQmeGOM2wHKfJADuLzh
# xKUReLL5xa3krGc/o7InJjYtJ+wwecOCy5atHsRlxwi9AFse/NaSSAky63V2O6uU
# zHR7ouaF6l4zzw8tNGbLtbQgwgmaQphnz7ge3LAU4wDm+9uPeMCyQVF+tg6aE56N
# FntgVYaopzSz8SXVOdTyM9erIpF95oPcYpktA7Zv5LksiPmrLDBW2BMeSKKJncDG
# +gAtC7rDPGGV2Cjhys7bqeSg6dC1Rqnu8HS2OxD4P29A3NDx55mf2Gb0RPYeEUEL
# xUnNZiba7Yi5MkL3C16CURejuUCj7ti6A7+Xsv5Av0OqoYIXWjCCF1YGCisGAQQB
# gjcDAwExghdGMIIXQgYJKoZIhvcNAQcCoIIXMzCCFy8CAQMxDzANBglghkgBZQME
# AgIFADCBhwYLKoZIhvcNAQkQAQSgeAR2MHQCAQEGCWCGSAGG/WwHATBBMA0GCWCG
# SAFlAwQCAgUABDASmvSdYcKaqprQD2jlxPmIocWTqu/VRmvOxzVvzQy+g7uKN1zt
# abLoqBLDhgZTetwCEFAzx3q+BhAt0GqPoFDG+0gYDzIwMjQxMjExMTAwNjUxWqCC
# EwMwgga8MIIEpKADAgECAhALrma8Wrp/lYfG+ekE4zMEMA0GCSqGSIb3DQEBCwUA
# MGMxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjE7MDkGA1UE
# AxMyRGlnaUNlcnQgVHJ1c3RlZCBHNCBSU0E0MDk2IFNIQTI1NiBUaW1lU3RhbXBp
# bmcgQ0EwHhcNMjQwOTI2MDAwMDAwWhcNMzUxMTI1MjM1OTU5WjBCMQswCQYDVQQG
# EwJVUzERMA8GA1UEChMIRGlnaUNlcnQxIDAeBgNVBAMTF0RpZ2lDZXJ0IFRpbWVz
# dGFtcCAyMDI0MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAvmpzn/aV
# IauWMLpbbeZZo7Xo/ZEfGMSIO2qZ46XB/QowIEMSvgjEdEZ3v4vrrTHleW1JWGEr
# rjOL0J4L0HqVR1czSzvUQ5xF7z4IQmn7dHY7yijvoQ7ujm0u6yXF2v1CrzZopykD
# 07/9fpAT4BxpT9vJoJqAsP8YuhRvflJ9YeHjes4fduksTHulntq9WelRWY++TFPx
# zZrbILRYynyEy7rS1lHQKFpXvo2GePfsMRhNf1F41nyEg5h7iOXv+vjX0K8RhUis
# fqw3TTLHj1uhS66YX2LZPxS4oaf33rp9HlfqSBePejlYeEdU740GKQM7SaVSH3Tb
# BL8R6HwX9QVpGnXPlKdE4fBIn5BBFnV+KwPxRNUNK6lYk2y1WSKour4hJN0SMkoa
# NV8hyyADiX1xuTxKaXN12HgR+8WulU2d6zhzXomJ2PleI9V2yfmfXSPGYanGgxzq
# I+ShoOGLomMd3mJt92nm7Mheng/TBeSA2z4I78JpwGpTRHiT7yHqBiV2ngUIyCtd
# 0pZ8zg3S7bk4QC4RrcnKJ3FbjyPAGogmoiZ33c1HG93Vp6lJ415ERcC7bFQMRbxq
# rMVANiav1k425zYyFMyLNyE1QulQSgDpW9rtvVcIH7WvG9sqYup9j8z9J1XqbBZP
# J5XLln8mS8wWmdDLnBHXgYly/p1DhoQo5fkCAwEAAaOCAYswggGHMA4GA1UdDwEB
# /wQEAwIHgDAMBgNVHRMBAf8EAjAAMBYGA1UdJQEB/wQMMAoGCCsGAQUFBwMIMCAG
# A1UdIAQZMBcwCAYGZ4EMAQQCMAsGCWCGSAGG/WwHATAfBgNVHSMEGDAWgBS6Ftlt
# TYUvcyl2mi91jGogj57IbzAdBgNVHQ4EFgQUn1csA3cOKBWQZqVjXu5Pkh92oFsw
# WgYDVR0fBFMwUTBPoE2gS4ZJaHR0cDovL2NybDMuZGlnaWNlcnQuY29tL0RpZ2lD
# ZXJ0VHJ1c3RlZEc0UlNBNDA5NlNIQTI1NlRpbWVTdGFtcGluZ0NBLmNybDCBkAYI
# KwYBBQUHAQEEgYMwgYAwJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0
# LmNvbTBYBggrBgEFBQcwAoZMaHR0cDovL2NhY2VydHMuZGlnaWNlcnQuY29tL0Rp
# Z2lDZXJ0VHJ1c3RlZEc0UlNBNDA5NlNIQTI1NlRpbWVTdGFtcGluZ0NBLmNydDAN
# BgkqhkiG9w0BAQsFAAOCAgEAPa0eH3aZW+M4hBJH2UOR9hHbm04IHdEoT8/T3HuB
# SyZeq3jSi5GXeWP7xCKhVireKCnCs+8GZl2uVYFvQe+pPTScVJeCZSsMo1JCoZN2
# mMew/L4tpqVNbSpWO9QGFwfMEy60HofN6V51sMLMXNTLfhVqs+e8haupWiArSozy
# AmGH/6oMQAh078qRh6wvJNU6gnh5OruCP1QUAvVSu4kqVOcJVozZR5RRb/zPd++P
# GE3qF1P3xWvYViUJLsxtvge/mzA75oBfFZSbdakHJe2BVDGIGVNVjOp8sNt70+kE
# oMF+T6tptMUNlehSR7vM+C13v9+9ZOUKzfRUAYSyyEmYtsnpltD/GWX8eM70ls1V
# 6QG/ZOB6b6Yum1HvIiulqJ1Elesj5TMHq8CWT/xrW7twipXTJ5/i5pkU5E16RSBA
# dOp12aw8IQhhA/vEbFkEiF2abhuFixUDobZaA0VhqAsMHOmaT3XThZDNi5U2zHKh
# Us5uHHdG6BoQau75KiNbh0c+hatSF+02kULkftARjsyEpHKsF7u5zKRbt5oK5YGw
# Fvgc4pEVUNytmB3BpIiowOIIuDgP5M9WArHYSAR16gc0dP2XdkMEP5eBsX7bf/MG
# N4K3HP50v/01ZHo/Z5lGLvNwQ7XHBx1yomzLP8lx4Q1zZKDyHcp4VQJLu2kWTsKs
# OqQwggauMIIElqADAgECAhAHNje3JFR82Ees/ShmKl5bMA0GCSqGSIb3DQEBCwUA
# MGIxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsT
# EHd3dy5kaWdpY2VydC5jb20xITAfBgNVBAMTGERpZ2lDZXJ0IFRydXN0ZWQgUm9v
# dCBHNDAeFw0yMjAzMjMwMDAwMDBaFw0zNzAzMjIyMzU5NTlaMGMxCzAJBgNVBAYT
# AlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjE7MDkGA1UEAxMyRGlnaUNlcnQg
# VHJ1c3RlZCBHNCBSU0E0MDk2IFNIQTI1NiBUaW1lU3RhbXBpbmcgQ0EwggIiMA0G
# CSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQDGhjUGSbPBPXJJUVXHJQPE8pE3qZdR
# odbSg9GeTKJtoLDMg/la9hGhRBVCX6SI82j6ffOciQt/nR+eDzMfUBMLJnOWbfhX
# qAJ9/UO0hNoR8XOxs+4rgISKIhjf69o9xBd/qxkrPkLcZ47qUT3w1lbU5ygt69Ox
# tXXnHwZljZQp09nsad/ZkIdGAHvbREGJ3HxqV3rwN3mfXazL6IRktFLydkf3YYMZ
# 3V+0VAshaG43IbtArF+y3kp9zvU5EmfvDqVjbOSmxR3NNg1c1eYbqMFkdECnwHLF
# uk4fsbVYTXn+149zk6wsOeKlSNbwsDETqVcplicu9Yemj052FVUmcJgmf6AaRyBD
# 40NjgHt1biclkJg6OBGz9vae5jtb7IHeIhTZgirHkr+g3uM+onP65x9abJTyUpUR
# K1h0QCirc0PO30qhHGs4xSnzyqqWc0Jon7ZGs506o9UD4L/wojzKQtwYSH8UNM/S
# TKvvmz3+DrhkKvp1KCRB7UK/BZxmSVJQ9FHzNklNiyDSLFc1eSuo80VgvCONWPfc
# Yd6T/jnA+bIwpUzX6ZhKWD7TA4j+s4/TXkt2ElGTyYwMO1uKIqjBJgj5FBASA31f
# I7tk42PgpuE+9sJ0sj8eCXbsq11GdeJgo1gJASgADoRU7s7pXcheMBK9Rp6103a5
# 0g5rmQzSM7TNsQIDAQABo4IBXTCCAVkwEgYDVR0TAQH/BAgwBgEB/wIBADAdBgNV
# HQ4EFgQUuhbZbU2FL3MpdpovdYxqII+eyG8wHwYDVR0jBBgwFoAU7NfjgtJxXWRM
# 3y5nP+e6mK4cD08wDgYDVR0PAQH/BAQDAgGGMBMGA1UdJQQMMAoGCCsGAQUFBwMI
# MHcGCCsGAQUFBwEBBGswaTAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNl
# cnQuY29tMEEGCCsGAQUFBzAChjVodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20v
# RGlnaUNlcnRUcnVzdGVkUm9vdEc0LmNydDBDBgNVHR8EPDA6MDigNqA0hjJodHRw
# Oi8vY3JsMy5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVkUm9vdEc0LmNybDAg
# BgNVHSAEGTAXMAgGBmeBDAEEAjALBglghkgBhv1sBwEwDQYJKoZIhvcNAQELBQAD
# ggIBAH1ZjsCTtm+YqUQiAX5m1tghQuGwGC4QTRPPMFPOvxj7x1Bd4ksp+3CKDaop
# afxpwc8dB+k+YMjYC+VcW9dth/qEICU0MWfNthKWb8RQTGIdDAiCqBa9qVbPFXON
# ASIlzpVpP0d3+3J0FNf/q0+KLHqrhc1DX+1gtqpPkWaeLJ7giqzl/Yy8ZCaHbJK9
# nXzQcAp876i8dU+6WvepELJd6f8oVInw1YpxdmXazPByoyP6wCeCRK6ZJxurJB4m
# wbfeKuv2nrF5mYGjVoarCkXJ38SNoOeY+/umnXKvxMfBwWpx2cYTgAnEtp/Nh4ck
# u0+jSbl3ZpHxcpzpSwJSpzd+k1OsOx0ISQ+UzTl63f8lY5knLD0/a6fxZsNBzU+2
# QJshIUDQtxMkzdwdeDrknq3lNHGS1yZr5Dhzq6YBT70/O3itTK37xJV77QpfMzmH
# QXh6OOmc4d0j/R0o08f56PGYX/sr2H7yRp11LB4nLCbbbxV7HhmLNriT1ObyF5lZ
# ynDwN7+YAN8gFk8n+2BnFqFmut1VwDophrCYoCvtlUG3OtUVmDG0YgkPCr2B2RP+
# v6TR81fZvAT6gt4y3wSJ8ADNXcL50CN/AAvkdgIm2fBldkKmKYcJRyvmfxqkhQ/8
# mJb2VVQrH4D6wPIOK+XW+6kvRBVK5xMOHds3OBqhK/bt1nz8MIIFjTCCBHWgAwIB
# AgIQDpsYjvnQLefv21DiCEAYWjANBgkqhkiG9w0BAQwFADBlMQswCQYDVQQGEwJV
# UzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQu
# Y29tMSQwIgYDVQQDExtEaWdpQ2VydCBBc3N1cmVkIElEIFJvb3QgQ0EwHhcNMjIw
# ODAxMDAwMDAwWhcNMzExMTA5MjM1OTU5WjBiMQswCQYDVQQGEwJVUzEVMBMGA1UE
# ChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMSEwHwYD
# VQQDExhEaWdpQ2VydCBUcnVzdGVkIFJvb3QgRzQwggIiMA0GCSqGSIb3DQEBAQUA
# A4ICDwAwggIKAoICAQC/5pBzaN675F1KPDAiMGkz7MKnJS7JIT3yithZwuEppz1Y
# q3aaza57G4QNxDAf8xukOBbrVsaXbR2rsnnyyhHS5F/WBTxSD1Ifxp4VpX6+n6lX
# FllVcq9ok3DCsrp1mWpzMpTREEQQLt+C8weE5nQ7bXHiLQwb7iDVySAdYyktzuxe
# TsiT+CFhmzTrBcZe7FsavOvJz82sNEBfsXpm7nfISKhmV1efVFiODCu3T6cw2Vbu
# yntd463JT17lNecxy9qTXtyOj4DatpGYQJB5w3jHtrHEtWoYOAMQjdjUN6QuBX2I
# 9YI+EJFwq1WCQTLX2wRzKm6RAXwhTNS8rhsDdV14Ztk6MUSaM0C/CNdaSaTC5qmg
# Z92kJ7yhTzm1EVgX9yRcRo9k98FpiHaYdj1ZXUJ2h4mXaXpI8OCiEhtmmnTK3kse
# 5w5jrubU75KSOp493ADkRSWJtppEGSt+wJS00mFt6zPZxd9LBADMfRyVw4/3IbKy
# Ebe7f/LVjHAsQWCqsWMYRJUadmJ+9oCw++hkpjPRiQfhvbfmQ6QYuKZ3AeEPlAwh
# HbJUKSWJbOUOUlFHdL4mrLZBdd56rF+NP8m800ERElvlEFDrMcXKchYiCd98THU/
# Y+whX8QgUWtvsauGi0/C1kVfnSD8oR7FwI+isX4KJpn15GkvmB0t9dmpsh3lGwID
# AQABo4IBOjCCATYwDwYDVR0TAQH/BAUwAwEB/zAdBgNVHQ4EFgQU7NfjgtJxXWRM
# 3y5nP+e6mK4cD08wHwYDVR0jBBgwFoAUReuir/SSy4IxLVGLp6chnfNtyA8wDgYD
# VR0PAQH/BAQDAgGGMHkGCCsGAQUFBwEBBG0wazAkBggrBgEFBQcwAYYYaHR0cDov
# L29jc3AuZGlnaWNlcnQuY29tMEMGCCsGAQUFBzAChjdodHRwOi8vY2FjZXJ0cy5k
# aWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3J0MEUGA1UdHwQ+
# MDwwOqA4oDaGNGh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEFzc3Vy
# ZWRJRFJvb3RDQS5jcmwwEQYDVR0gBAowCDAGBgRVHSAAMA0GCSqGSIb3DQEBDAUA
# A4IBAQBwoL9DXFXnOF+go3QbPbYW1/e/Vwe9mqyhhyzshV6pGrsi+IcaaVQi7aSI
# d229GhT0E0p6Ly23OO/0/4C5+KH38nLeJLxSA8hO0Cre+i1Wz/n096wwepqLsl7U
# z9FDRJtDIeuWcqFItJnLnU+nBgMTdydE1Od/6Fmo8L8vC6bp8jQ87PcDx4eo0kxA
# GTVGamlUsLihVo7spNU96LHc/RzY9HdaXFSMb++hUD38dglohJ9vytsgjTVgHAID
# yyCwrFigDkBjxZgiwbJZ9VVrzyerbHbObyMt9H5xaiNrIv8SuFQtJ37YOtnwtoeW
# /VvRXKwYw02fc7cBqZ9Xql4o4rmUMYIDhjCCA4ICAQEwdzBjMQswCQYDVQQGEwJV
# UzEXMBUGA1UEChMORGlnaUNlcnQsIEluYy4xOzA5BgNVBAMTMkRpZ2lDZXJ0IFRy
# dXN0ZWQgRzQgUlNBNDA5NiBTSEEyNTYgVGltZVN0YW1waW5nIENBAhALrma8Wrp/
# lYfG+ekE4zMEMA0GCWCGSAFlAwQCAgUAoIHhMBoGCSqGSIb3DQEJAzENBgsqhkiG
# 9w0BCRABBDAcBgkqhkiG9w0BCQUxDxcNMjQxMjExMTAwNjUxWjArBgsqhkiG9w0B
# CRACDDEcMBowGDAWBBTb04XuYtvSPnvk9nFIUIck1YZbRTA3BgsqhkiG9w0BCRAC
# LzEoMCYwJDAiBCB2dp+o8mMvH0MLOiMwrtZWdf7Xc9sF1mW5BZOYQ4+a2zA/Bgkq
# hkiG9w0BCQQxMgQwLHNLfNqvBVbusOnLbply19Jb6qsag4VIpSSSSTyhCRM6E08H
# tPf/cUvDPzvzeUrgMA0GCSqGSIb3DQEBAQUABIICABIsblKRh5XqUtDTmvNOU34j
# ik45OHL32yECivgL7SO3V5v4m7XzIYv+xXxMRazD8Chl1P1HPDPIXfEWOXmyjT/L
# xB5Lm0e3VVcUHPPviUyHVCc/ueQMps90MfvvhjpHAt0S8WfNMEWUB09FHPYpvE2A
# li6qCjGexvzj0+p5TnosJGxXDOA3JEcFJTB60S+6jac0S6IH9EnyOCCDZ7bQHZf7
# q6q9yDuFWfXio/e4B5kK6IJmSVBT1V8YlY4OQ0CSXgpYlc3uzNVXDVYFxlJjIh//
# 3EzEPj0WrBP4UmdwBrVfiSU9+JBi3c/HMmUZF9cmG9VBZMxNWA4kMaYN2TUh2F23
# /hXdO2qImTNlSTWVmkdbOZQmbO5GSvd+H+fS4DFnz1ZFYQz4z7Dy2k9ohrC2G5Kt
# bV5DQ77ErnqiCijN6I0JzkDqHD6V+Ul/8vVSAGjshHKslAZ9+Mrbz8G0D3dd51zF
# COjews2a+RaNjUAE0jqp5yb4oapB+uUQGngnoMey+5FqRl9CA4bXZvg4BYhWiwql
# FYry1heABmecZ1Rv/RekEO+6wVzBeF+6obYhCAZaFJ9TsRfDlCdndF4usItCD5Vf
# ESjPtmzRsl5EFUVYK6NmaDgXXrS2grQi9JEPaxfdtgsSOwye5enMQM+7r1jjhzpn
# Y4rU8ZEPuhbIk30rWqy2
# SIG # End signature block
