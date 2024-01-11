function FindUser($username) {
    try {
        # Attempt to find user based on 'first.last@domain.com'
        return Get-ADUser -Filter { UserPrincipalName -eq $username } -Properties UserPrincipalName, DisplayName, Enabled -ErrorAction Stop
    } catch {
        Write-Host "Error finding user: $_" -ForegroundColor Red
        return $null
    }
}

function HideFromAddressList($user) {
    Write-Host "Hiding user from address list." -ForegroundColor Cyan
    try {
        Set-ADUser $user -Replace @{msExchHideFromAddressLists=$true} -ErrorAction Stop
        Write-Host "SUCCESS: Hidden user from address list." -ForegroundColor Green
    } catch {
        Write-Host "Could not hide from the address list: $_" -ForegroundColor Red
    }
}

function RemoveManager($user) {
    Write-Host "Removing manager." -ForegroundColor Cyan
    try {
        $user | Set-ADUser -clear Manager
        Write-Host "SUCCESS: Manager removed." -ForegroundColor Green
    } catch {
        Write-Host "Could not remove the manager: $_" -ForegroundColor Red
    }
}

function RemoveUserFromGroups($user) {
    try {
        $userGroups = Get-ADPrincipalGroupMembership $user | Select-Object Name
        Write-Host "Removing user groups." -ForegroundColor Cyan
        foreach ($group in $userGroups) {
            try {
                Write-Host "Removing $($group.Name)." -ForegroundColor Cyan
                Remove-ADGroupMember -Identity $group.Name -Members $user -Confirm:$false -ErrorAction Stop
                Write-Host "SUCCESS: Removed from $($group.Name)." -ForegroundColor Green
            } catch {
                Write-Host "The group $($group.Name) cannot be removed: $_" -ForegroundColor DarkCyan
            }
        }
    } catch {
        Write-Host "Error removing user from groups: $_" -ForegroundColor Red
    }
}

function DisableUserAccount($user) {
    Write-Host "Disabling user account." -ForegroundColor Cyan
    try {
        Disable-ADAccount -Identity $user -ErrorAction Stop
        Write-Host "SUCCESS: User disabled." -ForegroundColor Green
    } catch {
        Write-Host "User could not be disabled: $_" -ForegroundColor Red
    }
}

function ChangeUserPassword($user) {
    Write-Host "Changing password." -ForegroundColor cyan
    try {
        $lastSetBefore = Get-ADUser $user -Properties passwordlastset | Select-Object -Expand passwordlastset

        $password = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 17 | ForEach-Object {[char]$_})
        $securePassword = ConvertTo-SecureString -String $password -AsPlainText -Force
        Set-AdAccountPassword -Identity $user -NewPassword $securePassword -Reset
        Set-AdUser -Identity $user -ChangePasswordAtLogon $true

        $lastSetAfter = Get-ADUser $user -Properties passwordlastset | Select-Object -Expand passwordlastset

        return @{
            "password" = $password
            "changed" = ($lastSetAfter -ne $lastSetBefore)
        }
    } catch {
        Write-Host "Error changing user password: $_" -ForegroundColor Red
        return @{
            "password" = $null
            "changed" = $false
        }
    }
}

function MoveUserToObsoleteOU($user) {
    Write-Host "Moving user to Obsolete OU." -ForegroundColor Cyan
    try {
        $user | Move-ADObject -TargetPath "OU=Obsolete,DC=domain,DC=com" -ErrorAction Stop
        Write-Host "SUCCESS: User moved to Obsolete OU." -ForegroundColor Green
    } catch {
        Write-Host "Error moving user to Obsolete OU: $_" -ForegroundColor Red
    }
}

function FindComputers($emailComponents) {
    try {
        $upnPrefix = $emailComponents.Split("@")[0]
        $computers = Get-ADComputer -Filter "Description -like '*$upnPrefix*'" -Properties Description, DisplayName, Enabled -ErrorAction Stop
        return $computers
    }
    catch {
        Write-Host "Error finding computer: $_" -ForegroundColor Red
        return $null
    }
}

function DisableComputer ($computer) {
    try {
        Write-Host "Disabling the computer object." -ForegroundColor Cyan
        $computerDN = $computer.DistinguishedName
        Set-ADComputer -Identity $computerDN -Enabled $false
        Write-Host "SUCCESS: Computer disabled." -ForegroundColor Green
    }
    catch {
        Write-Host "Error disabling computer: $_" -ForegroundColor Red
        return $null
    }
    
}

function RemoveComputerGroups($computer) {
    try {
        $computerGroups = Get-ADPrincipalGroupMembership $computer | Select-Object Name
        Write-Host "Removing computer groups." -ForegroundColor Cyan
        foreach ($group in $computerGroups) {
            try {
                Write-Host "Removing $($group.Name)." -ForegroundColor Cyan
                Remove-ADGroupMember -Identity $group.Name -Members $computer -Confirm:$false -ErrorAction Stop
                Write-Host "SUCCESS: Removed from $($group.Name)." -ForegroundColor Green
            } catch {
                Write-Host "The group $($group.Name) cannot be removed: $_" -ForegroundColor DarkCyan
            }
        }
    }
    catch {
        Write-Host "Error removing computer from groups: $_" -ForegroundColor Red
    }
    
}

function MoveComputerToObsolete($computer) {
    Write-Host "Moving computer to Obsolete OU." -ForegroundColor Cyan
    try {
        $computer | Move-ADObject -TargetPath "OU=Obsolete,OU=Workstations,DC=domain,DC=com"
        Write-Host "SUCCESS: Computer moved to Obsolete OU." -ForegroundColor Green
    } catch {
        Write-Host "Error moving computer to Obsolete OU: $_" -ForegroundColor Red
    }
}

#Script main
Write-Host "Enter the username in 'first.last@domain.com' format:" -ForegroundColor Yellow
$username = Read-Host -Prompt "User"
$emailComponents = $username.Split('@')
Import-Module ActiveDirectory

$user = FindUser($username)
$foundComputers = FindComputers($emailComponents)

if ($user) {
    Write-Host "User found:" -ForegroundColor Cyan
    Write-Host "Username: $($user.SAMAccountName)" -ForegroundColor Green
    Write-Host "Display Name: $($user.DisplayName)" -ForegroundColor Green    

    $confirmation = ""
    while ($confirmation -notmatch '^(Yes|No)$') {
        Write-Host "Do you want to proceed with deactivation? (Type 'Yes' to proceed, 'No' to cancel):" -ForegroundColor Yellow
        $confirmation = Read-Host -Prompt "Yes/No"
        if ($confirmation -notmatch '^(Yes|No)$') {
            Write-Host "Invalid input. Please type 'Yes' or 'No'." -ForegroundColor Red
        }
    }

    if ($confirmation -eq 'Yes') {
        Write-Host ""
        HideFromAddressList($user)
        Write-Host ""
        RemoveManager($user)
        Write-Host ""
        RemoveUserFromGroups($user)
        Write-Host ""
        DisableUserAccount($user)
        Write-Host ""
        
        $passwordChangeResult = ChangeUserPassword($user)
        if($passwordChangeResult["changed"]) {
            Write-Host "Password for $($user.Name) has been set to: $($passwordChangeResult["password"]) and must be changed on next logon." -ForegroundColor Green
        } else {
            Write-Host "Password for $($user.Name) could not be changed." -ForegroundColor Red
        }
        
        Write-Host ""
        MoveUserToObsoleteOU($user)
    } else {
        Write-Host "Deactivation process terminated by the admin." -ForegroundColor Red
    }
} else {
    Write-Host "User not found in the specified formats." -ForegroundColor Red
}

Write-Host ""
Write-Host ""

if ($foundComputers -and $user) {
    
    Write-Host "~Computer Deactivation~"
    
    if($foundComputers.Count -gt 1) {
        Write-Host "More than one computer found for the user." -ForegroundColor Yellow
        Write-Host "Computers found:" -ForegroundColor Cyan
        foreach($computer in $foundComputers){
            Write-Host $computer -ForegroundColor Green
        }
    }
    
    foreach($computer in $foundComputers) {
        Write-Host ""
        Write-Host "Display Name: $($computer.SAMAccountName)" -ForegroundColor Green    
        
        $confirmation = ""
        while ($confirmation -notmatch '^(Yes|No)$') {
            Write-Host "Do you want to proceed with deactivation? (Type 'Yes' to proceed, 'No' to cancel):" -ForegroundColor Yellow
            $confirmation = Read-Host -Prompt "Yes/No"
            if ($confirmation -notmatch '^(Yes|No)$') {
                Write-Host "Invalid input. Please type 'Yes' or 'No'." -ForegroundColor Red
            }
        }

        if ($confirmation -eq 'Yes') {
            Write-Host ""
            DisableComputer($computer)
            Write-Host ""
            RemoveComputerGroups($computer)
            Write-Host ""
            MoveComputerToObsolete($computer)

        } else {
            Write-Host "Deactivation process terminated by the admin." -ForegroundColor Red
        }
    }
    
} else {
    Write-Host "Computer not found or the input for the user is invalid." -ForegroundColor Red
    Write-Host "NOTE: If the user was found, they may have an AD Joined computer on the cloud." -ForegroundColor Yellow
}