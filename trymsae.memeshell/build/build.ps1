## Module Configurational Data
Write-Output "Setting module configuration"
$moduleName = "trymsae.memeshell"
$modulePath = "$($PSScriptRoot)\.."
$psd1Path = "$($modulePath)\release\$($moduleName).psd1"
$manifestPath = "$($PSScriptRoot)\..\..\release-please-manifest.json"

## Read version from release-please-manifest.json
Write-Output "Reading version from release-please manifest: $manifestPath"
if (Test-Path $manifestPath) {
    try {
        $manifest = Get-Content -Path $manifestPath -Raw | ConvertFrom-Json
        $moduleVersion = $manifest.$moduleName
        Write-Output "Found version in manifest: $moduleVersion"
    }
    catch {
        Write-Warning "Failed to read version from manifest, using default: $_"
        $moduleVersion = "0.1.0"
    }
}
else {
    Write-Warning "Release-please manifest not found, using default version"
    $moduleVersion = "0.1.0"
}

## Gather source-files and cmdlet data
Write-Output "Getting files from: $modulePath"
$files = Get-ChildItem -Path "$($modulePath)\src\" -Filter "*.ps1" -ErrorAction SilentlyContinue

if ($files) {
    $functiondata = Foreach ($file in $files) {
        $content = Get-Content -Path $file.FullName
        $content | where { $_ -match "^function\s{1}" }
    }
    $aliasData = Foreach ($file in $files) {
        $content = Get-Content -Path $file.FullName
        $content | where { $_ -match "\[Alias\(" -and $_ -notmatch "^#|#\[Alias\(" }
    }
    $moduleData = Foreach ($file in $files) {
        Get-Content -Path $file.FullName
    }
}
else {
    Write-Output "No PowerShell files found in src directory"
    $functiondata = @()
    $aliasData = @()
    $moduleData = @()
}

# Process cmdlet data
$functoexport = if ($functiondata) {
    (($functiondata -replace "function\s+") -replace "(\s+)?{(\s+)?" | Sort-Object)
}
else {
    @()
}
$aliastoexport = if ($aliasData) {
    (((($aliasData -replace "(\s+)?\[Alias\([('|`")]") -replace "('|`")" ) -replace "\)]" ) -split ",") | Where-Object { $_ -ne "" }
}
else {
    @()
}

## Define module manifest parameters
$moduleGuid = "c861dd56-5800-46a7-a296-07a46989e530"
$moduleAuthor = "trymsae"
$moduleCompany = "Knekt & Brekt AS"
$moduleDescription = "MemeShell PowerShell Module"
$modulePowerShellVersion = "7.5"
$moduleTags = @("Meme", "Shell")
$moduleProjectUri = "https://github.com/trymsae/MemeShell"
$moduleLicenseUri = "https://github.com/trymsae/MemeShell/blob/main/LICENSE"

## Create Module Manifest from scratch
Write-Output "Creating module manifest: $psd1Path"

# Prepare module manifest parameters
$moduleManifestParams = @{
    Path = $psd1Path
    RootModule = "$($moduleName).psm1"
    ModuleVersion = $moduleVersion
    GUID = $moduleGuid
    Author = $moduleAuthor
    companyName = $moduleCompany
    Description = $moduleDescription
    PowerShellVersion = $modulePowerShellVersion
    FunctionsToExport = $functoexport
    CmdletsToExport = @()
    VariablesToExport = '*'
    AliasesToExport = $aliastoexport
}

# Add optional parameters if they exist
if ($moduleTags -and $moduleTags.Count -gt 0) {
    $moduleManifestParams.Tags = $moduleTags
}
if (-not [string]::IsNullOrWhiteSpace($moduleProjectUri)) {
    $moduleManifestParams.ProjectUri = $moduleProjectUri
}
if (-not [string]::IsNullOrWhiteSpace($moduleLicenseUri)) {
    $moduleManifestParams.LicenseUri = $moduleLicenseUri
}

# Ensure release directory exists
$releaseDir = "$($modulePath)\release"
if (-not (Test-Path $releaseDir)) {
    New-Item -ItemType Directory -Path $releaseDir -Force | Out-Null
}

# Create the module manifest
New-ModuleManifest @moduleManifestParams

## Copy templates folder to release directory if it exists
$templatesSource = "$($modulePath)\templates"
$templatesDestination = "$($releaseDir)\templates"
if (Test-Path $templatesSource) {
    Write-Output "Copying templates folder to release directory"
    if (Test-Path $templatesDestination) {
        Remove-Item -Path $templatesDestination -Recurse -Force
    }
    Copy-Item -Path $templatesSource -Destination $templatesDestination -Recurse -Force
    Write-Output "Templates folder copied successfully"
}
else {
    Write-Output "No templates folder found at: $templatesSource"
}

Write-Output "Created module manifest with:"
Write-Output "  - Version: $moduleVersion (from release-please manifest)"
Write-Output "  - Author: $moduleAuthor"
Write-Output "  - Company: $moduleCompany"
Write-Output "  - Functions to export: $($functoexport.Count)"
Write-Output "  - Aliases to export: $($aliastoexport.Count)"

## Export the module
Write-Output "Exporting psm1 file to: $($modulePath)\release\$($moduleName).psm1"
if ($moduleData) {
    # Add random import message loader at the beginning
    $importMessage = @'
# MemeShell Module Load Message
$messageFile = Join-Path $PSScriptRoot "templates\texts\load-messages.b64"
if (Test-Path $messageFile) {
    try {
        $base64Content = Get-Content $messageFile -Raw
        $bytes = [Convert]::FromBase64String($base64Content.Trim())
        $decodedText = [System.Text.Encoding]::UTF8.GetString($bytes)
        $messages = $decodedText -split "`r?`n" | Where-Object { $_.Trim() -ne "" }
        $randomMessage = $messages | Get-Random
        Write-Host "█▀▄▀█ █▀▀ █▀▄▀█ █▀▀ █▀ █░█ █▀▀ █░░ █░░    █░░ █▀█ ▄▀█ █▀▄ █▀▀ █▀▄" -ForegroundColor Magenta
        Write-Host "█░▀░█ ██▄ █░▀░█ ██▄ ▄█ █▀█ ██▄ █▄▄ █▄▄    █▄▄ █▄█ █▀█ █▄▀ ██▄ █▄▀" -ForegroundColor Magenta
        Write-host "$($randomMessage)"
    }
    catch {
        Write-host "Catch these hands"
    }
}

'@

    # Auto-activation code at the END (after functions are loaded, duh)
    $autoActivation = @'

# Auto-activate meme prompt on module load (no escape lmao)
Enable-MemePrompt

'@

    # Combine import message with module data and auto-activation at the end
    $fullModuleContent = $importMessage + ($moduleData -join "`n") + $autoActivation

    Set-Content -Value $fullModuleContent -Path "$($modulePath)\release\$($moduleName).psm1" -Encoding UTF8
    Write-Output "Module build completed successfully!"
}
else {
    Write-Output "Warning: No module content found to export"
    Set-Content -Value "# No functions found in src directory" -Path "$($modulePath)\release\$($moduleName).psm1" -Encoding UTF8
}
