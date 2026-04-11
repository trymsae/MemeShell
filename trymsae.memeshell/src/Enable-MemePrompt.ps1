function Enable-MemePrompt {
    <#
        .SYNOPSIS
            Enables the highly sophisticated meme prompt.
        .DESCRIPTION
            Replaces your boring prompt with some dank lines.
        .PARAMETER allTheBitches
            Specifies all the bitches you aint getting son.
        .EXAMPLE
            PS> Enable-MemePrompt
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory = $false)]
        [switch]$allTheBitches
    )
    begin {
        # Save the current prompt before replacing it (save the actual function definition)
        if (-not $script:OriginalPrompt) {
            $script:OriginalPrompt = ${function:prompt}
        }
        # Load prompt messages from file (the juice)
        $promptMessagesFile = Join-Path $PSScriptRoot "templates\texts\prompt-messages.b64"
        if (Test-Path $promptMessagesFile) {
            try {
                $base64Content = Get-Content $promptMessagesFile -Raw
                $bytes = [Convert]::FromBase64String($base64Content.Trim())
                $decodedText = [System.Text.Encoding]::UTF8.GetString($bytes)
                $script:MemePrompts = $decodedText -split "`r?`n" | Where-Object { $_.Trim() -ne "" }
            }
            catch {
                # catch these hands (fallback to basics)
                $script:MemePrompts = @("DANK", "BASED", "no cap", "fr fr", "💀", "skill issue")
            }
        }
        else {
            # if file missing, lmao
            $script:MemePrompts = @("DANK", "BASED", "no cap", "fr fr", "💀", "skill issue")
        }
        # Dank colors for the prompt
        $script:MemeColors = @(
            "Cyan"
            "Magenta"
            "Yellow"
            "Green"
            "Red"
            "Blue"
            "DarkCyan"
            "DarkMagenta"
            "DarkYellow"
            "DarkGreen"
            "DarkRed"
        )
    }
    process {
        # Create the meme prompt function with random colors
        function global:prompt {
            $prefix = $script:MemePrompts | Get-Random
            $color1 = $script:MemeColors | Get-Random
            $color2 = $script:MemeColors | Get-Random
            $Path = (Get-Location).Path
            $Path = $Path -replace [regex]::Escape($env:USERPROFILE + "\"), "~\"
            # lmao
            if ((Get-Random -Minimum 1 -Maximum 35) -eq 1) {
                try {
                    $soundsPath = Join-Path $PSScriptRoot "templates\sounds"
                    if (Test-Path $soundsPath) {
                        $sounds = Get-ChildItem $soundsPath -Filter "*.wav" -ErrorAction SilentlyContinue
                        if ($sounds) {
                            $randomSound = $sounds | Get-Random
                            $player = New-Object System.Media.SoundPlayer
                            $player.SoundLocation = $randomSound.FullName
                            $player.Play()
                        }
                    }
                }
                catch {
                    # catch these hands
                }
            }
            # Chaos level selection (doing ur mom)
            $chaosRoll = Get-Random -Minimum 1 -Maximum 11
            if ($chaosRoll -le 5) {
                # 50% - Classic format
                Write-Host "[" -ForegroundColor $color2 -NoNewline
                Write-Host $prefix -ForegroundColor $color1 -NoNewline
                Write-Host "] - " -ForegroundColor $color2 -NoNewline
                Write-Host "(" -ForegroundColor $color2 -NoNewline
                Write-Host "$($Path)" -NoNewline
                Write-Host ")" -ForegroundColor $color2 -NoNewline
                Write-host " >" -NoNewline
            }
            elseif ($chaosRoll -eq 6) {
                # ALL CAPS SCREAMING
                Write-Host "[" -ForegroundColor $color2 -NoNewline
                Write-Host $prefix.ToUpper() -ForegroundColor $color1 -NoNewline
                Write-Host "] - " -ForegroundColor $color2 -NoNewline
                Write-Host "(" -ForegroundColor $color2 -NoNewline
                Write-Host "$($Path)" -NoNewline
                Write-Host ")" -ForegroundColor $color2 -NoNewline
                Write-host " >>>" -NoNewline
            }
            elseif ($chaosRoll -eq 7) {
                # dubblare
                $prefix2 = $script:MemePrompts | Get-Random
                Write-Host "[[" -ForegroundColor $color2 -NoNewline
                Write-Host $prefix -ForegroundColor $color1 -NoNewline
                Write-Host "] [" -ForegroundColor $color2 -NoNewline
                Write-Host $prefix2 -ForegroundColor $color1 -NoNewline
                Write-Host "]] " -ForegroundColor $color2 -NoNewline
                Write-Host "$($Path)" -NoNewline
                Write-host " $" -NoNewline
            }
            elseif ($chaosRoll -eq 8) {
                # no brackets?
                Write-Host $prefix -ForegroundColor $color1 -NoNewline
                Write-Host " @ " -ForegroundColor $color2 -NoNewline
                Write-Host "$($Path)" -NoNewline
                Write-host " #" -NoNewline
            }
            elseif ($chaosRoll -eq 9) {
                # spin it around bby
                Write-Host "]" -ForegroundColor $color2 -NoNewline
                Write-Host $prefix -ForegroundColor $color1 -NoNewline
                Write-Host "[ - " -ForegroundColor $color2 -NoNewline
                Write-Host ")" -ForegroundColor $color2 -NoNewline
                Write-Host "$($Path)" -NoNewline
                Write-Host "(" -ForegroundColor $color2 -NoNewline
                Write-host " <" -NoNewline
            }
            else {
                # lmao symbols
                $symbols = @(">", ">>", ">>>", "$", "#", "λ", "~>", "=>", "!!")
                $randomSymbol = $symbols | Get-Random
                Write-Host "{" -ForegroundColor $color2 -NoNewline
                Write-Host $prefix -ForegroundColor $color1 -NoNewline
                Write-Host "} " -ForegroundColor $color2 -NoNewline
                Write-Host "$($Path)" -NoNewline
                Write-host " $randomSymbol" -NoNewline
            }
            return " "
        }
    }
    end {
        Write-Host "MemePrompt enabled. your terminal is now " -ForegroundColor Cyan -NoNewline
        Write-Host "cooked" -ForegroundColor Red -NoNewline
        Write-Host "." -ForegroundColor Cyan
    }
}