function Disable-MemePrompt {
    <#
    .SYNOPSIS
        Disables the MemeShell prompt and restores your original prompt
    .DESCRIPTION
        Returns your prompt to its pre-MemeShell state
    .EXAMPLE
        Disable-MemePrompt
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory = $false)]
        [switch]$noBitches
    )
    begin {
        # No bitches?
    }
    process {
        if ($script:OriginalPrompt) {
            # Restore the original prompt function, boring.
            Set-Content -Path function:global:prompt -Value $script:OriginalPrompt
        }
        else {
            Write-Warning "No original prompt found. noob."
        }
    }
    end {
        if ($script:OriginalPrompt) {
            Write-Host "MemePrompt disabled. normalcy restored, back to work I guess?" -ForegroundColor Green
        }
    }
}
