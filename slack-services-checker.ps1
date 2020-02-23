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

# not running template
$service_not_running_template = 
@"
    {
        "channel": "#dev",
        "username": "Bloc Alerts",
        "text": ":gear: %SERVICE_NAME% not running, starting...",
        "blocks": [
                    {
                    "type": "section",
                    "text": {
                        "type": "mrkdwn",
                        "text": ":gear: Service *%SERVICE_NAME%* not running, please wait while starting :hourglass_flowing_sand: \n> Server: ``%IP_ADDR%``"
                    }
                },
            ]
        }
    }
"@

# service started template 
$service_started_template = 
@"
    {
        "channel": "#dev",
        "username": "Bloc Alerts",
        "text": ":gear: %SERVICE_NAME% successfully started :white_check_mark:",
        "blocks": [
                    {
                    "type": "section",
                    "text": {
                        "type": "mrkdwn",
                        "text": ":gear: Service *%SERVICE_NAME%* sucessfully started :white_check_mark:"
                    }
                },
            ]
        }
    }
"@

[Array] $Services = "WSearch", "Audiosrv"

Write-Host $Services

foreach ($ServiceName in $Services) {
    Write-Host $ServiceName
    $arrService = Get-Service -Name $ServiceName

    # Run this for as long as service status is not equal "Running"
    while ($arrService.Status -ne 'Running')
    {
        Write-Host $arrService.DisplayName
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

# Stop-Service "WSearch"
Stop-Service "Audiosrv"








