<#   
.SYNOPSIS
Automate the ALM Process by moving a solution between a source and destination environment while allowing for solution versioning 

.DESCRIPTION
This script requires the use of a Service Principal account and was designed for use with Partner Admin Link (PAL) as it will validate the Service Principal before proceeding with any ALM operation. MAKE SURE that in each environment that the Service Principal account used has the SYSTEM ADMIN ROLE in each of the ENVIRONMENTS (Source/Destination). 

Aditionally this script REQUIRES that you have the Power Platform CLI installed. run the following command in a command prompt "C:\"

    PAC

    Microsoft PowerPlatform CLI
    Version: 1.14.4+g960f65f

First two lines returned, should be similar to the output as shown above

.INPUTS
None

.OUTPUTS
Feedback as to the process. Feedback can come from either PowerShell or the Power Platform CLI

.LINK
https://docs.microsoft.com/en-us/power-apps/developer/data-platform/powerapps-cli


.EXAMPLE
> ALM_PP_CLI -TenantId <<GUID>> -ApplicationId -ClientSecret -SourceEnvironment <<URL>> -DestinationEnvironment <<URL>> -Solution <<TEXT>> -OnlineVersion << TEXT #.#.#.# >>

.NOTES   
    Title:    ©2022 Microsoft - Partner Application Link, Power Platform CLI
    Platform: Windows PowerShell 5.1 *** DOES NOT SUPPORT POWERSHELL CORE ***
    Author:   David Soden
    Profile:  https://davidsoden.com
    Modified: 5/2/2022
    Dependency: Power Platform CLI 
    Download: https://aka.ms/PowerAppsCLI  
#>
[CmdletBinding()]
Param(
    # Set Variables
    [Parameter(Mandatory=$true, HelpMessage="Tenant GUID...")]
        [String]$TenantId = "", 
    [Parameter(Mandatory=$true, HelpMessage="Service Principal or AppID...")]
        [String]$ApplicationId = "", 
    [Parameter(Mandatory=$true, HelpMessage="Service principal Secret...")]
        [String]$ClientSecret = "", 
    [Parameter(Mandatory=$true, HelpMessage="Environment to export from...")]
        [String]$SourceEnvironment = "", 
    [Parameter(Mandatory=$true, HelpMessage="Environment to import into...")]
        [String]$DestinationEnvironment = "", 
    [Parameter(Mandatory=$true, HelpMessage="Name of the Solution to move across environments...")]
        [String]$Solution = "", 
    [Parameter(Mandatory=$true, HelpMessage="Solution Version-> Example 1.0.0.1")]
        [String]$OnlineVersion = "" 
)

#------------------------------------------------------------------------------------
# PAL Association Check
#------------------------------------------------------------------------------------
$SecureStringPwd = $ClientSecret | ConvertTo-SecureString -AsPlainText -Force
$pscredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $ApplicationId, $SecureStringPwd
Connect-AzAccount -ServicePrincipal -Credential $pscredential -Tenant $TenantId

$MPN_Check = Get-AzManagementPartner
if($null -eq $MPN_Check){
    Write-Output "The Service Principal account used does NOT have a PAL Association,"
    Write-Output "MAU credits on this Solution and its applications will not be reported or credited to your Partnership"
    Write-Output "This job will now terminate and no Solutions will be moved"
    Write-Output "This window will self close in 10 seconds"
    Start-Sleep -Seconds 10
    Exit
}
#------------------------------------------------------------------------------------
# ALM with Power Platform CLI https://aka.ms/PowerAppsCLI
# -----------------------------------------------------------------------------------
# Create the credentials
Clear-Host
pac auth clear
pac auth create -n Dev -u $SourceEnvironment -id $ApplicationId -cs $ClientSecret -t $TenantId
pac auth create -n Prod -u $DestinationEnvironment -id $ApplicationId -cs $ClientSecret -t $TenantId
# Run the ALM from DEV to PROD
Clear-Host
pac auth select -i 1
pac solution online-version -sn $Solution -sv $OnlineVersion
pac solution export -m -n $Solution -p .\$Solution.zip
pac auth select -i 2
pac solution import -p .\$Solution.zip

#------------------------------------------------------------------------------------
# Take control over a canvas app - does not work on Model Driven Apps
#------------------------------------------------------------------------------------
## Take ownership of the Canvas App
#Add-PowerAppsAccount
#Set-AdminPowerAppOwner -AppName [[USER GUID]] -AppOwner $Global:currentSession.userId -EnvironmentName [[ENV GUID]]

#------------------------------------------------------------------------------------

# THIS SCRIPT IS DIGITALLY SIGNED BY DAVID SODEN BELOW 
# DO NOT REMOVE UNLESS YOU RESIGN OR CHANGE YOUR ExecutionPolicy

# SIG # Begin signature block
# MIIVjAYJKoZIhvcNAQcCoIIVfTCCFXkCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUoZTZzC4YMYTILjJVlhriaZBT
# mVCgghHsMIIFbzCCBFegAwIBAgIQSPyTtGBVlI02p8mKidaUFjANBgkqhkiG9w0B
# AQwFADB7MQswCQYDVQQGEwJHQjEbMBkGA1UECAwSR3JlYXRlciBNYW5jaGVzdGVy
# MRAwDgYDVQQHDAdTYWxmb3JkMRowGAYDVQQKDBFDb21vZG8gQ0EgTGltaXRlZDEh
# MB8GA1UEAwwYQUFBIENlcnRpZmljYXRlIFNlcnZpY2VzMB4XDTIxMDUyNTAwMDAw
# MFoXDTI4MTIzMTIzNTk1OVowVjELMAkGA1UEBhMCR0IxGDAWBgNVBAoTD1NlY3Rp
# Z28gTGltaXRlZDEtMCsGA1UEAxMkU2VjdGlnbyBQdWJsaWMgQ29kZSBTaWduaW5n
# IFJvb3QgUjQ2MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAjeeUEiIE
# JHQu/xYjApKKtq42haxH1CORKz7cfeIxoFFvrISR41KKteKW3tCHYySJiv/vEpM7
# fbu2ir29BX8nm2tl06UMabG8STma8W1uquSggyfamg0rUOlLW7O4ZDakfko9qXGr
# YbNzszwLDO/bM1flvjQ345cbXf0fEj2CA3bm+z9m0pQxafptszSswXp43JJQ8mTH
# qi0Eq8Nq6uAvp6fcbtfo/9ohq0C/ue4NnsbZnpnvxt4fqQx2sycgoda6/YDnAdLv
# 64IplXCN/7sVz/7RDzaiLk8ykHRGa0c1E3cFM09jLrgt4b9lpwRrGNhx+swI8m2J
# mRCxrds+LOSqGLDGBwF1Z95t6WNjHjZ/aYm+qkU+blpfj6Fby50whjDoA7NAxg0P
# OM1nqFOI+rgwZfpvx+cdsYN0aT6sxGg7seZnM5q2COCABUhA7vaCZEao9XOwBpXy
# bGWfv1VbHJxXGsd4RnxwqpQbghesh+m2yQ6BHEDWFhcp/FycGCvqRfXvvdVnTyhe
# Be6QTHrnxvTQ/PrNPjJGEyA2igTqt6oHRpwNkzoJZplYXCmjuQymMDg80EY2NXyc
# uu7D1fkKdvp+BRtAypI16dV60bV/AK6pkKrFfwGcELEW/MxuGNxvYv6mUKe4e7id
# FT/+IAx1yCJaE5UZkADpGtXChvHjjuxf9OUCAwEAAaOCARIwggEOMB8GA1UdIwQY
# MBaAFKARCiM+lvEH7OKvKe+CpX/QMKS0MB0GA1UdDgQWBBQy65Ka/zWWSC8oQEJw
# IDaRXBeF5jAOBgNVHQ8BAf8EBAMCAYYwDwYDVR0TAQH/BAUwAwEB/zATBgNVHSUE
# DDAKBggrBgEFBQcDAzAbBgNVHSAEFDASMAYGBFUdIAAwCAYGZ4EMAQQBMEMGA1Ud
# HwQ8MDowOKA2oDSGMmh0dHA6Ly9jcmwuY29tb2RvY2EuY29tL0FBQUNlcnRpZmlj
# YXRlU2VydmljZXMuY3JsMDQGCCsGAQUFBwEBBCgwJjAkBggrBgEFBQcwAYYYaHR0
# cDovL29jc3AuY29tb2RvY2EuY29tMA0GCSqGSIb3DQEBDAUAA4IBAQASv6Hvi3Sa
# mES4aUa1qyQKDKSKZ7g6gb9Fin1SB6iNH04hhTmja14tIIa/ELiueTtTzbT72ES+
# BtlcY2fUQBaHRIZyKtYyFfUSg8L54V0RQGf2QidyxSPiAjgaTCDi2wH3zUZPJqJ8
# ZsBRNraJAlTH/Fj7bADu/pimLpWhDFMpH2/YGaZPnvesCepdgsaLr4CnvYFIUoQx
# 2jLsFeSmTD1sOXPUC4U5IOCFGmjhp0g4qdE2JXfBjRkWxYhMZn0vY86Y6GnfrDyo
# XZ3JHFuu2PMvdM+4fvbXg50RlmKarkUT2n/cR/vfw1Kf5gZV6Z2M8jpiUbzsJA8p
# 1FiAhORFe1rYMIIGGjCCBAKgAwIBAgIQYh1tDFIBnjuQeRUgiSEcCjANBgkqhkiG
# 9w0BAQwFADBWMQswCQYDVQQGEwJHQjEYMBYGA1UEChMPU2VjdGlnbyBMaW1pdGVk
# MS0wKwYDVQQDEyRTZWN0aWdvIFB1YmxpYyBDb2RlIFNpZ25pbmcgUm9vdCBSNDYw
# HhcNMjEwMzIyMDAwMDAwWhcNMzYwMzIxMjM1OTU5WjBUMQswCQYDVQQGEwJHQjEY
# MBYGA1UEChMPU2VjdGlnbyBMaW1pdGVkMSswKQYDVQQDEyJTZWN0aWdvIFB1Ymxp
# YyBDb2RlIFNpZ25pbmcgQ0EgUjM2MIIBojANBgkqhkiG9w0BAQEFAAOCAY8AMIIB
# igKCAYEAmyudU/o1P45gBkNqwM/1f/bIU1MYyM7TbH78WAeVF3llMwsRHgBGRmxD
# eEDIArCS2VCoVk4Y/8j6stIkmYV5Gej4NgNjVQ4BYoDjGMwdjioXan1hlaGFt4Wk
# 9vT0k2oWJMJjL9G//N523hAm4jF4UjrW2pvv9+hdPX8tbbAfI3v0VdJiJPFy/7Xw
# iunD7mBxNtecM6ytIdUlh08T2z7mJEXZD9OWcJkZk5wDuf2q52PN43jc4T9OkoXZ
# 0arWZVeffvMr/iiIROSCzKoDmWABDRzV/UiQ5vqsaeFaqQdzFf4ed8peNWh1OaZX
# nYvZQgWx/SXiJDRSAolRzZEZquE6cbcH747FHncs/Kzcn0Ccv2jrOW+LPmnOyB+t
# AfiWu01TPhCr9VrkxsHC5qFNxaThTG5j4/Kc+ODD2dX/fmBECELcvzUHf9shoFvr
# n35XGf2RPaNTO2uSZ6n9otv7jElspkfK9qEATHZcodp+R4q2OIypxR//YEb3fkDn
# 3UayWW9bAgMBAAGjggFkMIIBYDAfBgNVHSMEGDAWgBQy65Ka/zWWSC8oQEJwIDaR
# XBeF5jAdBgNVHQ4EFgQUDyrLIIcouOxvSK4rVKYpqhekzQwwDgYDVR0PAQH/BAQD
# AgGGMBIGA1UdEwEB/wQIMAYBAf8CAQAwEwYDVR0lBAwwCgYIKwYBBQUHAwMwGwYD
# VR0gBBQwEjAGBgRVHSAAMAgGBmeBDAEEATBLBgNVHR8ERDBCMECgPqA8hjpodHRw
# Oi8vY3JsLnNlY3RpZ28uY29tL1NlY3RpZ29QdWJsaWNDb2RlU2lnbmluZ1Jvb3RS
# NDYuY3JsMHsGCCsGAQUFBwEBBG8wbTBGBggrBgEFBQcwAoY6aHR0cDovL2NydC5z
# ZWN0aWdvLmNvbS9TZWN0aWdvUHVibGljQ29kZVNpZ25pbmdSb290UjQ2LnA3YzAj
# BggrBgEFBQcwAYYXaHR0cDovL29jc3Auc2VjdGlnby5jb20wDQYJKoZIhvcNAQEM
# BQADggIBAAb/guF3YzZue6EVIJsT/wT+mHVEYcNWlXHRkT+FoetAQLHI1uBy/YXK
# ZDk8+Y1LoNqHrp22AKMGxQtgCivnDHFyAQ9GXTmlk7MjcgQbDCx6mn7yIawsppWk
# vfPkKaAQsiqaT9DnMWBHVNIabGqgQSGTrQWo43MOfsPynhbz2Hyxf5XWKZpRvr3d
# MapandPfYgoZ8iDL2OR3sYztgJrbG6VZ9DoTXFm1g0Rf97Aaen1l4c+w3DC+IkwF
# kvjFV3jS49ZSc4lShKK6BrPTJYs4NG1DGzmpToTnwoqZ8fAmi2XlZnuchC4NPSZa
# PATHvNIzt+z1PHo35D/f7j2pO1S8BCysQDHCbM5Mnomnq5aYcKCsdbh0czchOm8b
# kinLrYrKpii+Tk7pwL7TjRKLXkomm5D1Umds++pip8wH2cQpf93at3VDcOK4N7Ew
# oIJB0kak6pSzEu4I64U6gZs7tS/dGNSljf2OSSnRr7KWzq03zl8l75jy+hOds9TW
# SenLbjBQUGR96cFr6lEUfAIEHVC1L68Y1GGxx4/eRI82ut83axHMViw1+sVpbPxg
# 51Tbnio1lB93079WPFnYaOvfGAA0e0zcfF/M9gXr+korwQTh2Prqooq2bYNMvUoU
# KD85gnJ+t0smrWrb8dee2CvYZXD5laGtaAxOfy/VKNmwuWuAh9kcMIIGVzCCBL+g
# AwIBAgIRANKIr2Sbj5oFSFNQrsM7lvAwDQYJKoZIhvcNAQEMBQAwVDELMAkGA1UE
# BhMCR0IxGDAWBgNVBAoTD1NlY3RpZ28gTGltaXRlZDErMCkGA1UEAxMiU2VjdGln
# byBQdWJsaWMgQ29kZSBTaWduaW5nIENBIFIzNjAeFw0yMjA1MTcwMDAwMDBaFw0y
# NTA1MTYyMzU5NTlaMEsxCzAJBgNVBAYTAlVTMRAwDgYDVQQIDAdHZW9yZ2lhMRQw
# EgYDVQQKDAtEYXZpZCBTb2RlbjEUMBIGA1UEAwwLRGF2aWQgU29kZW4wggIiMA0G
# CSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQCqNGGJRCYYhPAQmfR2O3kL7cGzS0zr
# fZpRbeuul6d/lv+X8PwE1gg+b4S7OaLS7HNyjPlpUHkopSWLtaCF7zObH+ASsr9d
# nnMoAErg1EQQE0F/Ore0UlPfevcWdepZg7OjDw6VWpBlVywIF0PKWxx3C+/rgTG3
# S6VbMQxWAFtSxmgBZ8VkMZxcxFM1bzwg9n9eVzmqkBnZSZGLweyEAobGNKGOPYxj
# Z0YLsFGd4+7qCYs9lPYZUH1MdrJCp3KyIbuKTcnaSNM/8uxgsE0HOgAgBMpyBxt/
# yOlpaIDtuMoofv1hJldP+XIOBFmUGMSNMu2SZAgRnVLazKOSEnmvoopvCNrUdx5D
# 9eyUrtbGgubk0KeR49yvH8Bjg/PXl9LdrmnFEKdsyZFxSmpYzZnEZmdDUkmBp1Jo
# BtmEUWfL2xq/HDLN5RzYOBsaxXoWPQ2F+oOiIXLo4tQjP5VxoTUHPQ1pqGsFCMvx
# 2IEo+3w+JwG7H+H3rA3UGp/SaXgeXQhYQKGIEsN4kvYLPxTzqk06DtAQDsklaoKG
# 1DXkFGM7rJcdUwF59FXN4PjUpAmTNwDuzTJ+67nkmnaGfB2VB3CvoXt5N4hoUSqv
# eMxB52fgrEsRK33g4Vo3AwmeDvZMcL3GOXKtMVhkZOSjeXhht3FQ2kzQ0fux2W8v
# GCiKKZY5AouXBwIDAQABo4IBqzCCAacwHwYDVR0jBBgwFoAUDyrLIIcouOxvSK4r
# VKYpqhekzQwwHQYDVR0OBBYEFJ2Ye/KrqBKEGsk13QMgPGq2g1aOMA4GA1UdDwEB
# /wQEAwIHgDAMBgNVHRMBAf8EAjAAMBMGA1UdJQQMMAoGCCsGAQUFBwMDMEoGA1Ud
# IARDMEEwNQYMKwYBBAGyMQECAQMCMCUwIwYIKwYBBQUHAgEWF2h0dHBzOi8vc2Vj
# dGlnby5jb20vQ1BTMAgGBmeBDAEEATBJBgNVHR8EQjBAMD6gPKA6hjhodHRwOi8v
# Y3JsLnNlY3RpZ28uY29tL1NlY3RpZ29QdWJsaWNDb2RlU2lnbmluZ0NBUjM2LmNy
# bDB5BggrBgEFBQcBAQRtMGswRAYIKwYBBQUHMAKGOGh0dHA6Ly9jcnQuc2VjdGln
# by5jb20vU2VjdGlnb1B1YmxpY0NvZGVTaWduaW5nQ0FSMzYuY3J0MCMGCCsGAQUF
# BzABhhdodHRwOi8vb2NzcC5zZWN0aWdvLmNvbTAgBgNVHREEGTAXgRVEYXZpZFRT
# b2RlbkBnbWFpbC5jb20wDQYJKoZIhvcNAQEMBQADggGBAJK/NIqLhjTwB3s0G7c5
# l0Kgdk6JeKoUUt7Z4PzOXEXOh9cIJL8pTdZHnZ7e1sGINq75KYvSmv+CUkwZIaTs
# T2TlJe9VEm8M0nFxoHA90T6wCk7irZPAzF5hNTnRKC2eM4EfPlrHYVd9Yr7pHdp2
# 3i0Bl4AEzZqHd5v3sn+g3a5E2o2h2kLXFgVYVBfYl/4fJs27Tdy6biffDlivMwE5
# +a2Q/cp84T0P+1/X9D5jKsrwwELNbW81+60O/1uGJIHSYX+iUXr200eiKCkEZhZo
# GOCZWl9bfjFSg2QKPvdiZN5ls663H20+KB9K4C/YS9/S0UEnOewYmzwzFvhNIBwF
# KYMr7yWMge2juZbZaiShD1BNGUDYwofnvrxstjkN2lJpMMoxMwjPKwj0mz6a6HHc
# VCJWc9NwIJvb4jZTfkGGzt+XlBVUb7aL/DhGaMmzRxI3BMy2BGPs6wBh3iznAWCs
# YRhfvRAqadKfC16WXTpbzE0LJ3TKqCuekp1+Ur8bF9MqKTGCAwowggMGAgEBMGkw
# VDELMAkGA1UEBhMCR0IxGDAWBgNVBAoTD1NlY3RpZ28gTGltaXRlZDErMCkGA1UE
# AxMiU2VjdGlnbyBQdWJsaWMgQ29kZSBTaWduaW5nIENBIFIzNgIRANKIr2Sbj5oF
# SFNQrsM7lvAwCQYFKw4DAhoFAKB4MBgGCisGAQQBgjcCAQwxCjAIoAKAAKECgAAw
# GQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEOMAwGCisG
# AQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFEGuKBL3PbuklyZr8ob9qzf9Jgl1MA0G
# CSqGSIb3DQEBAQUABIICAH9kAXfmkNVQ8UFPiNJ+sm24KHeq9nubudBSj0dDVzsK
# Wee9vLBLlZsgrjzElLy6IBzS1mM4sODcezeDoZFrUovo3S5uequP37K9V6MjqLlZ
# G7D1vRVajR149cAcFs9PxXfwL6HNksmG2aubcHkmkoNzaVJ6kAzRZmUht4dP01cJ
# jB0yRED8qgzv6QITDj0h8KEbGiyY06r0CPg/DDE4IFn1j3Y1baPZL+vVzsJUTyOG
# Fk0LO5TloShlS7UV5U5uxpGT46gNkpxV/yDiZd2QabZPYUP3Fq6XNKJdMkediZ7i
# aP4+P/3j+Q4lpaDGBcldVPmKilIPN9B3zxxhmheGD9CmIgQel+P+BXTsidZ5K3bc
# VKdKejZintwOO5ohUroAMRT83Qh5umDjlNQUvzFoJ5OHDqhP+i3qhUDDvWlG5oT+
# zrMcZzvZ5uyO9WUqIPIeKt7rysgMIyX9H+VWHFldCtyQ22SsyTVQ9FXl7R9P7Wud
# 7y7SPKxhQWl5mvb4BPhLCuc9FeArhzyLmOFdWf8g9KV8LLZAFHFRzQCcXhNwQcRx
# tfq1q4Mdvh/GZ58ze/lRxVIrkhVcrjOxu6Y4SRWaT9nlyUD3Fe/ZLCddheW+rlFh
# IRmA++bttMVFgUwLisIqMGGB0pY3ioXTVIMXe3ZVp94WHlX7JKFZN42B/IbXmNWu
# SIG # End signature block
