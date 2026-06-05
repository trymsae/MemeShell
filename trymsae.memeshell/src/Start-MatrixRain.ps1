function Start-MatrixRain {
    <#
        .SYNOPSIS
            Full-screen Matrix rain screensaver. Ctrl+C to exit.
        .DESCRIPTION
            Renders falling katakana characters in your terminal. Runs until you press Ctrl+C.
            Saves and restores all console state on exit (no escape from the sauce tho).
        .PARAMETER speed
            Rain speed: Slow, Normal (default), or Fast
        .PARAMETER color
            Rain color: Green (default), Cyan, or Red
        .EXAMPLE
            PS > Start-MatrixRain
            *green rain descends*
        .EXAMPLE
            PS > matrix -speed Fast -color Red
            *red chaos ensues*
    #>
    [alias('matrix')]
    [CmdletBinding()]
    param (
        [parameter(Position = 0, Mandatory = $false)]
        [ValidateSet('Slow', 'Normal', 'Fast')]
        [string]$speed = 'Normal',
        [parameter(Position = 1, Mandatory = $false)]
        [ValidateSet('Green', 'Cyan', 'Red')]
        [string]$color = 'Green'
    )

    # Color layers: head (bright), trail (normal), fade (dim)
    $colorMap = @{
        Green = @{ head = [ConsoleColor]::White; trail = [ConsoleColor]::Green;   fade = [ConsoleColor]::DarkGreen }
        Cyan  = @{ head = [ConsoleColor]::White; trail = [ConsoleColor]::Cyan;    fade = [ConsoleColor]::DarkCyan  }
        Red   = @{ head = [ConsoleColor]::White; trail = [ConsoleColor]::Red;     fade = [ConsoleColor]::DarkRed   }
    }
    $colors = $colorMap[$color]

    $tickMs = switch ($speed) {
        'Slow' { 80 }
        'Fast' { 20 }
        default { 40 }
    }

    # Half-width katakana (0xFF66-0xFF9F) + digits for that authentic look
    $charPool = [char[]](0xFF66..0xFF9F) + [char[]](0x30..0x39)

    # Save console state so we can restore it on exit (no memory leaks in this house)
    $originalCursorVisible  = [Console]::CursorVisible
    $originalForeground     = [Console]::ForegroundColor
    $originalBackground     = [Console]::BackgroundColor
    $originalTreatCtrlC     = [Console]::TreatControlCAsInput
    $originalOutputEncoding = [Console]::OutputEncoding
    [Console]::TreatControlCAsInput = $true
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8

    $initColumns = {
        param($w, $h)
        if ($w -le 0 -or $h -le 0) { return @() }
        0..($w - 1) | ForEach-Object {
            @{
                x           = $_
                headY       = Get-Random -Minimum (-$h) -Maximum 0
                trailLength = Get-Random -Minimum 5 -Maximum 22
                speedDiv    = Get-Random -Minimum 1 -Maximum 4  # per-column speed variation
                tickCount   = 0
                chars       = @{}  # y -> char drawn at that position
            }
        }
    }

    try {
        [Console]::CursorVisible  = $false
        [Console]::BackgroundColor = [ConsoleColor]::Black
        [Console]::Clear()

        $width   = [Console]::WindowWidth
        $height  = [Console]::WindowHeight
        $columns = & $initColumns $width $height

        while ($true) {
            # Ctrl+C check (TreatControlCAsInput means it won't kill the process directly)
            if ([Console]::KeyAvailable) {
                $key = [Console]::ReadKey($true)
                if ($key.Key -eq [ConsoleKey]::C -and ($key.Modifiers -band [ConsoleModifiers]::Control)) { break }
            }

            # Handle terminal resize gracefully
            $newW = [Console]::WindowWidth
            $newH = [Console]::WindowHeight
            if ($newW -ne $width -or $newH -ne $height) {
                $width  = $newW
                $height = $newH
                [Console]::Clear()
                $columns = & $initColumns $width $height
            }

            foreach ($col in $columns) {
                try {
                    $col.tickCount++
                    if ($col.tickCount -lt $col.speedDiv) { continue }
                    $col.tickCount = 0

                    $x     = $col.x
                    $headY = $col.headY

                    # Erase the position behind the tail end
                    $eraseY = $headY - $col.trailLength - 1
                    if ($eraseY -ge 0 -and $eraseY -lt $height) {
                        [Console]::SetCursorPosition($x, $eraseY)
                        [Console]::ForegroundColor = [ConsoleColor]::Black
                        [Console]::Write(' ')
                        $col.chars.Remove($eraseY)
                    }

                    # Dim the tail end (dark color)
                    $fadeY = $headY - $col.trailLength
                    if ($fadeY -ge 0 -and $fadeY -lt $height) {
                        if (-not $col.chars.ContainsKey($fadeY)) { $col.chars[$fadeY] = $charPool[(Get-Random -Maximum $charPool.Count)] }
                        [Console]::SetCursorPosition($x, $fadeY)
                        [Console]::ForegroundColor = $colors.fade
                        [Console]::Write($col.chars[$fadeY])
                    }

                    # Trail (normal color, one step behind head)
                    $trailY = $headY - 1
                    if ($trailY -ge 0 -and $trailY -lt $height) {
                        if (-not $col.chars.ContainsKey($trailY)) { $col.chars[$trailY] = $charPool[(Get-Random -Maximum $charPool.Count)] }
                        [Console]::SetCursorPosition($x, $trailY)
                        [Console]::ForegroundColor = $colors.trail
                        [Console]::Write($col.chars[$trailY])
                    }

                    # Head (bright color, randomly changing char)
                    if ($headY -ge 0 -and $headY -lt $height) {
                        $headChar = $charPool[(Get-Random -Maximum $charPool.Count)]
                        $col.chars[$headY] = $headChar
                        [Console]::SetCursorPosition($x, $headY)
                        [Console]::ForegroundColor = $colors.head
                        [Console]::Write($headChar)
                    }

                    $col.headY++

                    # Reset column once tail has fully scrolled off bottom
                    if (($col.headY - $col.trailLength - 1) -ge $height) {
                        $col.headY       = Get-Random -Minimum ([int](-$height / 2)) -Maximum 0
                        $col.trailLength = Get-Random -Minimum 5 -Maximum 22
                        $col.speedDiv    = Get-Random -Minimum 1 -Maximum 4
                        $col.chars       = @{}
                    }
                } catch [System.ArgumentOutOfRangeException] {
                    continue
                }
            }

            Start-Sleep -Milliseconds $tickMs
        }
    }
    finally {
        # Restore all state no matter what (try/finally goes hard)
        [Console]::TreatControlCAsInput = $originalTreatCtrlC
        [Console]::CursorVisible        = $originalCursorVisible
        [Console]::ForegroundColor      = $originalForeground
        [Console]::BackgroundColor      = $originalBackground
        [Console]::OutputEncoding       = $originalOutputEncoding
        [Console]::Clear()
        [Console]::SetCursorPosition(0, 0)
    }
}
