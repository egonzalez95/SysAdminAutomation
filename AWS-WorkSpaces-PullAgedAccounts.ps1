# Using an authenticated AWS CLI we can pull last user login date on AWS.
# Configure AWSCLI with JSON
# I have added some writelines for verbose means...

# days to compare expiry to, default is 60
$expirydays = 60

### pull all workspaces in json format
Write-Host -NoNewLine "> Pulling JSON"
$workspacesJSON = aws workspaces describe-workspaces
Write-Host " ... Success"

### convert the json to an object, where we can pull individual JSON values
Write-Host -NoNewLine "> Converting JSON to PowerShell Object"
$workspacesOBJ = $workspacesJSON | ConvertFrom-Json
Write-Host " ... Success"

### pull list of workspace ids
Write-Host -NoNewLine "> Pulling all WorkSpace ID objects"
$workspaceids = $workspacesOBJ.Workspaces.WorkspaceId
Write-Host " ... Success"

### pull list of workspace usernames
Write-Host -NoNewLine "> Pulling all WorkSpace UserName objects"
$workspaceusers = $workspacesOBJ.Workspaces.UserName
Write-Host " ... Success"

### pull list of dates date for each WS
Write-Host "> Compiling all dates, this can take some time!"
$workspacedates = @()
Write-Host -NoNewLine "."
foreach ($wsid in $workspacesOBJ.Workspaces.WorkspaceId)
	{
		
		# convert status to JSON
		$wsstatus = aws workspaces describe-workspaces-connection-status --workspace-ids $wsid | ConvertFrom-Json

		Write-Host  -NoNewLine "."		

		# IF null, user never logged on
		if(!($wsstatus.WorkspacesConnectionStatus.LastKnownUserConnectionTimestamp))
		{
			$workspacedates += "* NO LOGIN"
		}

		# ELSE when was their last logon? strip the time to only the date
		else
		{
			$workspacedates += $wsstatus.WorkspacesConnectionStatus.LastKnownUserConnectionTimestamp.substring(0,10)
		}
	}
Write-Host " Success"

### print all the data in order; since we pull data in the same order we do not need to worry about mismatches
Write-Host "> Cleaning up all the data!"
for ($ii = 0; $ii -le ($workspaceids.length - 1); $ii += 1) {
	$workspaceids[$ii], $workspacedates[$ii], $workspaceusers[$ii] -join ' - '
	}

Write-Host "===== Older than 60 days ==============="
# Grab todays date
$today = (Get-Date).ToString('yyyy-MM-dd')

#Compare against our set expiry
for ($ii = 0; $ii -le ($workspacedates.length - 1); $ii += 1) {
    # If they never logged in, don't compute
    if ($workspacedates[$ii] -eq "* NO LOGIN"){
        "N/A", $workspaceusers[$ii] -join ' - '
    }
    # compute
    else {
        $timespan = New-TimeSpan -Start $workspacedates[$ii] -End $today
        if($timespan.Days -ge $expirydays){
            $timespan.Days, $workspaceusers[$ii]  -join ' - '
        }
    }
}


#signal we are done
Write-Host "> Done."

#Emilio Gonzalez - The Commonwealth of Massachusetts
