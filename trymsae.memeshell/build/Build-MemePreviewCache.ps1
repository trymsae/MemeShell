<#
    .SYNOPSIS
        Generates ANSI half-block .ans preview files for all bundled meme templates.
        Run once whenever templates are added or updated, then commit the output. No cap.
    .PARAMETER TemplatesPath
        Source folder of template images. Defaults to ../templates/pictures
    .PARAMETER OutputPath
        Destination folder for .ans files. Defaults to ../templates/previews
#>
param(
    [string]$TemplatesPath = "$PSScriptRoot\..\templates\pictures",
    [string]$OutputPath    = "$PSScriptRoot\..\templates\previews"
)

. "$PSScriptRoot\..\src\ConvertTo-MemePreview.ps1"

if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
}

$templates = Get-ChildItem -Path $TemplatesPath -Include "*.jpg","*.jpeg","*.png","*.bmp" -Recurse
Write-Host "Generating previews for $($templates.Count) templates..." -ForegroundColor Cyan

$success = 0
$failed  = 0

foreach ($template in $templates) {
    $outFile = Join-Path $OutputPath "$($template.BaseName).ans"
    Write-Host "  → $($template.BaseName)" -NoNewline
    $result = ConvertTo-MemePreview -ImagePath $template.FullName -OutputPath $outFile
    if ($result) {
        Write-Host " ✓" -ForegroundColor Green
        $success++
    }
    else {
        Write-Host " ✗ (skipped)" -ForegroundColor Red
        $failed++
    }
}

Write-Host "`nDone — $success succeeded, $failed failed. Commit those .ans files fam." -ForegroundColor Cyan
