function ConvertTo-MockText {
    <#
        .SYNOPSIS
            Converts text to mocking SpongeBob casing
        .DESCRIPTION
            tUrNs AnY tExT iNtO tHiS. Letters alternate case, non-letters are left alone.
            Supports pipeline input so you can mock literally anything fr fr.
        .PARAMETER text
            The text to mock. Accepts pipeline input (no cap).
        .PARAMETER noClipboard
            Don't copy the result to clipboard, just output it.
        .EXAMPLE
            PS > ConvertTo-MockText "code review approved"
            cOdE rEvIeW aPpRoVeD
        .EXAMPLE
            PS > "we ship on friday" | mock
            wE sHiP oN fRiDaY
        .EXAMPLE
            PS > git log --oneline | Select-Object -First 5 | mock
            mocks your entire commit history, as it deserves
    #>
    [alias('mocktext')]
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [string]$text,
        [Parameter(Mandatory = $false)]
        [switch]$noClipboard
    )
    begin {
        # accumulate piped lines so clipboard gets the whole thing (big brain)
        $allOutput = @()
    }
    process {
        # the sauce - alternate case per letter, skip non-letters so spacing doesn't break the toggle
        $result = ""
        $toggle = $false
        foreach ($char in $text.ToCharArray()) {
            if ([char]::IsLetter($char)) {
                $result += if ($toggle) { [char]::ToUpper($char) } else { [char]::ToLower($char) }
                $toggle = -not $toggle
            } else {
                $result += $char
            }
        }

        $allOutput += $result
        Write-Output $result
    }
    end {
        # yoink to clipboard (the whole thing, not just the last line)
        if (-not $noClipboard -and $allOutput.Count -gt 0) {
            $clipboardContent = $allOutput -join "`n"
            Set-Clipboard -Value $clipboardContent
            Write-Host "mocked and " -NoNewline -ForegroundColor DarkGray
            Write-Host "blæsted to clipboard" -ForegroundColor Green -NoNewline
            Write-Host " 🤡" -ForegroundColor DarkGray
        }
    }
}
