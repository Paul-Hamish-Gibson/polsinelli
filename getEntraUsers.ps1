#Get all Entra users in an organization and their Licenses
#Author:  Paul Gibson
#Date: 17 Sept 2025
 
#will not assume this is running from a Windows PC but is running in Powershell 7.x
#
#the Assumption here is that this will be ran ad-hoc and will require Entra ID's modern Auth, however edit the section beginning line 65 to automate this
 
##Boilerplate setup##

#change error action
#$ErrorActionPreference = 'Continue'

#Create a log file, formatted to account for either MacOs, Linux, or Windows
 
if ($isWindows){
    $logPath = 'C:\ScriptLogs\'
}else{
    $logpath = '~/ScriptLogs/'
}
if (! $(test-path $logPath)){
    new-item -path $logPath -Itemtype Directory
}
 
$date = get-date -format yyMMdd
$log = "$($logPath)getEntraUsersLog$date.txt"
new-item $log -Force

#Create a simple logging function
function write-log {
    param (
        [Parameter(Position = 0, Mandatory = $true)]
        [string[]]$logitem
    )
 
    $timestamp = get-date -format "HH:mm:ss"
    $entry = "$timestamp`n`t$logitem`n"
 
    add-content -path $log -Value $entry
}
 
#Stop execution if running outdated Powershell (as of 2025, with pwsh 7)
if ($psversiontable.psVersion.Major -lt 7){
    write-log "Error line 43:  Please run using Powershell 7 or newer"
    exit 1
}
 
#check for Graph PS module, install or update if necessary
write-log "Checking Requirements..."
$mgGraphModule = get-InstalledModule -Name Microsoft.Graph -erroraction silentlyContinue

if ($null -ne $mgGraphModule){
    $mgVersion = get-InstalledModule -Name Microsoft.Graph -MinimumVersion '2.30' -erroraction silentlyContinue
    if($null -eq $mgVersion){
        write-log "Graph Module installed but out of date`nUpdating module..."
        update-module -name Microsoft.Graph -MinimumVersion '2.30' -acceptLicense -force
    }
}else{
    write-log "MS Graph Module not installed, installing now..."
    install-module Microsoft.Graph -acceptLicense -AllowClobber -Force
}
 
#Connect to Graph
 
#Reminder: to automate this, you will need to create/register an app in Azure.
#Assuming one Azure environment for attached to the user's Entra ID
connect-mggraph -scopes "User.Read.All" -noWelcome
write-log "Connected to Graph API"
 
#Pull data from Microsoft
write-log "Pulling Users list..."
$users = Get-MgUser -All -Property DisplayName,GivenName,Surname,Mail,AssignedLicenses,ID
$skus = Get-MgSubscribedSku

#Initialise empty array to store data in
$userData = @()

#Process each user
# Write-log "Checking each user's licenses"
# foreach ($user in $users){
#     $licenseSku = $user.AssignedLicenses.SkuId
#     if ($null -eq $licenseSku){
#         write-log "No license found for $($user.mail)"
#         break
#     }
#     $licenses = @()
#     foreach ($sku in $licenseSku){
#         $skuObj = $skus | where-object {$_.SkuId -like $sku}
#         $skuName = $skuObj.SkuPartNumber
#         $licenses += $skuName
#     }

#     $userData += [PSCustomObject]@{
#         GivenName = $user.givenName
#         Surname = $user.Surname
#         EmailAddress = $user.Mail
#         AssignedLicenses = $skuName
#         userID = $user.Id
#     }


# }

foreach ($user in $users){
    $licenses = $(Get-MgUserLicenseDetail -UserId $user.id).SkuPartNumber

        $userData += [PSCustomObject]@{
        GivenName = $user.givenName
        Surname = $user.Surname
        EmailAddress = $user.Mail
        AssignedLicenses = $licenses
        userID = $user.Id
    }
}

write-log "Data created. Creating Report..."
$userData | export-csv -path "$($logPath)UserLicenseReport$date.csv" -Force

$fileTest = Test-Path -path "$($logPath)UserLicenseReport$date.csv"
if ($fileTest){
    write-log "$($logPath)UserLicenseReport$date.csv created"
    exit 0
}else{
    write-log "file creation error"
    exit 1
}