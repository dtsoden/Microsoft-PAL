<#   
.SYNOPSIS
Add AAD Application and SPN to Power Platform AAD and configure Power Platform to accept the SPN as tenant admin user.

.DESCRIPTION
This script assists in creating and configuring the ServicePrincipal to be used with
the Power Platform Command Line Interface (CLI) & Build Tools AzureDevOps task library.

Registers an Application object and corresponding ServicePrincipalName (SPN) with the Power Platform AAD instance.
This Application is then added as admin user to the Power Platform tenant itself.
NOTE: This script will prompt *TWICE* with the AAD login dialogs:
    1. time: to login as admin to the AAD instance associated with the Power Platform tenant
    2. time: to login as tenant admin to the Power Platform tenant itself

.INPUTS
None

.OUTPUTS
Object with Power Platform TenantId, ApplicationId and client secret (in clear text);
use this triple to configure the AzureDevOps ServiceConnection. Aditionaly a PAL Association will be performed 
against the MPN_ID provided at runtime

.LINK
https://docs.microsoft.com/en-us/power-apps/developer/data-platform/powerapps-cli
https://marketplace.visualstudio.com/items?itemName=microsoft-IsvExpTools.PowerPlatform-BuildTools

.EXAMPLE
New-PAL-MPN-ID-ServicePrincipal -DryRun -MPN_ID 1234567
.EXAMPLE
New-PAL-MPN-ID-ServicePrincipal -MPN_ID 1234567 
.EXAMPLE
New-PAL-MPN-ID-ServicePrincipal -MPN_ID 1234567 -TenantLocation "Europe"
.EXAMPLE
New-PAL-MPN-ID-ServicePrincipal -MPN_ID 1234567 -AdminUrl "https://admin.services.crm4.dynamics.com"
.EXAMPLE
New-PAL-MPN-ID-ServicePrincipal -MPN_ID 1234567 -SecretExpiration (New-TimeSpan -Days 90)  # default is 365 days

.NOTES   
    Title:    ©2022 Microsoft - Partner Application Link, Power Platform Service Principal
    Credit:   Original script adopted from https://pabuildtools.blob.core.windows.net/spn-docs-4133a3fe/New-PAL-MPN-ID-ServicePrincipal.ps1
    Author:   David Soden
    Profile:  https://davidsoden.com
    Modified: 5/2/2022
#>

[CmdletBinding()]
Param(    
    # gather permission requests but don't create any AppId nor ServicePrincipal
    [switch] $DryRun = $false,
    # other possible Azure environments, see: https://docs.microsoft.com/en-us/powershell/module/azuread/connect-azuread?view=azureadps-2.0#parameters
    [ValidateSet(
        "AzureCloud",
        "AzureChinaCloud",
        "AzureUSGovernment",
        "AzureGermanyCloud"
    )]
    [string] $AzureEnvironment = "AzureCloud",
    [ValidateSet(
        "UnitedStates",
        "Preview(UnitedStates)",
        "Europe",
        "EMEA",
        "Asia",
        "Australia",
        "Japan",
        "SouthAmerica",
        "India",
        "Canada",
        "UnitedKingdom",
        "France"
    )]
    [string] $TenantLocation = "UnitedStates",
    [string] $AdminUrl,
    [TimeSpan] $SecretExpiration = (New-TimeSpan -Days 365),
    [Parameter(Mandatory=$true)]
        [String]$MPN_ID = ""
)

$adminUrls = @{
    "UnitedStates"	            =	"https://admin.services.crm.dynamics.com"
    "Preview(UnitedStates)"	    =	"https://admin.services.crm9.dynamics.com"
    "Europe"		            =	"https://admin.services.crm4.dynamics.com"
    "EMEA"	                    =	"https://admin.services.crm4.dynamics.com"
    "Asia"	                    =	"https://admin.services.crm5.dynamics.com"
    "Australia"	                =	"https://admin.services.crm6.dynamics.com"
    "Japan"		                =	"https://admin.services.crm7.dynamics.com"
    "SouthAmerica"	            =	"https://admin.services.crm2.dynamics.com"
    "India"		                =	"https://admin.services.crm8.dynamics.com"
    "Canada"		            =	"https://admin.services.crm3.dynamics.com"
    "UnitedKingdom"	            =	"https://admin.services.crm11.dynamics.com"
    "France"		            =	"https://admin.services.crm12.dynamics.com"
    }

    function ensureModules {
    $dependencies = @(
        # the more general and modern "Az" a "AzureRM" do not have proper support to manage permissions
        @{ Name = "AzureAD"; Version = [Version]"2.0.2.137"; "InstallWith" = "Install-Module -Name AzureAD -AllowClobber -Scope CurrentUser" },
        @{ Name = "Microsoft.PowerApps.Administration.PowerShell"; Version = [Version]"2.0.131"; "InstallWith" = "Install-Module -Name Microsoft.PowerApps.Administration.PowerShell -AllowClobber -Scope CurrentUser"},
        @{ Name = "Az.ManagementPartner"; Version = [Version]"0.7.2"; "InstallWith" = "Install-Module -Name Az.ManagementPartner -AllowClobber -Scope CurrentUser"}
        )
    $missingDependencies = $false
    $dependencies | ForEach-Object -Process {
        $moduleName = $_.Name
        $deps = (Get-Module -ListAvailable -Name $moduleName `
            | Sort-Object -Descending -Property Version)
        if ($deps -eq $null) {
            Write-Host @"
ERROR: Required module not installed; install from PowerShell prompt with:
>>  $($_.InstallWith) -MinimumVersion $($_.Version)
"@
            $missingDependencies = $true
            return
        }
        $dep = $deps[0]
        if ($dep.Version -lt $_.Version) {
            Write-Host @"
ERROR: Required module installed but does not meet minimal required version:
       found: $($dep.Version), required: >= $($_.Version); to fix, please run:
>>  Update-Module $($_.Name) -Scope CurrentUser -RequiredVersion $($_.Version)
"@
            $missingDependencies = $true
            return
        }
        Import-Module $moduleName -MinimumVersion $_.Version
    }
    if ($missingDependencies) {
        throw "Missing required dependencies!"
    }
}

function connectAAD {
    Write-Host @"

Connecting to AzureAD: Please log in, using your Power Platform / Power Platform tenant ADMIN credentials:

"@
    try {
        Connect-AzureAD -AzureEnvironmentName $AzureEnvironment -ErrorAction Stop | Out-Null
    }
    catch {
        throw "Failed to login: $($_.Exception.Message)"
    }
    return Get-AzureADCurrentSessionInfo
}

function reconnectAAD {
    # for tenantID, see DirectoryID here: https://aad.portal.azure.com/#blade/Microsoft_AAD_IAM/ActiveDirectoryMenuBlade/Overview
    try {
        $session = Get-AzureADCurrentSessionInfo -ErrorAction SilentlyContinue
        if ($session.Environment.Name -ne $AzureEnvironment) {
            Disconnect-AzureAd
            $session = connectAAD
        }
    }
    catch [Microsoft.Open.Azure.AD.CommonLibrary.AadNeedAuthenticationException] {
        $session = connectAAD
    }
    $tenantId = $session.TenantId
    Write-Host @"
Connected to AAD tenant: $($session.TenantDomain) ($($tenantId)) in $($session.Environment.Name)

"@
    return $tenantId
}

function addRequiredAccess {
    param(
        [System.Collections.Generic.List[Microsoft.Open.AzureAD.Model.RequiredResourceAccess]] $requestList,
        [Microsoft.Open.AzureAD.Model.ServicePrincipal[]] $spns,
        [string] $spnDisplayName,
        [string] $permissionName
    )
    Write-Host "  - requiredAccess for $spnDisplayName - $permissionName"
    $selectedSpns = $spns | Where-Object { $_.DisplayName -eq $spnDisplayName }

    # have to build the List<ResourceAccess> item by item since PS doesn't deal well with generic lists (which is the signature for .ResourceAccess)
    $selectedSpns | ForEach-Object -process {
        $spn = $_
        $accessList = New-Object -TypeName 'System.Collections.Generic.List[Microsoft.Open.AzureAD.Model.ResourceAccess]'
        ( $spn.OAuth2Permissions `
        | Where-Object { $_.Value -eq $permissionName } `
        | ForEach-Object -process {
            $acc = New-Object -TypeName 'Microsoft.Open.AzureAD.Model.ResourceAccess'
            $acc.Id = $_.Id
            $acc.Type = "Scope"
            $accessList.Add($acc)
        } )
        Write-Verbose "accessList: $accessList"

        # TODO: filter out the now-obsoleted SPN for CDS user_impersonation: id = 9f7cb6a3-2591-431e-b80d-385fce1f93aa (PowerApps Runtime), see once granted admin consent in SPN permissions
        $req  = New-Object -TypeName 'Microsoft.Open.AzureAD.Model.RequiredResourceAccess'
        $req.ResourceAppId = $spn.AppId
        $req.ResourceAccess = $accessList
        $requestList.Add($req)
    }
}

function calculateSecretKey {
    param (
        [int] $length = 32
    )
    $secret = [System.Byte[]]::new($length)
    $rng = New-Object System.Security.Cryptography.RNGCryptoServiceProvider

    # restrict to printable alpha-numeric characters
    $validCharSet = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890"
    function getRandomChar {
        param (
            [uint32] $min = 0,
            [uint32] $max = $validCharSet.length - 1
        )
        $diff = $max - $min + 1
        [Byte[]] $bytes = 1..4
        $rng.getbytes($bytes)
        $number = [System.BitConverter]::ToUInt32(($bytes), 0)
        $index = [char] ($number % $diff + $min)
        return $validCharSet[$index]
    }
    for ($i = 0; $i -lt $length; $i++) {
        $secret[$i] = getRandomChar
    }
    return $secret
}

if ($PSVersionTable.PSEdition -ne "Desktop") {
    throw "This script must be run on PowerShell Desktop/Windows; the AzureAD module is not supported for PowershellCore yet!"
}
ensureModules
$ErrorActionPreference = "Stop"
$tenantId = reconnectAAD

$allSPN = Get-AzureADServicePrincipal -All $true

$requiredAccess = New-Object -TypeName 'System.Collections.Generic.List[Microsoft.Open.AzureAD.Model.RequiredResourceAccess]'

addRequiredAccess $requiredAccess $allSPN "Microsoft Graph" "User.Read"
addRequiredAccess $requiredAccess $allSPN "PowerApps-Advisor" "Analysis.All"
addRequiredAccess $requiredAccess $allSPN "Common Data Service" "user_impersonation"
CLS
$appBaseName = $MPN_ID
$spnDisplayName = "PAL-$($appBaseName)-SPN"

Write-Verbose "Creating AAD Application: '$spnDisplayName'..."
$appId = "<dryrun-no-app-created>"
$spnId = "<dryrun-no-spn-created>"
if (!$DryRun) {
    # https://docs.microsoft.com/en-us/azure/active-directory/develop/app-objects-and-service-principals
    $app = New-AzureADApplication -DisplayName $spnDisplayName -PublicClient $true -ReplyUrls "urn:ietf:wg:oauth:2.0:oob" -RequiredResourceAccess $requiredAccess
    $appId = $app.AppId
}
CLS
Write-Host "Created AAD Application: '$spnDisplayName' with appID $appId (objectId: $($app.ObjectId)"

$secretText = [System.Text.Encoding]::UTF8.GetString((calculateSecretKey))

Write-Verbose "Creating Service Principal Name (SPN): '$spnDisplayName'..."
$secretExpires = (get-date).Add($SecretExpiration)
if (!$DryRun) {
    # display name of SPN must be same as for the App itself
    # https://docs.microsoft.com/en-us/powershell/module/azuread/new-azureadserviceprincipal?view=azureadps-2.0
    $spn = New-AzureADServicePrincipal -AccountEnabled $true -AppId $appId -AppRoleAssignmentRequired $true -DisplayName $spnDisplayName -Tags {WindowsAzureActiveDirectoryIntegratedApp}
    $spnId = $spn.ObjectId

    $spnKey = New-AzureADServicePrincipalPasswordCredential -ObjectId $spn.ObjectId -StartDate (get-date).AddHours(-1) -EndDate $secretExpires -Value $secretText
    Set-AzureADServicePrincipal -ObjectId $spn.ObjectId -PasswordCredentials @($spnKey)
}
Write-Host "Created SPN '$spnDisplayName' with objectId: $spnId"

Write-Host @"

Connecting to Power Platform CRM managment API and adding appID to Power Platform tenant:
    Please log in, using your Power Platform / Power Platform tenant ADMIN credentials:
"@

if (!$DryRun) {
    if ($PSBoundParameters.ContainsKey("AdminUrl")) {
        $adminApi = $AdminUrl
    } else {
        $adminApi = $adminUrls[$TenantLocation]
    }
    Write-Host "Admin Api is: $adminApi"

    Add-PowerAppsAccount -Endpoint "prod"
    $mgmtApp = New-PowerAppManagementApp -ApplicationId $appId
    Write-Host @"

Added appId $($appId) to D365 tenant ($($tenantId))

"@
}
$result = [PSCustomObject] @{
    TenantId = $tenantId;
    ApplicationId = $appId;
    ClientSecret = $secretText;
    Expiration = $secretExpires;
}
Write-Output $result | Format-List

Write-host "Now Registering " $spnDisplayName " with MPN-ID " $MPN_ID
Write-host "Please Wait... "

if (!$DryRun) {
   
    # Management Partner cmdlets for Azure Resource Manager in Windows PowerShell and PowerShell Core.
    Start-Sleep -Seconds 15

    # Sign in with newly created Service Principal
    $SecureStringPwd = $secretText | ConvertTo-SecureString -AsPlainText -Force
    $pscredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $appId, $SecureStringPwd
    Connect-AzAccount -ServicePrincipal -Credential $pscredential -Tenant $tenantId

    # Assign Partner ID -> example 2442485
    New-AzManagementPartner -PartnerId $MPN_ID
    Disconnect-AzAccount
} else {
    Write-Host "If this were not a dry run a PAL Association would have happened for $spnDisplayName " with MPN-ID " $MPN_ID" -ForegroundColor Black -BackgroundColor Yellow
}

# THIS SCRIPT IS DIGITALLY SIGNED BY DAVID SODEN BELOW 
# DO NOT REMOVE UNLESS YOU RESIGN OR CHANGE YOUR ExecutionPolicy

# SIG # Begin signature block
# MIIVjAYJKoZIhvcNAQcCoIIVfTCCFXkCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUmQEHEa2L/4ULAiigbSn+m3tV
# 7UygghHsMIIFbzCCBFegAwIBAgIQSPyTtGBVlI02p8mKidaUFjANBgkqhkiG9w0B
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
# AQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFMCpM98nSjo5VltoOM9zcjRSoavmMA0G
# CSqGSIb3DQEBAQUABIICAB8BvN0HwS/+PGdk6LSf7q8537l2732sOVvKjwh9KaDT
# m1hMnX10OIki++r1UUWRCg6DpVl0vLbqsYRYyPcordt0NtbfE30qP1LtQmF6mTY1
# OSSj5Set8bH2/JFQIgqD7drBJiLaka6BR0QvUnP6i1H62XiaLH5lwn7oS4n7VMeQ
# w1sZtkg27wxh11IN9Me1/QNhB53iVAj4dK0oMQF3lRG6tloulqdY+6Vxnp6n1Hvz
# SN24cUcHdkH/0VTsqVQ+WYO6miKODnq/ased5xZ7rc69rqviudjjJ78VvhBq5QfZ
# OkbB/gDtVfo9SJyw5MdcAojMTltxL8qz0ckN9u3WW+gy8tx1MQwzSCI5aKBn5sAh
# h8pMYlTHkuAI54tlZU7gAREGlU1djPbsaXVLDfgY7CYmWjvqjpCRfHT4EvOES2qR
# DWpPONcoUg7SGAM3KsaKf30VFZBBWhQ+42QbCuToL58p7nuRbNORB9wTyivatNAj
# OnrfRnwsAkZledziDtXVRSSv9P/f2/bOh7Qe9mopMITunivvySEZOyt8yMnITnM6
# ZHlHsTz7mvOrQfNSPLzW2fc/nYAHM5t9XP9ed1ODjdcsV7BwSKvq2qWQbZiW1Kxu
# VS7wQsxAVnExF/+xWo9R4INcpduyscnXbmg22z3nvF/Ve7nrmvrO1AOZ8j1JW3k8
# SIG # End signature block
