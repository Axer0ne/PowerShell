$inputFilePath = "Path"
$outputFilePath = "Path"
$lines = Get-Content $inputFilePath
$filteredLines = $lines | Where-Object { $_ -match "CO-" }
$sortedLines = $filteredLines | Sort-Object

$sortedLines | Out-File -FilePath $outputFilePath
Write-Host "Filtered and sorted lines have been written to $outputFilePath"
