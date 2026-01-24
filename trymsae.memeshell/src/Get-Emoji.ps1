function Get-Emoji {
    <#
        .SYNOPSIS
            This function adds emojis to clipboard or directly in console
        .DESCRIPTION
            This function is a quick access for my personal used emojis. Now with more chaos.
        .PARAMETER emoji
            Specify your emoji or use 'random' for surprise
        .EXAMPLE
            PS > Get-Emoji -emoji dunno
            ¯\_(ツ)_/¯ | yoinked to clipboard
        .EXAMPLE
            PS > emoji random
            (╯°□°）╯︵ ┻━┻ | yoinked to clipboard
    #>
    [alias('emoji')]
    [CmdletBinding()]
    param (
        [parameter(Position = 0, Mandatory = $true)]
        [ValidateSet('dunno', 'beer', 'surfsup', 'tableflip', 'unflip', 'shrug', 'lenny', 'disapprove',
                     'dealwithit', 'rage', 'happy', 'sad', 'dead', 'fire', 'skull', 'eyes', 'point',
                     'think', 'clap', 'pray', 'facepalm', 'knife', 'gun', 'bomb',
                     'sus', 'based', 'cringe', 'yeet', 'oof', 'bruh', 'fr', 'nocap', 'ratio',
                     'random')]
        [string]$emoji,
        [parameter(Position = 1, Mandatory = $false)]
        [switch]$noClipboard
    )
    begin {
        # the juice
        $emojiMap = @{
            # the classics
            'dunno'      = '¯\_(ツ)_/¯'
            'shrug'      = '¯\_(ツ)_/¯'
            'tableflip'  = '(╯°□°）╯︵ ┻━┻'
            'unflip'     = '┬─┬ノ( º _ ºノ)'
            'lenny'      = '( ͡° ͜ʖ ͡°)'
            'disapprove' = 'ಠ_ಠ'
            'dealwithit' = '(⌐■_■)'
            'rage'       = '(ノಠ益ಠ)ノ彡┻━┻'
            'happy'      = '(◕‿◕)'
            'sad'        = '(╥﹏╥)'
            'dead'       = '(✖╭╮✖)'
            'think'      = '(¬‿¬)'
            # the mojis
            'beer'       = '🍺'
            'surfsup'    = '🤙'
            'fire'       = '🔥'
            'skull'      = '💀'
            'eyes'       = '👀'
            'point'      = '👉'
            'clap'       = '👏'
            'pray'       = '🙏'
            'facepalm'   = '🤦'
            'knife'      = '🔪'
            'gun'        = '🔫'
            'bomb'       = '💣'
            # the unwelcomed
            'sus'        = 'ඞ'
            'based'      = '🗿'
            'cringe'     = '😬'
            'yeet'       = '༼ つ ◕_◕ ༽つ'
            'oof'        = 'F'
            'bruh'       = '🤨'
            'fr'         = '💯'
            'nocap'      = '🧢'
            'ratio'      = '📉'
        }
        # rando
        if ($emoji -eq 'random') {
            $randomKey = $emojiMap.Keys | Where-Object { $_ -ne 'random' } | Get-Random
            $output = $emojiMap[$randomKey]
            $emoji = $randomKey  # for display purposes
        }
        else {
            $output = $emojiMap[$emoji]
        }
    }
    process {
        # no bitches?
    }
    end {
        if ( -not $noClipboard ) {
            Set-Clipboard -Value $output
            Write-Host "$($output) | " -NoNewline
            Write-Host "plastered to clipboard" -ForegroundColor Green -NoNewline
            Write-Host " [$emoji]" -ForegroundColor DarkGray
        }
        else {
            Write-Host $output
        }
    }
}