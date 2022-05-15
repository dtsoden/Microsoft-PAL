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
