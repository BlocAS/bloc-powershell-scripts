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

$service_started_template = 
@"
    {
        "channel": "#dev",
        "username": "Bloc Alerts",
        "text": ":gear: %SERVICE_NAME% successfully started :white_check_mark:",
        "blocks": [{
                    "type": "section",
                    "text": {
                        "type": "mrkdwn",
                        "text": ":gear: Service *%SERVICE_NAME%* sucessfully started :white_check_mark:"
                    }
            }]
        }
    }
"@

$processes_started_template = 
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

