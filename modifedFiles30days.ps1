#Paul Gibson
#18 September 2025

#Get files for a directory modified in the last 30 days
#excludes directorys in the return objects

$currDir = $(pwd).Path
$dirToCheck = $null

Write-host "We'll check for files modified with the past 30 days of today ($(get-date -format "D"))`n`nThe default directory is $($currDir), is this where you would like to check files? (y/n)"

do {
    $currDirBool = $(read-host).ToLower()

    switch($currDirBool){
        "y" {$dirToCheck = $currDir}
        "n" {$dirToCheck = $(read-host -prompt "Ok, please enter the directory path you'd like to check").ToString()}
        default {Write-host "you entered a value other than 'y' or 'n', please try again"; }
    }

    if(! $(test-path -path $dirToCheck)){

        write-host -prompt "$dirToCheck is invalid or doesn't exist, please try again"
        $dirToCheck = $null
        
    }

    Write-host "Ok, we'll find files in $dirToCheck that have been created or modified in the past 30 days!"
}while ($null -eq $dirToCheck)

$recursePrompt = $(read-host -prompt "Would you like to inclue files in all subfolders as well? Default is n (y/n)").toLower()
if ($recursePrompt -eq 'y'){
    get-childitem -path $dirToCheck -recurse -file | where {$_.modified -le $(get-date).addDays(30)}

}else{
    "you chose an option other than 'y', here is the files modified only in this directory"
    get-childitem -path $dirToCheck -file | where {$_.modified -le $(get-date).addDays(30)}
}

