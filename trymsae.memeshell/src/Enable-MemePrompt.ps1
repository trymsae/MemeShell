function Enable-MemePrompt {
    <#
        .SYNOPSIS
            Enables the highly sophisticated meme prompt.
        .DESCRIPTION
            Replaces your boring prompt with some dank lines.
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
        $script:MemePrompts = @(
            "ඞ"
            "DANK"
            "BASED"
            "no cap"
            "fr fr"
            "💀"
            "stonks"
            "skill issue"
            "built different"
            "down bad"
            "caught in 4k"
            "ratio"
            "touch grass"
            "no bitches?"
            "bussin"
            "sheesh"
            "bruh"
            "oof"
            "big yikes"
            "F"
            "press F"
            "suffering from success"
            "task failed successfully"
            "not stonks"
            "this is fine"
            "we live in a society"
            "bottom text"
            "TOP TEXT"
            "needs more jpeg"
            "deep fried"
            "EMOTIONAL DAMAGE"
            "certified hood classic"
            "sigma grindset"
            "gigachad"
            "soy"
            "cringe"
            "unfathomably based"
            "unhinged"
            "feral"
            "absolutely unhinged"
            "delulu"
            "situationship"
            "rizz god"
            "no rizz"
            "L rizz"
            "W rizz"
            "ohio"
            "goofy ahh"
            "dawg"
            "bro really"
            "nah bro"
            "real"
            "fake"
            "cap detected"
            "main character energy"
            "side character arc"
            "villain era"
            "redemption arc"
            "NPC behavior"
            "quest failed"
            "achievement unlocked"
            "game over"
            "new game+"
            "hard mode"
            "easy mode"
            "god mode"
            "debug mode"
            "creative mode"
            "survival mode"
            "peaceful mode"
            "hardcore mode"
            "no thoughts head empty"
            "one braincell"
            "shared braincell"
            "lost the plot"
            "off the rails"
            "menace to society"
            "public enemy no.1"
            "wanted dead or alive"
            "BREAKING NEWS"
            "LEAKED"
            "NOT CLICKBAIT"
            "GONE WRONG"
            "COPS CALLED"
            "AT 3AM"
            "DO NOT TRY"
            "INSANE"
            "YOU WONT BELIEVE"
            "POV:"
            "mfw"
            "tfw"
            "mrw"
            "irl"
            "chronically online"
            "terminally online"
            "grass touching required"
            "vitamin D deficiency"
            "send help"
            "i cant even"
            "literally dying"
            "screaming"
            "sobbing"
            "throwing up"
            "unwell"
            "not okay"
            "losing it"
            "going feral"
            "clawing at the walls"
            "laying on the floor"
            "staring at ceiling"
            "disassociating"
            "maladaptive daydreaming"
            "hyperfixating"
            "neurodivergent"
            "autism powers activate"
            "adhd moment"
            "executive dysfunction"
            "object permanence who"
            "time is a construct"
            "sleep is for the weak"
            "3am thoughts"
            "existential dread"
            "void screaming"
            "eldritch horror"
            "cosmic horror"
            "psychological horror"
            "the horrors persist, but so do i"
            "built from spite"
            "running on spite"
            "fueled by haterism"
            "haters are my motivators"
            "they hate us cuz they aint us"
            "stay mad"
            "stay pressed"
            "cry about it"
            "cope"
            "seethe"
            "mald"
            "dilate"
            "rent free"
            "living in your walls"
            "inside your home"
            "hes right behind me isnt he"
            "parry this you filthy casual"
            "skill issue + ratio"
            "L + ratio + ur mom phat"
            "didnt ask + dont care"
            "who asked"
            "nobody asked"
            "the council will decide your fate"
            "i am the senate"
            "its treason then"
            "do it"
            "dew it"
            "visible confusion"
            "confused stonks"
            "panik"
            "kalm"
            "PANIK"
            "chuckles im in danger"
            "softly dont"
            "wait thats illegal"
            "FBI OPEN UP"
            "ladies and gentlemen we got em"
            "mission failed"
            "betrayal"
            "top 10 anime betrayals"
            "character development"
            "plot twist"
            "foreshadowing"
            "narrative foil"
            "deus ex machina"
            "macguffin acquired"
            "rawdogging it"
            "doing ur mom"
            "ur mom gae"
        )
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
            $Path = $Path -replace "C:\\Users\\$($env:USERNAME)\\", "~\"
            # lmao
            if ((Get-Random -Minimum 1 -Maximum 30) -eq 1) {
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
            Write-Host "[" -ForegroundColor $color2 -NoNewline
            Write-Host $prefix -ForegroundColor $color1 -NoNewline
            Write-Host "] - " -ForegroundColor $color2 -NoNewline
            Write-Host "(" -ForegroundColor $color2 -NoNewline
            Write-Host "$($Path)" -NoNewline
            Write-Host ")" -ForegroundColor $color2 -NoNewline
            Write-host " >" -NoNewline
            return " "
        }
    }
    end {
        Write-Host "MemePrompt enabled. your terminal is now " -ForegroundColor Cyan -NoNewline
        Write-Host "cooked" -ForegroundColor Red -NoNewline
        Write-Host ". no going back???. godspeed o7" -ForegroundColor Cyan
    }
}
