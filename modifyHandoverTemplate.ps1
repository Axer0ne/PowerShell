$wordApp = New-Object -ComObject Word.Application
$wordApp.Visible = $false

$document = $wordApp.Documents.Open("$Env:USERPROFILE\path\")

$findAndReplace = @{
    "Name Surname" = "" #Employee Name:
    "EmpCd" = "" #Employee Code:
    "Asset T. No." = "" #Asset Transfer No.:
    "XX.XX.XXXX." = "" #Handover Date:
    "SN" = "" #Serial Number
    "ITEM" = "" #Particulars
    "BARCODE" = "" #Asset Code
    "QUANT" = "" #Qty (Quantity)
}

foreach ($key in $findAndReplace.Keys) {
    $find = $key
    $replace = $findAndReplace[$key]

    $findRange = $document.Content
    $findRange.Find.Execute($find)

    while ($findRange.Find.Found) {
        $findRange.Text = $findRange.Text -replace $find, $replace
        $findRange = $document.Content
        $findRange.Find.Execute($find)
    }
}

# Save the modified document with a new name
$newPath = "$Env:USERPROFILE\path\"
$document.SaveAs([ref]$newPath)

# Close the document and quit Word
$document.Close()
$wordApp.Quit()
