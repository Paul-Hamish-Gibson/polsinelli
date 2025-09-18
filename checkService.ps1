#Paul Gibson
#18 September 2025

#Check for a Service to see if it's running and restart it if it isn't

#Please not, this must be ran with Admin level permissions

$foundService = $null


do{
    $Name = Read-host -Prompt "What Service do you want to check on?"
    try{
        $result = Get-Service -Name "*$Name*"
        if($result.length -gt 1){
            Write-host "There are multiple possible matches.  Please choose which item to check:"
            $i = 0
            foreach ($service in $result){

                write-host "$i -- $($service.displayName)"
                $i++
            }
            $numInput = Read-host -prompt "Enter the number of the service listed above"
            $foundservice = $($result[$numInput])
        }else{
            $foundService = $result
        }
    }catch{
        write-host "service not found, please try again"
    }

}while($null -eq $foundService)

$status = $(get-service -name $foundService.name).Status

Write-host "$($foundService.DisplayName) has a status of $Status"
if ($status -eq "Stopped"){
    $startService = read-host "would you like to start this service? (y/n, default is n)"
    if($($startservice.toLower()) -eq 'y'){
        try{
            start-service -name $foundService.name
        }catch{
            Write-Host "Service could not be started on this machine"
        }
    }else{
        exit 0
    }
    
}else{
    $restart = read-host -Prompt "Would you like to restart the $($foundService.DisplayName)? (y/n, default is n)"
    if ($($restart.toLower()) -eq 'y'){
        restart-service -name $foundService.name -force
    }else{
        exit 0
    }
}

