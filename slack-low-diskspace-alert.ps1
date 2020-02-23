# Command-line parameters 
# NB! Must be first
param(
  [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$false)]
  [string] $minSize = 20GB,
  [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$false)]
  [string] $hosts = $null,
  [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$false)]
  $volumes = $null
)

# Imports
. .\_slackhook.ps1

$sep = ":";

# if there are no $cur_hosts set, set the local computer as host. 
if (!$hosts) { $hosts = $env:computername; }

foreach ($cur_host in $hosts.split($sep))
{
    # converts IP to hostNames
    if (($cur_host -As [IPAddress]) -As [Bool]) {
        $cur_host = [System.Net.Dns]::GetHostEntry($cur_host).HostName
    }

	Write-Host ("----------------------------------------------");
	Write-Host ($cur_host);
	Write-Host ("----------------------------------------------");
    $drives_to_check = @();

    if ($null -eq $volumes) {
   	    $volArr = 
          If ($cur_host -eq $env:computername) { Get-WMIObject win32_volume }
          Else { Invoke-Command -ComputerName $cur_host -ScriptBlock { Get-WMIObject win32_volume } }

	    $drives_to_check = @();
        foreach ($vol in $volArr | Sort-Object -Property DriveLetter) {
	        if ($vol.DriveType -eq 3 -And $null -ne $vol.DriveLetter ) {
  		        $drives_to_check += $vol.DriveLetter[0];
		    }
	    }
    }
    Else { $drives_to_check = $volumes.split($sep) }

  foreach ($d in $drives_to_check) {
	$disk = If ($cur_host -eq $env:computername) { Get-PSDrive $d }
    Else { 
        Invoke-Command -ComputerName $cur_host -ScriptBlock { 
            Get-PSDrive $using:d 
        } 
    }

	if ($disk.Free -lt $minSize) {
		Write-Host "  - [" -noNewLine
        Write-Host "WARNING" -noNewLine -ForegroundColor Red
        Write-Host "] " -noNewLine
        Write-Host ("Drive " + $d + " has less than " + ($minSize/1GB).ToString(".00") + "GB (" + ($disk.Free/1GB).ToString(".00") + "GB)") -NoNewline
        $BodyTemplate = 
@"
    {
        "channel": "#dev",
        "username": "Bloc Alerts",
        "text": ":fire: FULL DISK AT %IP_ADDR%",
        "blocks": [
                    {
                    "type": "section",
                    "text": {
                        "type": "mrkdwn",
                        "text": "*:sos:  FULL DISK AT %IP_ADDR% :sos:* \n _Available disk space below %MIN_SIZE%_ \n> Disk letter: ``%DRIVE%:`` \n> Used space: ``%USED_SPACE%``. \n> Free space: ``%FREE_SPACE%``"
                    }
                },
            ]
        }
    }
"@

        $ip_address = (get-netadapter | get-netipaddress | ? addressfamily -eq 'IPv4').ipaddress;
        $body = $BodyTemplate.Replace("%DRIVE%", $d).Replace("%IP_ADDR%", $ip_address).Replace("%HOST%",  $cur_host).Replace("%USED_SPACE%", ($disk.Used/1GB).ToString(".00") + "GB").Replace("%FREE_SPACE%", ($disk.Free/1GB).ToString(".00") + "GB").Replace("%MIN_SIZE%", ($minSize/1GB).ToString(".00") + "GB")
        

        Invoke-RestMethod -uri $SlackChannelUri -Method Post -body $body -ContentType 'application/json'



	}
	Else {
		Write-Host "  - [" -noNewLine
        Write-Host "OK" -noNewLine -ForegroundColor Green
        Write-Host "] " -noNewLine
		Write-Host ("Drive " + $d + " has more than " + ($minSize/1GB).ToString(".00") + " GB free: nothing to do.")
	}
  }
}



