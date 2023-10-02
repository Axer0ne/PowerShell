# Define the path to your input text file
$inputFilePath = "Path"

# Define the path to your output text file
$outputFilePath = "Path"

# Read the content of the input file
$lines = Get-Content $inputFilePath

# Filter lines that contain "CO-"
$filteredLines = $lines | Where-Object { $_ -match "SOMEFILTER" }

# Sort the filtered lines by name
$sortedLines = $filteredLines | Sort-Object

# Write the sorted lines to the output file
$sortedLines | Out-File -FilePath $outputFilePath

Write-Host "Filtered and sorted lines have been written to $outputFilePath"
