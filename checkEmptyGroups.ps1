Function ConnectModule
{
    try {
        Write-Host "Checking if Microsoft Graph is installed..." -ForegroundColor Cyan
        if (Get-Module -Name "Microsoft.Graph" -ListAvailable) {
            Write-Host "Microsoft.Graph module is installed." -ForegroundColor Green
            Write-Host "Connecting MgGraph Module..." -ForegroundColor Cyan
            Connect-MgGraph -NoWelcome
        } else {
            Write-Host "Microsoft.Graph module is not installed." -ForegroundColor Red
            Write-Host "Installing MgGraph Module..." -ForegroundColor Cyan
            Install-Module Microsoft.Graph
        }
    }
    catch {
        Write-Host "An error occurred while checking for Microsoft.Graph module: $_" -ForegroundColor Red
    }
}

Function CheckEmptyGroups {
    try {
        $allGroups = Get-MgGroup -Select id,displayName
        $emptyGroups = @()

        foreach ($group in $allGroups) {
            $members = Get-MgGroupMember -GroupId $group.id
            if ($members.Count -eq 0) {
                $emptyGroups += $group | Select-Object id, displayName
            }
        }

        $emptyGroups
    }
    catch {
        Write-Host "An error occurred while checking for groups in AD: $_" -ForegroundColor Red
    }
}

#main
ConnectModule
CheckEmptyGroups

