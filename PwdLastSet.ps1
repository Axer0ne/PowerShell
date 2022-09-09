$UserAccount = 'firstname.lastname'
$LastSet = get-aduser $UserAccount -properties * | Select-Object -Expand passwordlastset

$Today = Get-Date
$YearFromLastSet = $LastSet.AddDays(365)

if($Today -le $YearFromLastSet){
   write-host("Password still valid for " + $UserAccount)
   
   $DaysUntilExp = $YearFromLastSet - $Today
   write-host("Password expires in " + $DaysUntilExp.Days + " days.")

}else {
   write-host("Password expired for " + $UserAccount)
}