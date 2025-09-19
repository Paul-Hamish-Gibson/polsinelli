#Paul Gibson
# 19 September 2025
#Check Enabled AD User with Employee Type "C" or "E" and report any that their Username doesn't match their Email (SMPT) address

#Assuming this is being ran on a modern server and the AD Module is already installed


#Create log and report directories and files
$logpath = 'C:\ScriptLogs\'
$reports = 'C:\ScriptReports\'

if (! $(test-path $logPath)){
    new-item -path $logPath -Itemtype Directory
}

if (! $(test-path $reports)){
    new-item -path $reports -Itemtype Directory
}

$date = get-date -format yyMMdd
$log = "$($logPath)getEntraUsersLog$date.txt"
new-item $log -Force
$reportfile = "$($reports)ADUsersReport$date.csv"

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

write-log "Log and Reporting directories verified`nLog File Created`nScript Start"

# As far as I can tell, EmployeeType is not a property in a Local DC, atleast up until Windows Server 2022,
# Either there's an additional file with information on the server, or we need to check Entra to get employeeType
## Assuming Entra and that this a Hybrid Environment to avoid fragmenting data

#Stop execution if running outdated Powershell (as of 2025, with pwsh 7)
if ($psversiontable.psVersion.Major -lt 7){
    write-log "Error line 45:  Please run using Powershell 7 or newer"
    exit 1
}

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

#Assuming one Azure environment for attached to the user's Entra ID
connect-mggraph -scopes "User.Read.All","Group.Read.All" -noWelcome
write-log "Connected to Graph API"
 
#Pull user data
write-log "Pulling Users list from Graph..."
$mgUsers = Get-MgUser -All -Property GivenName,Surname,Mail,ID,EmployeeType,UserPrincipalName | Where { $_.EmployeeType -eq "C" -or $_.EmployeeType -eq "C"}

write-log "Pulling Users list from AD"
$adUsers = Get-ADUser -Filter "Enabled -eq 'True'" -Properties UserPrincipalName,GivenName,Surname


#Combine the two lists into a single object
$users = @()

write-log "uniting users objects and filtering"

foreach ($mgUser in $mgUsers){
    $matchedUser = $adUsers | where {$_.UserPrincipalName -eq $mgUser.UserPrincipalName} -ErrorAction SilentlyContinue
    if($null -eq $matchedUser){
        write-log "no match for $($mguser.userprincipleName)"
        continue
    }
    if ($($mguser.userPrincipalName) -eq $($mguser.Mail)) {
        continue
    }
    $user = [PSCustomObject]@{
        GivenName = $mgUser.GivenName
        Surname = $mgUser.Surname
        Email = $mguser.Mail
        UPN = $matchedUser.userPrincipalName
        ID = $mgUser.Id
        EmployeeType = $mgUser.EmployeeType
    }

    $users += $user

}

#Create Report
write-log "users reconciled`ngenerating report"
$users | export-csv -path $reportfile -Force

$fileTest = Test-Path -path $reportfile
if ($fileTest){
    write-log "$reportfile Created"
    exit 0
}else{
    write-log "file creation error"
    exit 1
}
