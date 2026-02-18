# Define paths
$currentDir = Get-Location
$outputPath = "C:\wow-addon-versions\$title"
$addonDestinationPath = Join-Path $outputPath "UtilityHub"

Write-Host "Preparing UtilityHub for distribution..."

# 1. Create the output directory if it doesn't exist
if (-Not (Test-Path $outputPath)) {
    Write-Host "Creating output directory: $outputPath"
    New-Item -ItemType Directory -Force -Path $outputPath | Out-Null
} else {
    Write-Host "Output directory already exists: $outputPath"
}

# 2. Clear previous build if it exists
if (Test-Path $addonDestinationPath) {
    Write-Host "Removing previous build directory: $addonDestinationPath"
    Remove-Item -Path $addonDestinationPath -Recurse -Force | Out-Null
}

Write-Host "Copying addon files to $addonDestinationPath..."
# 3. Get all items from the current directory, excluding the 'out' folder,
# the packaging script, and any potential zip file.
$itemsToCopy = Get-ChildItem -Path $currentDir -Exclude "out", "UtilityHub.zip", "package.ps1"

# Copy each filtered item to the destination
foreach ($item in $itemsToCopy) {
    Copy-Item -Path $item.FullName -Destination $addonDestinationPath -Recurse -Force -ErrorAction Stop
}

# Define items to remove from the copied addon
$itemsToRemove = @(
    # Files
    (Join-Path $addonDestinationPath "GEMINI.md"),
    (Join-Path $addonDestinationPath ".pkgmeta"),
    (Join-Path $addonDestinationPath ".emmyrc.json"),
    
    # Directories
    (Join-Path $addonDestinationPath ".gemini"),
    (Join-Path $addonDestinationPath ".git"),
    (Join-Path $addonDestinationPath ".vscode"),
    (Join-Path $addonDestinationPath ".github")
    (Join-Path $addonDestinationPath "refs")
)

Write-Host "Removing unnecessary files and folders from the build..."
# 4. Remove unnecessary files and folders
foreach ($item in $itemsToRemove) {
    if (Test-Path $item) {
        Write-Host "  Removing: $item"
        Remove-Item -Path $item -Recurse -Force | Out-Null
    }
}

# --- New Zipping Functionality ---
Write-Host "Reading addon metadata from UtilityHub.toc..."
$tocContent = Get-Content (Join-Path $currentDir "UtilityHub.toc")

$title = ($tocContent | Select-String -Pattern '^## Title: (.+)$').Matches[0].Groups[1].Value.Trim()
$version = ($tocContent | Select-String -Pattern '^## Version: (.+)$').Matches[0].Groups[1].Value.Trim()

if (-not $title) {
    Write-Error "Could not find '## Title:' in UtilityHub.toc. Cannot create zip file."
    exit 1
}
if (-not $version) {
    Write-Error "Could not find '## Version:' in UtilityHub.toc. Cannot create zip file."
    exit 1
}

$zipFileName = "$title-$version.zip"
$zipFilePath = Join-Path $outputPath $zipFileName

Write-Host "Creating zip archive: $zipFilePath"
# Compress-Archive requires PowerShell 5.0 or later. Windows 10+ has this.
Compress-Archive -Path $addonDestinationPath -DestinationPath $zipFilePath -Force -ErrorAction Stop

Write-Host "Addon prepared for distribution in '$addonDestinationPath'"
Write-Host "Release archive created: '$zipFilePath'"
Write-Host "Packaging script completed."

Start-Process explorer.exe -ArgumentList "C:\wow-addon-versions"