# Define file paths
$fullListPath = "C:\temp\everything.txt"
$partialListPath = "C:\temp\partiallist.txt"
$outputPath = "C:\temp\difference.txt"

# Read the content of file2 into an array for comparison
$partialContent = Get-Content -Path $partialListPath

# Initialize an array to store lines that are not found in file2
$linesNotFound = @()

# Read and process each line from file1
Get-Content -Path $fullListPath | ForEach-Object {
    $line = $_.Trim()
    
    # Check if the line is not in file2
    if ($line -notin $partialContent) {
        $linesNotFound += $line
    }
}

# Write the lines not found in file2 to the output file
$linesNotFound | Out-File -FilePath $outputPath

Write-Host "Task completed. Output is saved in 'output.txt'."
