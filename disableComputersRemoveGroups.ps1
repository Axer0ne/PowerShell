Import-Module ActiveDirectory

#Create variables for the log file
$logDate = Get-Date -format yyyyMMdd
$logpath = "C:\system\logs"
$logfile = "$logpath\disableComputersRemoveGroups_$logDate.txt"

# Set the target OU's distinguished name
$ouDN = "OU=OU,OU=OU,DC=domain,DC=com" 

# Get all enabled computers in the target OU
$enabledComputers = Get-ADComputer -Filter "Enabled -eq 'True'" -SearchBase $ouDN -Properties *

# Disable each computer in the OU
Add-Content $logfile "##Disabled computers##"
Add-Content $logfile "Name, Description"

foreach ($computer in $enabledComputers) {
    $computerDN = $computer.DistinguishedName
    Set-ADComputer -Identity $computerDN -Enabled $false
    $computername = $computer.name
    $description = $computer.description
	Add-Content $logfile "$computername, $description"
}

# Get MemberOf for all computers in the OU
$computersObsolete = Get-ADComputer -filter * -SearchBase $ouDN -Properties *

# Clear all groups in MemberOf for all computers
foreach ($computer in $computersObsolete){
    $computer.MemberOf | Remove-ADGroupMember -Member $computer -Confirm:$false  
}
Add-Content $logfile "Groups except 'Domain computers' removed for all computer objects in Obsolete OU"

#Send E-Mail
    $smtpServer = "smtp.server.com"
    $emailTo = "group@domain.com"
    $emailFrom = $env:computername + "@domain.com"
    $emailSubject = "Disabled computers & removed groups"
    $mailBody = 
"The attached log is generated on $env:computername

The AD Computer accounts in the logfile have been disabled and the group memberships were removed:

- Workstations located in the following OU: $ouDN
- Computer account is disabled
- Group memberships removed

*** This is an automatically generated email ***
"

Send-MailMessage -To $emailTo -From $emailFrom -Subject $emailSubject -Body $mailBody -Attachments $logfile -SmtpServer $smtpServer
