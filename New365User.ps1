#Paul Gibson
#17 September 2025

#To Create a new user in Microsoft 365

#connect to graph api
connect-mggraph -Scopes "User.ReadWrite.All", "Group.ReadWrite.All", "licenseAssignment.ReadWrite.All" -noWelcome 

#get data from the user
Write-Host "Let's add a new user to your default 365 Tenant!`nPlease enter the following information"
$firstName = Read-host "First Name"
$lastName = Read-host "Last Name"
$password = read-host -prompt "Password" -maskInput
$department = read-host "Department"
$title = read-host "Job Title"
$mobile = read-host "Mobile Phone"

#build other data
$domain = $(get-mgdomain | where {$_.isdefault -eq $true}).ID
$email = "$($firstName)`.$($lastName)`@$($domain)"
$nickname = "$($firstName)`.$($lastName)"
$displayName = "$($firstName) $($lastName)"

$passwrdProfile = @{
    Password = $password
}

#create user without a license
try{
new-mguser -DisplayName $displayName -MailNickName $nickname -UserPrincipalName $email -passwordProfile $passwrdProfile -accountenabled -mobilePhone $mobile -Department $department -JobTitle $title -UsageLocation US
}Catch{
    Write-Host "Error, could not create user"
    exit 1
}

$userID = $(Get-MgUser -Filter "UserPrincipalName eq `'$($email)`'").ID

#add licenses to the user
$skus = get-mgsubscribedsku
$i = 0
write-host "which license(s) would you like to assign?"
foreach ($sku in $skus){
    write-host "$i -- $($sku.SkuPartNumber)"
    $i++
}
$skuChoice = Read-host "Enter the number for the license, for multiple licenses, seperate with a space"
$licenseChoices = $skuChoice -split " "
$licenses = @()
$licenses += $licenseChoices

foreach ($license in $licenses){
    $skuID = $skus[$license].skuID
    $payload = @{SkuID = "$($skuID)"}
    Set-mguserLicense -UserID $userID -addLicenses $payload -RemoveLicenses @()
}

