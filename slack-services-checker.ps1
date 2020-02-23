# todo rewrite to tasks https://stackify.com/what-is-powershell/


# administrator check 
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# variables
$ip_address = (get-netadapter | get-netipaddress | ? addressfamily -eq 'IPv4').ipaddress;

# slack
$SlackChannelUri = "https://hooks.slack.com/services/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"

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
# for testing 
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

$json = '{
    "services" : [
        { 
            "name" : "Service status", 
            "executable" : "C:\\BlocServices\\CMDServices\\CheckServiceStatus\\CheckServiceStatus.exe" 
        },
        { 
            "name" : "campaign company report", 
            "executable" : "C:\\BlocServices\\CMDServices\\Bloc.CampaignCompanyReport\\Bloc.CampaignCompanyReport.exe" 
        },
        { 
            "name" : "campaign team report", 
            "executable" : "C:\\BlocServices\\CMDServices\\Bloc.CampaignTeamReport\\Bloc.CampaignTeamReport.exe" 
        },
        { 
            "name" : "campaign user report", 
            "executable" : "C:\\BlocServices\\CMDServices\\Bloc.CampaignUserReport\\Bloc.CampaignUserReport.exe" 
        },
        { 
            "name" : "invoice fee reminder", 
            "executable" : "C:\\BlocServices\\CMDServices\\FeeInvoiceService\\FeeInvoiceService.exe" 
        },
        { 
            "name" : "elastic search indexer", 
            "executable" : "C:\\BlocServices\\CMDServices\\LuceneDBIndex\\LuceneDBIndexer.exe" 
        },
        { 
            "name" : "orgtree builder", 
            "executable" : "C:\\BlocServices\\CMDServices\\BuildOrgTree\\bloc.buildOrgTree.exe" 
        },
        { 
            "name" : "push booking orders", 
            "executable" : "C:\\BlocServices\\CMDServices\\PushBoookingOrderToHip\\Bloc.PushBookingOrderToHip.exe" 
        },
        { 
            "name" : "booking sms reminder", 
            "executable" : "C:\\BlocServices\\CMDServices\\SendBookingSMSReminderService\\SendBookingSMSReminderService.exe" 
        },
        { 
            "name" : "FotballData sync", 
            "executable" : "C:\\BlocServices\\CMDServices\\Fotball\\FootballSync.exe" 
        },
        { 
            "name" : "NIFLastChangesFromNifByOrgId1",
            "executable" : "C:\\BlocServices\\CMDServices\\nifservices\\NIFSyncFunctionsByOrgId1\\NIFSyncFunctionsByOrgId1.exe" 
        },
        { 
            "name" : "NifSyncmembersByOrgIdFromServiceBus.exe",
            "executable" : "C:\\BlocServices\\CMDServices\\nifservices\\NifSyncmembersByOrgIdFromServiceBus\\NifSyncmembersByOrgIdFromServiceBus.exe" 
        },
        { 
            "name" : "Bloc.SendFormPageNotificationEmail.exe", 
            "executable" : "C:\\BlocServices\\CMDServices\\FormWidgetNotification\\Bloc.SendFormPageNotificationEmail.exe" 
        },
        { 
            "name" : "mportMemberMatchService.exe",
            "executable" : "C:\\BlocServices\\CMDServices\\Bloc.ImportMemberMatchService\\ImportMemberMatchService.exe" 
        },
        { 
            "name" : "PolarPullNotification.exe",
            "executable" : "C:\\BlocServices\\CMDServices\\PolarService\\PolarPullNotification.exe" 
        },
        { 
            "name" : "LetsEncryptService.exe", 
            "executable" : "C:\\BlocServices\\CMDServices\\LetsEncryptService\\LetsEncryptService.exe" 
        },
        { 
            "name" : "Bloc.TrainingService", 
            "executable" : "C:\\BlocServices\\CMDServices\\Bloc.TrainingService\\Bloc.TrainingReport.exe" 
        },
        { 
            "name" : "Bloc.CronService", 
            "executable" : "C:\\BlocServices\\CMDServices\\CronService\\CronService.exe" 
        },
        { 
            "name" : "NIF Result service", 
            "executable" : "C:\\BlocServices\\CMDServices\\NIFServices\\NIFResultService\\NIFResultService.exe" 
        },
        { 
            "name" : "Reply email service", 
            "executable" : "C:\\BlocServices\\CMDServices\\ReplyEmailService\\Bloc.ReplyToEmailService.exe" 
        },
        { 
            "name" : "DBRequest service", 
            "executable" : "C:\\BlocServices\\CMDServices\\DBQueryService\\DBQueryService.exe" 
        }
    ]
}'


$object = $json | ConvertFrom-Json
Write-Host $object.services
$processes_started = ""
$processesCount = $object.services.Count
Write-Host $processesCount
$startedCount = 0
$runningCount = 0
foreach($service in $object.services){

    Write-Host $service
    $ServiceName = $service.name
    $ServiceExecutable = $service.executable

    $processIsRunning = (Get-Process -Name $ServiceName -ErrorAction SilentlyContinue) -eq $null
    
    if($processIsRunning) {
        Write-Host $ServiceName "is not running! We need to start it!"
        $processes_started += $ServiceName + ", "
        $startedCount = $startedCount + 1
        .$ServiceExecutable
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
$body = $service_started_template.Replace("%SERVICE_NAME%", $processes_started).Replace("%PROCESSES_TOTAL%", $processesCount).Replace("%PROCESSES_RUNNING%", $runningCount).Replace("%PROCESSES_STARTED%", $startedCount).Replace("%IP_ADDR%", $ip_address)
Invoke-RestMethod -uri $SlackChannelUri -Method Post -body $body -ContentType 'application/json'

