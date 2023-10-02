##### USER DEACTIVATION #####

# Type in the SAM Account Name
$SAMAccountName=Read-Host -Prompt "Enter the username: "

# Get the user in AD
$user= Get-ADUser -Identity $SAMAccountName

# Hide the user from the address lists
Set-ADUser $user -Replace @{msExchHideFromAddressLists=$true}

# Remove the user's manager
$user | Set-ADUser -clear Manager

# Get the user's groups
$userGroups=Get-ADPrincipalGroupMembership $SAMAccountName | Select-Object Name

# Remove the user from each group
foreach($group in $userGroups){
 
    try{
    
        Remove-ADGroupMember -Identity $group.Name -Members $SAMAccountName 
    }
    catch{
         Write-Host "The group 'Domain Users' cannot be removed because its the user's primary group"
    }
}

# Disable user's account
Disable-ADAccount -Identity $SAMAccountName

# Generate a random 17-character password
$Password = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 17 | ForEach-Object {[char]$_})

# Convert the password to a secure string
$SecurePassword = ConvertTo-SecureString -String $Password -AsPlainText -Force

# Set the new password for the user
Set-AdAccountPassword -Identity $SAMAccountName -NewPassword $SecurePassword -Reset

# Force the user to change their password at the next logon
Set-AdUser -Identity $SAMAccountName -ChangePasswordAtLogon $true

# Display the generated password (optional)
Write-Host "Password for $SAMAccountName has been set to: $Password"

# Move to the "Obsolete Accounts" Organizational Unit
$user | Move-ADObject -TargetPath "OU=Obsolete,DC=domain,DC=com"

##### COMPUTER DEACTIVATION #####

$partialDescription = "$SAMAccountName*"

# Get computer based on SAM Account Name of the user
$computer = Get-ADComputer -Filter {description -Like $partialDescription} -Properties *

# Disable the Computer object
$computerDN = $computer.DistinguishedName
Set-ADComputer -Identity $computerDN -Enabled $false

# Clear all groups in MemberOf for all computers
$computer.MemberOf | Remove-ADGroupMember -Member $computer -Confirm:$false

# Move computer to Obsolete in Workstations OU
$computer | Move-ADObject -TargetPath "OU=Obsolete,OU=Workstations,DC=domain,DC=com"