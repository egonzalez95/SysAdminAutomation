# Using an authenticated AWS CLI we can pull last user login date on AWS.
# aws configure with valid keypair > json

##################################################

# USER MANAGED SETTINGS

# days to compare expiry to, 60 is default
$expirydays = 60

# auto remove workspaces over 60 days (0 = no, 1 = yes)
$expiryremoval = 0

##################################################
##################################################

# pull all workspaces in json format
Write-Host -NoNewLine "> Pulling JSON"
$WSINFO = aws workspaces describe-workspaces | ConvertFrom-Json
Write-Host " ... Success"

# pull list of workspace ids
Write-Host -NoNewLine "> Pulling all WorkSpace ID objects"
$workspaceids = $WSINFO.Workspaces.WorkspaceId
Write-Host " ... Success"

# pull list of workspace usernames
Write-Host -NoNewLine "> Pulling all WorkSpace UserName objects"
$workspaceusers = $WSINFO.Workspaces.UserName
Write-Host " ... Success"

# pull list of dates date for each WS
Write-Host "> Compiling all dates, this can take some time!"
$workspacedates = @()
Write-Host -NoNewLine "."
foreach ($wsid in $WSINFO.Workspaces.WorkspaceId)
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

# print all the data in order.
Write-Host "> Cleaning up all the data!"
for ($ii = 0; $ii -le ($workspaceids.length - 1); $ii += 1) {
	$workspaceids[$ii], $workspacedates[$ii], $workspaceusers[$ii] -join ' - '
	}

##################################################
##################################################

# Display WS over 60 days

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

##################################################
##################################################

#signal we are done
Write-Host "> Done."

#Emilio Gonzalez
