function Register-MemeTabHook {
    <#
        .SYNOPSIS
            Registers PSReadLine Tab and Enter hooks for inline meme template previews.
            Called automatically at module import. Use Unregister-MemeTabHook to undo.
    #>

    $script:MemePreviewVisible = $false

    # Save original Tab binding so we can restore it on Remove-Module
    $existing = Get-PSReadLineKeyHandler | Where-Object { $_.Key -eq 'Tab' } | Select-Object -First 1
    if ($existing -and $existing.Function -ne 'Custom ScriptBlock') {
        $script:MemeShellOriginalTabFunction = $existing.Function
    }
    elseif ($existing -and $existing.Function -eq 'Custom ScriptBlock') {
        $script:MemeShellOriginalTabFunction = $null
        Write-Warning "MemeShell: couldn't snapshot your Tab binding — Remove-Module won't restore it fr fr"
    }
    else {
        $script:MemeShellOriginalTabFunction = 'TabCompleteNext'
    }

    # Save original Enter binding
    $existingEnter = Get-PSReadLineKeyHandler | Where-Object { $_.Key -eq 'Enter' } | Select-Object -First 1
    if ($existingEnter -and $existingEnter.Function -ne 'Custom ScriptBlock') {
        $script:MemeShellOriginalEnterFunction = $existingEnter.Function
    }
    else {
        $script:MemeShellOriginalEnterFunction = 'AcceptLine'
    }

    # Enter key: clear preview then accept the line
    Set-PSReadLineKeyHandler -Key Enter -ScriptBlock {
        if ($script:MemePreviewVisible) {
            try {
                $savedTop  = [Console]::CursorTop
                $savedLeft = [Console]::CursorLeft
                for ($i = 0; $i -lt 15; $i++) {
                    [Console]::SetCursorPosition(0, $savedTop + 1 + $i)
                    [Console]::Write("`e[2K")
                }
                [Console]::SetCursorPosition($savedLeft, $savedTop)
            }
            catch { }
            $script:MemePreviewVisible = $false
        }
        [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
    }

    Set-PSReadLineKeyHandler -Key Tab -ScriptBlock {
        # Step 1: advance the completion (what Tab normally does)
        [Microsoft.PowerShell.PSConsoleReadLine]::TabCompleteNext()

        # Step 2: read buffer after completion
        $line = $null; $cursor = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

        # Step 3: bail if this isn't a meme/New-Meme command
        if ([string]::IsNullOrWhiteSpace($line)) { return }
        $tokens      = ($line.Trim() -split '\s+')
        $commandName = $tokens[0]
        if ($commandName -notin @('meme', 'New-Meme')) { return }

        # Step 4: extract template name — last non-flag token after the command
        # Note: heuristic fails for positional args after flags (e.g. meme drake -topText hi)
        # In that case no preview shows — cosmetic miss, not a crash
        $templateName = $null
        for ($i = $tokens.Length - 1; $i -ge 1; $i--) {
            $t = $tokens[$i]
            if (-not $t.StartsWith('-')) {
                $templateName = $t.Trim('"', "'")
                break
            }
        }
        if (-not $templateName) { return }

        # Step 5: locate .ans file — bundled first, user cache second
        $modulePath = (Get-Module -Name 'trymsae.memeshell' -ErrorAction SilentlyContinue).ModuleBase
        $ansPath    = $null

        if ($modulePath) {
            $candidate = Join-Path $modulePath "templates\previews\$templateName.ans"
            if (Test-Path $candidate) { $ansPath = $candidate }
        }

        if (-not $ansPath) {
            $userCache = Join-Path $env:USERPROFILE ".memeshell\cache\previews\$templateName.ans"
            if (Test-Path $userCache) {
                $ansPath = $userCache
            }
            else {
                # Lazy-generate preview for user templates
                $userPicsPath = Join-Path $env:USERPROFILE ".memeshell\templates\pictures"
                $userTemplate = Get-ChildItem $userPicsPath -ErrorAction SilentlyContinue |
                    Where-Object { $_.BaseName -eq $templateName } |
                    Select-Object -First 1
                if ($userTemplate) {
                    try {
                        ConvertTo-MemePreview -ImagePath $userTemplate.FullName -OutputPath $userCache
                        if (Test-Path $userCache) { $ansPath = $userCache }
                    }
                    catch { }
                }
            }
        }

        if (-not $ansPath) { return }

        # Step 6: check there is room below the cursor in the visible viewport
        # CursorTop is buffer-relative; WindowTop is the top of the visible window in buffer coords
        $rowsBelow = [Console]::WindowHeight - ([Console]::CursorTop - [Console]::WindowTop)
        if ($rowsBelow -lt 17) { return }  # 15 preview rows + 2 buffer

        # Step 7: clear previous preview area, write new preview, restore cursor
        try {
            $previewRowCount = 15
            $savedTop  = [Console]::CursorTop
            $savedLeft = [Console]::CursorLeft

            # Erase each preview row individually to avoid scroll
            $script:MemePreviewVisible = $false
            for ($i = 0; $i -lt $previewRowCount; $i++) {
                [Console]::SetCursorPosition(0, $savedTop + 1 + $i)
                [Console]::Write("`e[2K")
            }

            # Write the preview starting one row below the input line
            [Console]::SetCursorPosition(0, $savedTop + 1)
            $preview = Get-Content -Path $ansPath -Raw -Encoding UTF8
            [Console]::Write($preview)

            # Restore cursor to the input line
            [Console]::SetCursorPosition($savedLeft, $savedTop)
            $script:MemePreviewVisible = $true
        }
        catch { }
    }
}

function Unregister-MemeTabHook {
    <#
        .SYNOPSIS
            Restores the original PSReadLine Tab and Enter bindings. Called by module OnRemove.
    #>
    if ($script:MemeShellOriginalTabFunction) {
        try {
            Set-PSReadLineKeyHandler -Key Tab -Function $script:MemeShellOriginalTabFunction
        }
        catch { }
    }
    if ($script:MemeShellOriginalEnterFunction) {
        try {
            Set-PSReadLineKeyHandler -Key Enter -Function $script:MemeShellOriginalEnterFunction
        }
        catch { }
    }
}
