# Imports 
. .\_slackhook.ps1
. .\error-handler.ps1

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

# service started template 
$service_started_template = 
@"
    {
        "channel": "#dev",
        "username": "Bloc Alerts",
        "text": ":gear: %SERVICE_NAME% started :white_check_mark:",
        "blocks": [
                    {
                    "type": "section",
                    "text": {
                        "type": "mrkdwn",
                        "text": ":gear: Stopped service found \n _Started:  *%SERVICE_NAME%*_ \n> %PROCESSES_TOTAL% processes discovered \n> %PROCESSES_RUNNING% processes already running \n> %PROCESSES_STARTED% process started"
                    }
                },
            ]
        }
    }
"@


$json = '{
    "services" : [
        {
            "name" : "Bloc.MSMQJobs", 
            "executable" : "C:\\BlocServices\\CMDServices\\RedisMQ\\Bloc.MSMQJobs.exe"
        },
        { 
            "name" : "Bloc.CampaignCompanyReport", 
            "executable" : "C:\\BlocServices\\CMDServices\\Bloc.CampaignCompanyReport\\Bloc.CampaignCompanyReport.exe" 
        },
        { 
            "name" : "Bloc.CampaignTeamReport", 
            "executable" : "C:\\BlocServices\\CMDServices\\Bloc.CampaignTeamReport\\Bloc.CampaignTeamReport.exe" 
        },
        { 
            "name" : "Bloc.CampaignUserReport", 
            "executable" : "C:\\BlocServices\\CMDServices\\Bloc.CampaignUserReport\\Bloc.CampaignUserReport.exe" 
        },
        { 
            "name" : "FeeInvoiceService", 
            "executable" : "C:\\BlocServices\\CMDServices\\FeeInvoiceService\\FeeInvoiceService.exe" 
        },
        { 
            "name" : "LuceneDBIndexer", 
            "executable" : "C:\\BlocServices\\CMDServices\\LuceneDBIndex\\LuceneDBIndexer.exe" 
        },
        { 
            "name" : "Bloc.BuildOrgTree", 
            "executable" : "C:\\BlocServices\\CMDServices\\BuildOrgTree\\bloc.buildOrgTree.exe" 
        },
        { 
            "name" : "Bloc.PushBookingOrderToHip", 
            "executable" : "C:\\BlocServices\\CMDServices\\PushBoookingOrderToHip\\Bloc.PushBookingOrderToHip.exe" 
        },
        { 
            "name" : "SendBookingSMSReminderService", 
            "executable" : "C:\\BlocServices\\CMDServices\\SendBookingSMSReminderService\\SendBookingSMSReminderService.exe" 
        },
        { 
            "name" : "FootBallSync", 
            "executable" : "C:\\BlocServices\\CMDServices\\Fotball\\FootballSync.exe" 
        },
        { 
            "name" : "NIFSyncFunctionsByOrgId1",
            "executable" : "C:\\BlocServices\\CMDServices\\nifservices\\NIFSyncFunctionsByOrgId1\\NIFSyncFunctionsByOrgId1.exe" 
        },
        { 
            "name" : "NIFSyncMembersByOrgIdFromServiceBus",
            "executable" : "C:\\BlocServices\\CMDServices\\nifservices\\NifSyncmembersByOrgIdFromServiceBus\\NifSyncmembersByOrgIdFromServiceBus.exe" 
        },
        { 
            "name" : "Bloc.SendFormPageNotificationEmail", 
            "executable" : "C:\\BlocServices\\CMDServices\\FormWidgetNotification\\Bloc.SendFormPageNotificationEmail.exe" 
        },
        { 
            "name" : "ImportMemberMatchService",
            "executable" : "C:\\BlocServices\\CMDServices\\Bloc.ImportMemberMatchService\\ImportMemberMatchService.exe" 
        },
        { 
            "name" : "PolarPullNotification",
            "executable" : "C:\\BlocServices\\CMDServices\\PolarService\\PolarPullNotification.exe" 
        },
        { 
            "name" : "LetsEncryptService", 
            "executable" : "C:\\BlocServices\\CMDServices\\LetsEncryptService\\LetsEncryptService.exe" 
        },
        { 
            "name" : "Bloc.TrainingReport", 
            "executable" : "C:\\BlocServices\\CMDServices\\Bloc.TrainingService\\Bloc.TrainingReport.exe" 
        },
        { 
            "name" : "CronService", 
            "executable" : "C:\\BlocServices\\CMDServices\\CronService\\CronService.exe" 
        },
        { 
            "name" : "NIFResultService", 
            "executable" : "C:\\BlocServices\\CMDServices\\NIFServices\\NIFResultService\\NIFResultService.exe" 
        },
        { 
            "name" : "Bloc.ReplyToEmailService", 
            "executable" : "C:\\BlocServices\\CMDServices\\ReplyEmailService\\Bloc.ReplyToEmailService.exe" 
        },
        { 
            "name" : "DBQueryService", 
            "executable" : "C:\\BlocServices\\CMDServices\\DBQueryService\\DBQueryService.exe" 
        }
    ]
}'

#for testing 
# $json = '{
#     "services" : [
#         { 
#             "name" : "Calculator", 
#             "executable" : "C:\\Windows\\system32\\calc.exe" 
#         },
#         { 
#             "name" : "notepad", 
#             "executable" : "C:\\Windows\\system32\\notepad.exe" 
#         }
        
#     ]
# }'


$object = $json | ConvertFrom-Json

$processes_started = ""
$processesCount = $object.services.Count
$startedCount = 0
$runningCount = 0

foreach($service in $object.services){

    $ServiceName = $service.name
    $ServiceExecutable = $service.executable

    $processNotRunning = $null -eq (Get-Process -Name $ServiceName -ErrorAction SilentlyContinue)
    
    if($processNotRunning) {
        Write-Host $ServiceName "is not running! We need to start it!"
        $processes_started += $ServiceName + ", "
        $startedCount = $startedCount + 1

        Start-Process $ServiceExecutable # starting the service
        Start-Sleep -Seconds 5
        $didStart = $null -ne (Get-Process -Name $ServiceName -ErrorAction SilentlyContinue)
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
    $body = $service_started_template.Replace("%SERVICE_NAME%", $processes_started).Replace("%PROCESSES_TOTAL%", $processesCount).Replace("%PROCESSES_RUNNING%", $runningCount).Replace("%PROCESSES_STARTED%", $startedCount).Replace("%IP_ADDR%", $ip_address)
    Invoke-RestMethod -uri $SlackChannelUri -Method Post -body $body -ContentType 'application/json'
}

