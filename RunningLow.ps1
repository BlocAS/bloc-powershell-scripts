###
#
# ---------------------------------------------
# RunningLow v1.1
# ---------------------------------------------
# A small Powershell script to check for low disk space and send e-mail to System Administrators
#
# by Darkseal/Ryadel
# https://www.ryadel.com/
#
# Licensed under GNU - General Public License, v3.0
# https://www.gnu.org/licenses/gpl-3.0.en.html
#
###

# Command-line parameters
param(
  [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$false)]
  [string] $minSize = 20GB,
  [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$false)]
  [string] $hosts = $null,
  [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$false)]
  $volumes = $null,
  [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$false)]
  [string] $email_to ="olemariusloset@gmail.com",
  [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$false)]
  $email_username = "bloc-alerts@outlook.com",
  [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$false)]
  $email_password = "BlocMafiaBlocForAlertEmailAccount",
  [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$false)]
  $email_smtp_host = "smtp.outlook.com",
  [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$false)]
  $email_smtp_port = 587,
  [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$false)]
  $email_smtp_SSL = $true,
  [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$false)]
  $email_from = $email_username
)

$sep = ":";

# if there are no $cur_hosts set, set the local computer as host. 
if (!$hosts) { $hosts = $env:computername; }

foreach ($cur_host in $hosts.split($sep))
{
    # converts IP to hostNames
    if (($cur_host -As [IPAddress]) -As [Bool]) {
        $cur_host = [System.Net.Dns]::GetHostEntry($cur_host).HostName
    }

	Write-Host ("");
	Write-Host ("");
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
	# Write-Host ("");
	# Write-Host ("  Checking drive " + $d + " ...");
	$disk = If ($cur_host -eq $env:computername) { Get-PSDrive $d }
    Else { Invoke-Command -ComputerName $cur_host -ScriptBlock { Get-PSDrive $using:d } }

	if ($disk.Free -lt $minSize) {
		Write-Host "  - [" -noNewLine
        Write-Host "WARNING" -noNewLine -ForegroundColor Red
        Write-Host "] " -noNewLine
        Write-Host ("Drive " + $d + " has less than " + ($minSize/1GB).ToString(".00") + "GB (" + ($disk.Free/1GB).ToString(".00") + "GB)") -NoNewline
         
        if ($email_to) {
            Write-Host(": Sending e-mail...");
		    $message = new-object Net.Mail.MailMessage;
		    $message.From = $email_from;
		    foreach ($to in $email_to.split($sep)) {
			    $message.To.Add($to);
		    }
		    $message.Subject = 	("WARNING: " + $cur_host + " drive " + $d);
		    $message.Subject +=	(" has less than " + ($minSize/1GB).ToString(".00") + "GB free ");
		    $message.Subject +=	("(" + ($disk.Free/1GB).ToString(".00") +" GB)");
		    $message.Body += 	("The " + $env:computername + " drive " + $d + " ");
		    $message.Body += 	"is running low on free space. `r`n`r`n";
		    $message.Body += 	"--------------------------------------------------------------";
		    $message.Body +=	"`r`n";
		    $message.Body += 	("Machine HostName: " + $env:computername + " `r`n");
		    $message.Body += 	"Machine IP Address(es): ";
		    $ipAddresses = Get-NetIPAddress -AddressFamily IPv4;
		    foreach ($ip in $ipAddresses) {
		        if ($ip.IPAddress -like "127.0.0.1") {
			        continue;
			    }
		        $message.Body += ($ip.IPAddress + " ");
		    }
		    $message.Body += 	"`r`n";
		    $message.Body += 	("Used space on drive " + $d + ": " + ($disk.Used/1GB).ToString(".00") + " GB. `r`n");
		    $message.Body += 	("Free space on drive " + $d + ": " + ($disk.Free/1GB).ToString(".00") + " GB. `r`n");
		    $message.Body += 	"--------------------------------------------------------------";
		    $message.Body +=	"`r`n`r`n";
		    $message.Body += 	"This warning will fire when the free space is lower ";
		    $message.Body +=	("than " + ($minSize/1GB).ToString(".00") + "GB `r`n`r`n");


		    $smtp = new-object Net.Mail.SmtpClient($email_smtp_host, $email_smtp_port);
		    $smtp.EnableSSL = $email_smtp_SSL;
		    $smtp.Credentials = New-Object System.Net.NetworkCredential($email_username, $email_password);
		    $smtp.send($message);
			$message.Dispose();
			Write-Host $message.Body;
		    Write-Host "E-Mail sent!" ; 
        }
        Else {
            Write-Host(".");
        }
	}
	Else {
		Write-Host "  - [" -noNewLine
        Write-Host "OK" -noNewLine -ForegroundColor Green
        Write-Host "] " -noNewLine
		Write-Host ("Drive " + $d + " has more than " + ($minSize/1GB).ToString(".00") + " GB free: nothing to do.")
	}
  }
}
