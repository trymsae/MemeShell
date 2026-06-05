function Get-MemeTemplatePaths {
    <#
        .SYNOPSIS
            Returns all available meme template FileInfo objects
        .DESCRIPTION
            Merges templates from the installed module folder and the user-local
            ~/.memeshell/templates/pictures/ folder. Module templates win on
            BaseName conflict. Silently skips folders that don't exist.
        .PARAMETER modulePath
            Path to the module root (defaults to the installed module's base directory).
        .PARAMETER userTemplatePath
            Path to the user-local templates folder (defaults to ~/.memeshell/templates/pictures).
        .EXAMPLE
            PS > Get-MemeTemplatePaths
            Returns all available templates from both locations
    #>
    [CmdletBinding()]
    param (
        [string]$modulePath = ((Get-Module -Name 'trymsae.memeshell' -ErrorAction SilentlyContinue).ModuleBase),
        [string]$userTemplatePath = (Join-Path $env:USERPROFILE ".memeshell\templates\pictures")
    )

    $results = [System.Collections.Generic.List[System.IO.FileInfo]]::new()

    # Bundled module templates (these are the OG ones, they win all conflicts fr fr)
    if ($modulePath) {
        $bundledPath = Join-Path $modulePath "templates\pictures"
        if (Test-Path $bundledPath) {
            Get-ChildItem -Path $bundledPath -Recurse -ErrorAction SilentlyContinue |
                Where-Object { $_.Extension -in @('.jpg', '.jpeg', '.png', '.bmp') } |
                ForEach-Object { $results.Add($_) }
        }
    }

    # Build a hashtable of module BaseName → true for O(1) dedup lookups, no cap
    $moduleBaseNames = @{}
    $results | ForEach-Object { $moduleBaseNames[$_.BaseName] = $true }

    # User-local templates (deduplicate by BaseName — module wins, no cap)
    if ($userTemplatePath -and (Test-Path $userTemplatePath)) {
        Get-ChildItem -Path $userTemplatePath -Recurse -ErrorAction SilentlyContinue |
            Where-Object { $_.Extension -in @('.jpg', '.jpeg', '.png', '.bmp') } |
            ForEach-Object {
                $userFile = $_
                if (-not $moduleBaseNames.ContainsKey($userFile.BaseName)) {
                    $results.Add($userFile)
                }
            }
    }

    return $results.ToArray()
}
