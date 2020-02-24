# Imports 
. .\_slackhook.ps1
. .\_errorHandler.ps1
. .\_slackTemplates.ps1
. .\_processes.ps1
. .\_services.ps1

# administrator check 
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# variables
$ip_address = (get-netadapter | get-netipaddress | ? addressfamily -eq 'IPv4').ipaddress;


# make sure script is run with elevated priveleges
if(!$isAdmin){
    Write-Host "This script requires elevated administrator rights"
    exit
}



$processesObject = $processesJson | ConvertFrom-Json

$processes_started = ""
$processesCount = $processesObject.services.Count
$startedCount = 0
$runningCount = 0

foreach($process in $processesObject.processes){

    $ProcessName = $process.name
    $ProcessExecutable = $process.executable

    $processNotRunning = $null -eq (Get-Process -Name $ProcessName -ErrorAction SilentlyContinue)
    
    if($processNotRunning) {
        Write-Host $ProcessName "is not running! We need to start it!"
        $processes_started += $ProcessName + ", "
        $startedCount = $startedCount + 1

        Start-Process $ProcessExecutable # starting the process
        Start-Sleep -Seconds 5
        $didStart = $null -ne (Get-Process -Name $ProcessName -ErrorAction SilentlyContinue)
        Write-Host 'Started successfully' $didStart
        trap {
            TrapHandler $_
            continue
        }

    } else {
        $runningCount = $runningCount + 1
        Write-Host $ServiceName "is already running, do nothing..."
    }
}

Write-Host "-------------------------------------"
Write-Host "Started" $startedCount
Write-Host "Already running" $runningCount
Write-Host "Processes checked" ($startedCount+$runningCount)
Write-Host "JSON count" $processesCount
Write-Host "-------------------------------------"
if($startedCount -gt 0){
    $body = $processes_started_template.Replace("%SERVICE_NAME%", $processes_started).Replace("%PROCESSES_TOTAL%", $processesCount).Replace("%PROCESSES_RUNNING%", $runningCount).Replace("%PROCESSES_STARTED%", $startedCount).Replace("%IP_ADDR%", $ip_address)
    Invoke-RestMethod -uri $SlackChannelUri -Method Post -body $body -ContentType 'application/json'
}



# Services



foreach ($ServiceName in $servicesArray) {

    if(Get-Service $ServiceName -ErrorAction SilentlyContinue) {

        $arrService = Get-Service -Name $ServiceName 

        # Run this for as long as service status is not equal "Running"
        while ($arrService.Status -ne 'Running')
        {
            # post to slack
            $not_running_body = $service_not_running_template.Replace("%SERVICE_NAME%", $arrService.DisplayName).Replace("%IP_ADDR%", $ip_address)
            Invoke-RestMethod -uri $SlackChannelUri -Method Post -body $not_running_body -ContentType 'application/json'
            
            Start-Service $arrService.Name
            
            Write-Host $arrService.DisplayName 'service starting...'
            
            Start-Sleep -seconds 10
            $arrService.Refresh()
            # Once status is Running, print 
            if ($arrService.Status -eq 'Running')
            {
                Write-Host $arrService 'service is now Running'
                # post to slack
                $running_body = $service_started_template.Replace("%SERVICE_NAME%", $arrService.DisplayName).Replace("%IP_ADDR%", $ip_address)
                Invoke-RestMethod -uri $SlackChannelUri -Method Post -body $running_body -ContentType 'application/json'
            }
            
        }
    }
}