function New-YoloCommit {
    <#
        .SYNOPSIS
            Generates unhinged but technically valid commit messages
        .DESCRIPTION
            Just send a commit message, bro.
        .PARAMETER type
            Commit type: feat, fix, chore, refactor, docs, style, test, perf, ci, build
        .PARAMETER module
            Module name for monorepo scope (default: trymsae.memeshell)
        .PARAMETER major
            major in ur mom.
        .PARAMETER noClipboard
            Just for display.
        .EXAMPLE
            PS > New-YoloCommit -type feat
            feat(trymsae.memeshell): yeet the deprecated code into the sun | mogged to clipboard
        .EXAMPLE
            PS > yolo fix
            fix(trymsae.memeshell): turns out the bug was a feature all along | mogged to clipboard
        .EXAMPLE
            PS > yolo feat -major
            feat(trymsae.memeshell)!: this changes everything
        .EXAMPLE
            PS > yolo feat -module "ur.mom"
            feat(ur.mom): built different fr fr | mogged to clipboard
    #>
    [alias('yolo')]
    [CmdletBinding()]
    param (
        [parameter(Position = 0, Mandatory = $true)]
        [ValidateSet('feat', 'fix', 'chore', 'refactor', 'docs', 'style', 'test', 'perf', 'ci', 'build')]
        [string]$type,
        [parameter(Position = 1, Mandatory = $false)]
        [string]$module = "trymsae.memeshell",
        [parameter(Position = 2, Mandatory = $false)]
        [switch]$major,
        [parameter(Position = 3, Mandatory = $false)]
        [switch]$noClipboard
    )
    begin {
        # get the sauce
        $messagesFile = Join-Path $PSScriptRoot "templates\texts\commit-messages.b64"
        if (Test-Path $messagesFile) {
            try {
                $base64Content = Get-Content $messagesFile -Raw
                $bytes = [Convert]::FromBase64String($base64Content.Trim())
                $decodedText = [System.Text.Encoding]::UTF8.GetString($bytes)
                $commitMessages = $decodedText -split "`r?`n" | Where-Object { $_.Trim() -ne "" }
            }
            catch {
                # catch these hands
                $commitMessages = @("something broke but we ship anyway")
            }
        }
        else {
            # if shit breaks, lmao.
            $commitMessages = @("yolo commit message generator broke lmao")
        }
    }
    process {
        # yeet a random message
        $randomMessage = $commitMessages | Get-Random
        # handle majors
        if ($major) {
            # breaking change vibes
            $output = "$($type)($($module))!: $($randomMessage)"
        }
        else {
            # what else?
            $output = "$($type)($($module)): $($randomMessage)"
        }
    }
    end {
        if ( -not $noClipboard ) {
            Set-Clipboard -Value $output
            Write-Host "$($output) | " -NoNewline
            Write-Host "mogged to clipboard" -ForegroundColor Green
        }
        else {
            Write-Host $output
        }
    }
}