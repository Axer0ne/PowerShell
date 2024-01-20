function CheckPrerequisites {
    try {
        #Modules
        Write-Host "Checking prerequisites:" -ForegroundColor Cyan
        Write-Host "ExchangeOnlineManagement module" -ForegroundColor Magenta
        if (Get-Module -ListAvailable -Name ExchangeOnlineManagement) {
            Write-Host "Module exists." -ForegroundColor Green
        } else {
            $hasModule = $false
            while(!$hasModule) {
                Write-Host "Module does not exist." -ForegroundColor Red
                Write-Host "Installing missing module ExchangeOnlineManagement."
                Install-Module ExchangeOnlineManagement
                if(Get-Module -ListAvailable -Name ExchangeOnlineManagement) {
                    $hasModule = $true
                    Write-Host "SUCCESS: Module installed." -ForegroundColor Green
                } else {
                    $hasModule = $false
                    Write-Host "Error installing module." -ForegroundColor Red
                } 
            }    
        }
        #Connect to Exchange
        Write-Host "Connection to Exchange Online" -ForegroundColor Magenta
        Connect-ExchangeOnline
        $isConnected = Get-ConnectionInformation
        if ($isConnected.State -eq "Connected") {
            Write-Host "SUCCESS: Connected to Exchange Online." -ForegroundColor Green
         } else {
            Write-Host "Could not establish connection to Exchange Online." -ForegroundColor Red
         }
        
        Write-Host ""
        Write-Host "AzureAD module" -ForegroundColor Magenta
        if (Get-Module -ListAvailable -Name AzureAD) {
            Write-Host "Module exists." -ForegroundColor Green
        } else {
            $hasModule = $false
            while(!$hasModule) {
                Write-Host "Module does not exist." -ForegroundColor Red
                Write-Host "Installing missing module AzureAD."
                Install-Module AzureAD
                if(Get-Module -ListAvailable -Name AzureAD) {
                    $hasModule = $true
                    Write-Host "SUCCESS: Module installed." -ForegroundColor Green
                } else {
                    $hasModule = $false
                    Write-Host "Error installing module." -ForegroundColor Red
                } 
            }    
        }
        #Connect to Azure AD
        Write-Host "Connection to Azure AD" -ForegroundColor Magenta
        Connect-AzureAD
        
        if (Get-AzureADCurrentSessionInfo -ErrorAction SilentlyContinue) {
            Write-Host "SUCCESS: Connected to Azure AD." -ForegroundColor Green
         } else {
            Write-Host "Could not establish connection to Azure AD." -ForegroundColor Red
         }

    }
    catch {
        Write-Host "Error checking prerequisites: $_" -ForegroundColor Red
        return $null
    }
}
function FindUser ($userPrincipalName) {
    try {
        $user = Get-User -Identity $userPrincipalName | Select-Object * -ErrorAction Stop
        if($user) {
            Write-Host "SUCCESS: User found." -ForegroundColor Green
        } else {
            Write-Host "Error finding user: $_" -ForegroundColor Red
        }
        return $user
    }
    catch {
        Write-Host "Error finding user: $_" -ForegroundColor Red
        return $null
    } 
}
function SetOutOfOffice ($user) {
    try {
        Write-Host "Setting the Out-of-Office message." -ForegroundColor Magenta

        $message = "Hi, 
        Thank you for your email, " + $user.UserPrincipalName + " is no longer an employee at Forsta.
        
        For technical matters please contact support: support@forsta.com, for any other business please call your local Forsta office or reach out to another Forsta team member for assistance.
        
        Kind regards, 
        Forsta"

        Set-MailboxAutoReplyConfiguration -Identity $user -AutoReplyState Enabled -InternalMessage $message  -ExternalMessage $message -ExternalAudience All

        $status = Get-MailboxAutoReplyConfiguration -Identity $user
        if($status.AutoReplyState -eq "Enabled") {
            Write-Host "SUCCESS: Out-of-Office message set." -ForegroundColor Green 
        } else {
            Write-Host "Error setting the OOO message." -ForegroundColor Red 
        }
    }
    catch {
        Write-Host "Error setting the OOO message: $_" -ForegroundColor Red
        return $null
    }  
}
function ConvertToSharedMailbox ($user) {
    try {
        Write-Host "Converting from regular to shared mailbox." -ForegroundColor Magenta
        Set-Mailbox -Identity $user -Type Shared -WarningAction SilentlyContinue
        Write-Host "SUCCESS: Converted to SharedMailbox." -ForegroundColor Green
    }
    catch {
        Write-Host "Error converting to shared mailbox: $_" -ForegroundColor Red
        return $null
    }
}
function RemoveCloudGroups ($user) {
    Write-Host "Removing user from Azure groups." -ForegroundColor Magenta
    $userID = (Get-AzureADUser -ObjectId $user.UserPrincipalName).ObjectId

    $groups = Get-AzureADUserMembership -ObjectId $userID 
    foreach($group in $groups){ 
        try { 
            Remove-AzureADGroupMember -ObjectId $group.ObjectId -MemberId $userID -ErrorAction Stop 
            Write-Host "$($group.DisplayName) removed." -ForegroundColor Green
        } catch {
            Write-Host "$($group.DisplayName) membership cannot be removed via Azure cmdlets." -ForegroundColor Red
        }
    }
}
function SetEmailForwarding ($user) {
    try {
        Write-Host "Setting email forwarding." -ForegroundColor Magenta
        $confirmation = ""
        while ($confirmation -notmatch '^(Yes|No)$') {
            Write-Host "Do you want to send emails to the manager? (Type 'Yes' to proceed, 'No' to cancel):" -ForegroundColor Yellow
            $confirmation = Read-Host -Prompt "Yes/No"
            if ($confirmation -notmatch '^(Yes|No)$') {
                Write-Host "Invalid input. Please type 'Yes' or 'No'." -ForegroundColor Red
            }
        }

        if ($confirmation -eq 'Yes') {
            Write-Host "Input manager email (name.surname@forsta.com):" -ForegroundColor Yellow
            $forwardingAddress = Read-Host -Prompt "Manager"
            Set-Mailbox -Identity $user -DeliverToMailboxAndForward $true -ForwardingSMTPAddress $forwardingAddress
        } else {
            Write-Host "Process skipped by the admin." -ForegroundColor DarkMagenta 
        }
    }
    catch {
        Write-Host "Could not set email forwarding: $_" -ForegroundColor Red
    } 
}
function HandleUserDevices ($user){
    try {
        $userID = (Get-AzureADUser -ObjectId $user.UserPrincipalName).ObjectId
        $devices = Get-AzureADUserRegisteredDevice -ObjectId $userID
        foreach ($device in $devices) {
            $deviceOS = $device.DeviceOSType
            if ($deviceOS -in "Android", "iOS") {
                Remove-AzureADDevice -ObjectId $device.ObjectId
                Write-Host "Removed device: $($device.DisplayName)" -ForegroundColor Green
            }
        }
    }
    catch {
        Write-Host "Error removing devices: $_" -ForegroundColor Red
    } 
}

#Main
CheckPrerequisites
Write-Host "Finding the user:" -ForegroundColor Cyan
Write-Host "Enter the user UPN (Name.Surname@forsta.com)" -ForegroundColor Magenta
$username = Read-Host -Prompt "User"
$foundUser = FindUser($username)

if($foundUser) { 
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
        SetOutOfOffice($foundUser)
        Write-Host ""
        ConvertToSharedMailbox($foundUser)
        Write-Host ""
        RemoveCloudGroups($foundUser)
        Write-Host ""
        SetEmailForwarding($foundUser)
        Write-Host ""
        HandleUserDevices($foundUser)
    } else {
        Write-Host "Deactivation process terminated by the admin." -ForegroundColor Red
    }
}


