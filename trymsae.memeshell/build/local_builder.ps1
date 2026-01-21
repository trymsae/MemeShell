## Local Module Builder for Testing
## This script builds the module locally so you can test it

# Get paths relative to script location
$buildScriptPath = Join-Path $PSScriptRoot "build.ps1"
$modulePath = Split-Path -Parent $PSScriptRoot
$tempReleasePath = Join-Path $modulePath "release"
$finalReleasePath = Join-Path $modulePath "release\trymsae.memeshell"

# Run the build script
& $buildScriptPath

# Reorganize: move contents into trymsae.memeshell subfolder
if (Test-Path $tempReleasePath) {
    # Create temp directory for reorganization
    $tempDir = Join-Path $modulePath "temp-local-build"
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

    # Move current release contents to temp
    Move-Item -Path "$tempReleasePath\*" -Destination $tempDir -Force

    # Create the module subfolder in release
    New-Item -ItemType Directory -Path $finalReleasePath -Force | Out-Null

    # Move everything from temp to the module subfolder
    Move-Item -Path "$tempDir\*" -Destination $finalReleasePath -Force

    # Clean up temp directory
    Remove-Item -Path $tempDir -Force
}

Write-Host "`nModule built at: $finalReleasePath" -ForegroundColor Green
