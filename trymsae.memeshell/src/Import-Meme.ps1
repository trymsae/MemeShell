function Import-Meme {
    <#
        .SYNOPSIS
            Imports a custom meme template into MemeShell
        .DESCRIPTION
            Copies an image into MemeShell's templates folder, resizing it proportionally
            if it exceeds maxSize, and normalizing the filename to kebab-case.
            By default imports to the user-local folder (~/.memeshell/templates/pictures/).
            Use -toSource to import directly into the repo's source templates (for contributors).
            Accepts a local file path or an HTTP/HTTPS URL — auto-detected from -path.
        .PARAMETER path
            Path to the source image file (jpg, jpeg, png, bmp) or an HTTP/HTTPS URL to an image.
        .PARAMETER name
            Override the output filename. Will be kebab-cased automatically. Omit to use source filename.
        .PARAMETER maxSize
            Maximum dimension (width or height) in pixels. Default 800. Only resizes down, never up.
        .PARAMETER toSource
            Import to the repo's source templates folder instead of the user-local folder.
            Only works when running the module from the development repo.
        .EXAMPLE
            PS > Import-Meme -path "C:\memes\Funny Cat.jpg"
            Imports as funny-cat.png to ~/.memeshell/templates/pictures/
        .EXAMPLE
            PS > Import-Meme -path "C:\memes\drake2.png" -name "drake-v2" -toSource
            Imports as drake-v2.png to the repo source templates (for the next release)
        .EXAMPLE
            PS > Import-Meme -path "https://example.com/distracted-boyfriend.jpg"
            Downloads and imports as distracted-boyfriend.png to ~/.memeshell/templates/pictures/
        .EXAMPLE
            PS > Import-Meme -path "https://cdn.example.com/img?id=42" -name "big-brain"
            Downloads from URL with a meaningless path segment; uses -name override.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory = $true)]
        [string]$path,

        [Parameter(Position = 1, Mandatory = $false)]
        [string]$name,

        [Parameter(Mandatory = $false)]
        [ValidateRange(100, 4000)]
        [int]$maxSize = 800,

        [Parameter(Mandatory = $false)]
        [switch]$toSource
    )
    begin {
        Add-Type -AssemblyName System.Drawing
        $supportedExtensions = @('.jpg', '.jpeg', '.png', '.bmp')
    }
    process {
        $bytes    = $null
        $baseName = $null
        $isUrl    = $path -match '^https?://'

        if ($isUrl) {
            $uri     = [System.Uri]$path
            $segment = [System.Uri]::UnescapeDataString($uri.Segments[-1]).TrimEnd('/')
            $segExt  = [System.IO.Path]::GetExtension($segment).ToLower()
            $segBase = [System.IO.Path]::GetFileNameWithoutExtension($segment)

            if ([string]::IsNullOrWhiteSpace($name)) {
                $preKebab    = $segBase.ToLower() -replace '[\s_]+', '-' -replace '[^a-z0-9\-]', '' -replace '-+', '-'
                $preKebab    = $preKebab.Trim('-')
                $blocklist   = @('img','image','images','photo','photos','download','file','meme','get','view','thumb','thumbnail','pic','pics')
                $hasImageExt = $segExt -in @('.jpg','.jpeg','.png','.bmp','.gif','.webp')
                if (($preKebab -in $blocklist -or $preKebab.Length -lt 3) -and -not $hasImageExt) {
                    Write-Error "Can't derive a usable filename from URL '$path' — add -name to sort it out fr"
                    return
                }
                $baseName = $segBase
            }
            else {
                $baseName = $name
            }

            $response    = Invoke-WebRequest -Uri $path -UseBasicParsing
            $contentType = ($response.Headers['Content-Type'] -split ';')[0].Trim()
            if ($contentType -notin @('image/jpeg','image/png','image/bmp','image/gif','image/webp')) {
                Write-Error "URL did not return an image (got '$contentType') — link's cooked fr"
                return
            }
            $bytes = $response.Content
        }
        else {
            # Validate source file exists
            if (-not (Test-Path $path)) {
                Write-Error "File not found: $path (you sure that's real cuh?)"
                return
            }

            $sourceFile = Get-Item $path

            # Validate format
            if ($sourceFile.Extension.ToLower() -notin $supportedExtensions) {
                Write-Error "Unsupported format: '$($sourceFile.Extension)'. Valid formats: jpg, jpeg, png, bmp (no bitch format)"
                return
            }

            $baseName = if (-not [string]::IsNullOrWhiteSpace($name)) { $name } else { $sourceFile.BaseName }
            $bytes    = [System.IO.File]::ReadAllBytes($sourceFile.FullName)
        }

        # Derive kebab-case output filename
        $kebabName  = $baseName.ToLower() -replace '[\s_]+', '-' -replace '[^a-z0-9\-]', '' -replace '-+', '-'
        $kebabName  = $kebabName.Trim('-')
        $outputName = "$kebabName.png"

        if ([string]::IsNullOrWhiteSpace($kebabName)) {
            Write-Error "Could not derive a valid filename from '$baseName' (skill issue — use -name to specify one fr)"
            return
        }

        # Determine destination directory
        if ($toSource) {
            $destDir = Join-Path (Split-Path $PSScriptRoot -Parent) "templates\pictures"
            if (-not (Test-Path $destDir)) {
                Write-Error "Source templates folder not found at: $destDir`nThe -toSource switch only works when running from the development repo, not from an installed PSGallery version (no cap)"
                return
            }
        }
        else {
            $destDir = Join-Path $env:USERPROFILE ".memeshell\templates\pictures"
            if (-not (Test-Path $destDir)) {
                New-Item -ItemType Directory -Path $destDir -Force | Out-Null
                Write-Host "Created user-local templates folder: $destDir" -ForegroundColor Cyan
            }
        }

        $destPath = Join-Path $destDir $outputName

        # Check for filename collision — prompt for a new name rather than hard-erroring
        while (Test-Path $destPath) {
            $newName = Read-Host "Template '$outputName' already exists — what do you want to call it? (empty to cancel)"
            if ([string]::IsNullOrWhiteSpace($newName)) {
                Write-Error "Import cancelled — '$outputName' already exists (ratio + L)"
                return
            }
            $kebabName  = $newName.ToLower() -replace '[\s_]+', '-' -replace '[^a-z0-9\-]', '' -replace '-+', '-'
            $kebabName  = $kebabName.Trim('-')
            if ([string]::IsNullOrWhiteSpace($kebabName)) {
                Write-Error "Could not derive a valid filename from '$newName' (skill issue fr)"
                return
            }
            $outputName = "$kebabName.png"
            $destPath   = Join-Path $destDir $outputName
        }

        # Load, optionally resize, save as PNG
        $graphics = $null
        $bitmap   = $null
        $img      = $null
        $ms       = $null
        try {
            $ms  = New-Object System.IO.MemoryStream(,$bytes)
            $img = [System.Drawing.Image]::FromStream($ms)

            $finalWidth  = $img.Width
            $finalHeight = $img.Height

            if ($img.Width -gt $maxSize -or $img.Height -gt $maxSize) {
                $ratio       = [Math]::Min($maxSize / $img.Width, $maxSize / $img.Height)
                $finalWidth  = [int]($img.Width  * $ratio)
                $finalHeight = [int]($img.Height * $ratio)

                $bitmap   = New-Object System.Drawing.Bitmap($finalWidth, $finalHeight)
                $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
                $graphics.InterpolationMode    = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
                $graphics.SmoothingMode        = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
                $graphics.CompositingQuality   = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
                $graphics.DrawImage($img, 0, 0, $finalWidth, $finalHeight)
            }
            else {
                $bitmap = New-Object System.Drawing.Bitmap($img)
            }

            $bitmap.Save($destPath, [System.Drawing.Imaging.ImageFormat]::Png)

            $dest = if ($toSource) { "source templates (next release included fr)" } else { "user-local templates" }
            Write-Host "Meme imported " -NoNewline
            Write-Host "no cap" -ForegroundColor Green -NoNewline
            Write-Host " 🔥 → " -NoNewline
            Write-Host $outputName -ForegroundColor Cyan -NoNewline
            Write-Host " (${finalWidth}x${finalHeight}px) → $dest" -ForegroundColor Gray
            Write-Host "Saved to: $destPath" -ForegroundColor Gray
        }
        catch {
            # Clean up partial file so the collision guard doesn't block retries
            if ($destPath -and (Test-Path -LiteralPath $destPath)) {
                Remove-Item -LiteralPath $destPath -Force -ErrorAction SilentlyContinue
            }
            Write-Error "Failed to process image: $($_.Exception.Message) (catch these hands)"
        }
        finally {
            if ($null -ne $graphics) { $graphics.Dispose() }
            if ($null -ne $bitmap)   { $bitmap.Dispose() }
            if ($null -ne $img)      { $img.Dispose() }
            if ($null -ne $ms)       { $ms.Dispose() }
        }
    }
}
