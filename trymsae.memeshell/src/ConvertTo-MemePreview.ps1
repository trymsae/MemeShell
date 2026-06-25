function ConvertTo-MemePreview {
    <#
        .SYNOPSIS
            Renders a meme template as ANSI half-block art (the sauce)
        .PARAMETER ImagePath
            Full path to the source image
        .PARAMETER OutputPath
            Optional .ans output path — if omitted returns the string only
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$ImagePath,
        [Parameter(Position = 1)]
        [string]$OutputPath
    )

    Add-Type -AssemblyName System.Drawing

    $targetWidth  = 60
    $targetHeight = 30  # 2px per char row × 15 rows

    try {
        $image   = [System.Drawing.Image]::FromFile($ImagePath)
        $resized = New-Object System.Drawing.Bitmap($targetWidth, $targetHeight)
        $g       = [System.Drawing.Graphics]::FromImage($resized)
        $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $g.DrawImage($image, 0, 0, $targetWidth, $targetHeight)
        $g.Dispose()
        $image.Dispose()

        $sb = [System.Text.StringBuilder]::new()

        for ($row = 0; $row -lt $targetHeight; $row += 2) {
            for ($col = 0; $col -lt $targetWidth; $col++) {
                $top = $resized.GetPixel($col, $row)
                $bot = if (($row + 1) -lt $targetHeight) { $resized.GetPixel($col, $row + 1) } else { $top }
                # foreground = bottom pixel (lower half of ▄), background = top pixel
                [void]$sb.Append("`e[38;2;$($bot.R);$($bot.G);$($bot.B)m`e[48;2;$($top.R);$($top.G);$($top.B)m▄")
            }
            [void]$sb.Append("`e[0m`n")
        }

        $resized.Dispose()
        $result = $sb.ToString()

        if ($OutputPath) {
            $dir = Split-Path $OutputPath -Parent
            if ($dir -and -not (Test-Path $dir)) {
                New-Item -ItemType Directory -Path $dir -Force | Out-Null
            }
            Set-Content -Path $OutputPath -Value $result -Encoding UTF8 -NoNewline
        }

        return $result
    }
    catch {
        return $null  # no preview, no crash (catch these hands)
    }
}
