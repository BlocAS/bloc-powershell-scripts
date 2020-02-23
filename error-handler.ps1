# Webhooks Channel
. .\_slackhook.ps1

$BodyTemplate = 
@"
    {
        "channel": "#dev",
        "username": "Bloc Alerts",
        "text": ":fire: Service returned error",
        "blocks": [
                    {
                    "type": "section",
                    "text": {
                        "type": "mrkdwn",
                        "text": "*:beetle: EXCEPTION*  \n _Exception thrown from a service_ \n> %ERROR%"
                    }
                },
            ]
        }
    }
"@




function TrapHandler($error)
{
    $body = $BodyTemplate.Replace("%ERROR%",$error)

    Write-Host $SlackChannelUri
    Invoke-RestMethod -uri $SlackChannelUri -Method Post -body $body -ContentType 'application/json'

    Write-Host "oops - $error" 
}