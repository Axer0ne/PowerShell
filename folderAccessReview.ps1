Function GetAccessRights {
    param (
        [string]$FolderPath
    )

    try {
        $files = Get-ChildItem -Path $FolderPath -Recurse -File
        foreach ($file in $files) {
            $fileName = $file.FullName
            try {
                $acl = Get-Acl -Path $fileName

                Write-Host ""
                Write-Host "File: $($fileName)" -ForegroundColor Cyan
                foreach ($accessRule in $acl.Access) {
                    Write-Host "  $($accessRule.IdentityReference) - $($accessRule.FileSystemRights)" -ForegroundColor Green
                }
            }
            catch {
                Write-Error "Error retrieving access rights for file: $fileName"
            }
        }
    }
    catch {
        Write-Error "Error accessing folder: $FolderPath"
    }
}

#Change this to your path
$folderPath = "C:\Test\The\Script"

#Main
GetAccessRights -FolderPath $folderPath
