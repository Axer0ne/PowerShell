#This script sets the recovery options for a service from default "Take No Action" to "Restart the Service"
#Useful for setting up new services for new system integrations (UniFi, Forsta Visualizations environment etc.)
#The script uses the XblGameSave service as a test/dummy service
function Set-Recovery{
    param
    (
        [string] 
        [Parameter(Mandatory=$true)]
        $ServiceName = "XblGameSave"

    )

    sc.exe failure $ServiceName reset= 0 actions= restart/0 #Restart after 0 ms
}

Set-Recovery -ServiceName "XblGameSave"