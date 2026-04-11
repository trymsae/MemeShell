function New-Meme {
    <#
        .SYNOPSIS
            Generates dank memes from local templates
        .DESCRIPTION
            Creates memes by adding text to local image templates. Classic top/bottom text format or use -manual for GUI mode.
        .PARAMETER template
            Template image name (without extension) from templates\pictures folder
        .PARAMETER topText
            Text for the top of the meme (classic format)
        .PARAMETER bottomText
            Text for the bottom of the meme (classic format)
        .PARAMETER manual
            Opens GUI window for manual meme creation (more control, less speed)
        .PARAMETER noClipboard
            Don't copy the result to clipboard (just save it)
        .PARAMETER textCase
            Text casing: Upper (default, classic meme), Lower, or Original (keep as typed)
        .EXAMPLE
            PS > New-Meme -template "drake" -topText "Using APIs" -bottomText "Local images with PowerShell"
            Meme created and mogged to clipboard
        .EXAMPLE
            PS > New-Meme -template "drake" -topText "Shouting" -bottomText "whispering" -textCase Original
            Renders with exact casing as typed
        .EXAMPLE
            PS > meme -manual
            Opens GUI for manual meme crafting
    #>
    [alias('meme')]
    [CmdletBinding()]
    param (
        [parameter(Position = 0, Mandatory = $false)]
        [ArgumentCompleter({
            param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
            $modulePath = (Get-Module -Name 'trymsae.memeshell' -ErrorAction SilentlyContinue).ModuleBase
            if (-not $modulePath) { return }
            $picturesPath = Join-Path $modulePath "templates\pictures"
            if (Test-Path $picturesPath) {
                Get-ChildItem $picturesPath -Include *.jpg,*.jpeg,*.png,*.bmp -Recurse -ErrorAction SilentlyContinue |
                    Where-Object { $_.BaseName -like "$wordToComplete*" } |
                    ForEach-Object { $_.BaseName }
            }
        })]
        [string]$template,
        [parameter(Position = 1, Mandatory = $false)]
        [string]$topText,
        [parameter(Position = 2, Mandatory = $false)]
        [string]$bottomText,
        [parameter(Position = 3, Mandatory = $false)]
        [switch]$manual,
        [parameter(Position = 4, Mandatory = $false)]
        [switch]$noClipboard,
        [parameter(Position = 5, Mandatory = $false)]
        [ValidateSet('Upper', 'Lower', 'Original')]
        [string]$textCase = 'Original',
        [parameter(Position = 6, Mandatory = $false)]
        [ValidateRange(2, 6)]
        [int]$TextLines = 2
    )
    begin {
        # Load the juice (System.Drawing for image manipulation)
        Add-Type -AssemblyName System.Drawing
        Add-Type -AssemblyName System.Windows.Forms

        $script:newMemeInitOk = $false

        # get templates folder
        $picturesPath = Join-Path $PSScriptRoot "templates\pictures"

        if (-not (Test-Path $picturesPath)) {
            Write-Error "Templates folder not found at: $picturesPath (no bitches?)"
            return
        }

        # grab all image files
        $availableTemplates = Get-ChildItem $picturesPath -Include *.jpg,*.jpeg,*.png,*.bmp -Recurse -ErrorAction SilentlyContinue

        if ($availableTemplates.Count -eq 0) {
            Write-Error "No templates found in $picturesPath (folder is empty fr)"
            return
        }

        # temp output path
        $tempPath = [System.IO.Path]::GetTempPath()
        $outputFile = Join-Path $tempPath "meme_$(Get-Date -Format 'yyyyMMdd_HHmmss').png"

        $script:newMemeInitOk = $true
    }
    process {
        # bail if begin failed (return in begin doesn't stop process, no cap)
        if (-not $script:newMemeInitOk) { return }

        $useMultiLineMode = $false

        # Manual mode (GUI goes hard)
        if ($manual) {
            # Calculate form height based on text lines (dynamic sizing fr fr)
            $textLineHeight = 80
            $previewStartY = 90 + ($TextLines * $textLineHeight) + 20
            $previewHeight = 250
            $buttonY = $previewStartY + $previewHeight + 20
            $formHeight = $buttonY + 80

            # Create the form (dynamic height based on text lines, wider for X controls)
            $form = New-Object System.Windows.Forms.Form
            $form.Text = "MemeShell - Manual Mode 🔥 ($TextLines lines)"
            $form.Size = New-Object System.Drawing.Size 780, $formHeight
            $form.StartPosition = "CenterScreen"
            $form.FormBorderStyle = "FixedDialog"
            $form.MaximizeBox = $false

            # Template dropdown
            $labelTemplate = New-Object System.Windows.Forms.Label
            $labelTemplate.Location = New-Object System.Drawing.Point 10, 20
            $labelTemplate.Size = New-Object System.Drawing.Size 280, 20
            $labelTemplate.Text = "Select Template:"
            $form.Controls.Add($labelTemplate)

            $comboTemplate = New-Object System.Windows.Forms.ComboBox
            $comboTemplate.Location = New-Object System.Drawing.Point 10, 45
            $comboTemplate.Size = New-Object System.Drawing.Size 740, 25
            $comboTemplate.DropDownStyle = "DropDownList"
            foreach ($tmpl in $availableTemplates) {
                $comboTemplate.Items.Add($tmpl.BaseName) | Out-Null
            }
            if ($comboTemplate.Items.Count -gt 0) {
                # Pre-select the template passed via -template, otherwise fall back to first (no more always-bernie bug)
                $preSelectedIdx = $comboTemplate.Items.IndexOf($template)
                $comboTemplate.SelectedIndex = if ($preSelectedIdx -ge 0) { $preSelectedIdx } else { 0 }
            }
            $form.Controls.Add($comboTemplate)

            # Create dynamic text line controls (array-based for flexibility)
            $textBoxes = @()
            $numericXControls = @()
            $numericYControls = @()
            $checkboxWrapControls = @()
            $defaultYPositions = @(50, 200, 350, 500, 650, 800)  # Default Y positions for up to 6 lines

            for ($i = 0; $i -lt $TextLines; $i++) {
                $yPos = 90 + ($i * $textLineHeight)
                $lineNum = $i + 1

                # Text label
                $labelText = New-Object System.Windows.Forms.Label
                $labelText.Location = New-Object System.Drawing.Point 10, $yPos
                $labelText.Size = New-Object System.Drawing.Size 280, 20
                $labelText.Text = "Text Line $($lineNum):"
                $form.Controls.Add($labelText)

                # Text input
                $textBox = New-Object System.Windows.Forms.TextBox
                $textBox.Location = New-Object System.Drawing.Point 10, ($yPos + 25)
                $textBox.Size = New-Object System.Drawing.Size 380, 25
                $textBox.Font = New-Object System.Drawing.Font("Arial", 10)
                $textBox.Tag = $i  # Store index for later reference
                $form.Controls.Add($textBox)
                $textBoxes += $textBox

                # X position label
                $labelX = New-Object System.Windows.Forms.Label
                $labelX.Location = New-Object System.Drawing.Point 400, ($yPos + 5)
                $labelX.Size = New-Object System.Drawing.Size 70, 20
                $labelX.Text = "X Position:"
                $form.Controls.Add($labelX)

                # X position control (-1 = center, 0+ = absolute position)
                $numericX = New-Object System.Windows.Forms.NumericUpDown
                $numericX.Location = New-Object System.Drawing.Point 400, ($yPos + 25)
                $numericX.Size = New-Object System.Drawing.Size 80, 25
                $numericX.Minimum = -1
                $numericX.Maximum = 2000
                $numericX.Value = -1  # -1 means "center" (auto-calculated)
                $numericX.Increment = 5
                $numericX.Tag = $i
                $form.Controls.Add($numericX)
                $numericXControls += $numericX

                # Y position label
                $labelY = New-Object System.Windows.Forms.Label
                $labelY.Location = New-Object System.Drawing.Point 490, ($yPos + 5)
                $labelY.Size = New-Object System.Drawing.Size 70, 20
                $labelY.Text = "Y Position:"
                $form.Controls.Add($labelY)

                # Y position control
                $numericY = New-Object System.Windows.Forms.NumericUpDown
                $numericY.Location = New-Object System.Drawing.Point 490, ($yPos + 25)
                $numericY.Size = New-Object System.Drawing.Size 80, 25
                $numericY.Minimum = 0
                $numericY.Maximum = 2000
                $numericY.Value = $defaultYPositions[$i]
                $numericY.Increment = 5
                $numericY.Tag = $i  # Store index for later reference
                $form.Controls.Add($numericY)
                $numericYControls += $numericY

                # Center X button (quick reset to center)
                $buttonCenterX = New-Object System.Windows.Forms.Button
                $buttonCenterX.Location = New-Object System.Drawing.Point 580, ($yPos + 24)
                $buttonCenterX.Size = New-Object System.Drawing.Size 75, 25
                $buttonCenterX.Text = "Center X"
                $buttonCenterX.Tag = $i
                $buttonCenterX.Add_Click({
                    param($btnSender, $btnEvent)
                    $index = $btnSender.Tag
                    $numericXControls[$index].Value = -1
                })
                $form.Controls.Add($buttonCenterX)

                # Auto-wrap checkbox
                $checkboxWrap = New-Object System.Windows.Forms.CheckBox
                $checkboxWrap.Location = New-Object System.Drawing.Point 665, ($yPos + 26)
                $checkboxWrap.Size = New-Object System.Drawing.Size 100, 20
                $checkboxWrap.Text = "Auto-wrap"
                $checkboxWrap.Checked = $true
                $checkboxWrap.Tag = $i
                $form.Controls.Add($checkboxWrap)
                $checkboxWrapControls += $checkboxWrap
            }

            # Set initial text for first two lines if provided (backward compatibility)
            if ($textBoxes.Count -ge 1 -and -not [string]::IsNullOrWhiteSpace($topText)) {
                $textBoxes[0].Text = $topText
            }
            if ($textBoxes.Count -ge 2 -and -not [string]::IsNullOrWhiteSpace($bottomText)) {
                $textBoxes[1].Text = $bottomText
            }

            # Preview box
            $pictureBox = New-Object System.Windows.Forms.PictureBox
            $pictureBox.Location = New-Object System.Drawing.Point 10, $previewStartY
            $pictureBox.Size = New-Object System.Drawing.Size 740, $previewHeight
            $pictureBox.SizeMode = "Zoom"
            $pictureBox.BorderStyle = "FixedSingle"
            $form.Controls.Add($pictureBox)

            # Live preview update function (the sauce)
            $updatePreview = {
                $selectedTemplate = $availableTemplates | Where-Object { $_.BaseName -eq $comboTemplate.SelectedItem }

                if (-not $selectedTemplate) { return }

                try {
                    # Dispose previous image
                    if ($pictureBox.Image) {
                        $pictureBox.Image.Dispose()
                    }

                    # Load base template
                    $previewImage = [System.Drawing.Image]::FromFile($selectedTemplate.FullName)
                    $previewBitmap = New-Object System.Drawing.Bitmap($previewImage.Width, $previewImage.Height)
                    $previewGraphics = [System.Drawing.Graphics]::FromImage($previewBitmap)
                    $previewGraphics.DrawImage($previewImage, 0, 0, $previewImage.Width, $previewImage.Height)

                    # Set up text rendering (MAXIMUM QUALITY MODE - matches final output)
                    $previewGraphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
                    $previewGraphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
                    $previewGraphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
                    $previewGraphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic

                    # Font setup
                    $previewFontSize = [Math]::Max(24, $previewImage.Width / 15)
                    $previewFont = New-Object System.Drawing.Font("Impact", $previewFontSize, [System.Drawing.FontStyle]::Bold)
                    $previewBrushWhite = [System.Drawing.Brushes]::White
                    $previewPenBlack = New-Object System.Drawing.Pen([System.Drawing.Color]::Black, ($previewFontSize / 12))
                    $previewPenBlack.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round  # Smooth corners, no artifacts

                    # Helper to draw text with outline and wrapping support (chef's kiss)
                    $drawPreviewText = {
                        param($text, $x, $y, $useXCenter, $enableWrap)

                        if ([string]::IsNullOrWhiteSpace($text)) { return }

                        $formattedText = switch ($textCase) {
                            'Lower'    { $text.ToLower() }
                            'Original' { $text }
                            default    { $text.ToUpper() }
                        }

                        # Check if wrapping is needed
                        $textWidth = $previewGraphics.MeasureString($formattedText, $previewFont).Width
                        $maxWidth = $previewImage.Width * 0.9  # Leave 10% margin

                        if ($enableWrap -and $textWidth -gt $maxWidth) {
                            # Split text into words and wrap (the wrapping sauce)
                            $words = $formattedText -split ' '
                            $lines = @()
                            $currentLine = ""

                            foreach ($word in $words) {
                                $testLine = if ($currentLine) { "$currentLine $word" } else { $word }
                                $testWidth = $previewGraphics.MeasureString($testLine, $previewFont).Width

                                if ($testWidth -gt $maxWidth -and $currentLine) {
                                    $lines += $currentLine
                                    $currentLine = $word
                                } else {
                                    $currentLine = $testLine
                                }
                            }
                            if ($currentLine) { $lines += $currentLine }

                            # Draw each line with offset
                            $lineHeight = $previewFontSize * 1.2
                            $startY = $y - (($lines.Count - 1) * $lineHeight / 2)

                            for ($lineIdx = 0; $lineIdx -lt $lines.Count; $lineIdx++) {
                                $lineY = $startY + ($lineIdx * $lineHeight)
                                $lineX = if ($useXCenter) { $previewImage.Width / 2 } else { $x }

                                $format = New-Object System.Drawing.StringFormat
                                $format.Alignment = if ($useXCenter) { [System.Drawing.StringAlignment]::Center } else { [System.Drawing.StringAlignment]::Near }
                                $format.LineAlignment = [System.Drawing.StringAlignment]::Center

                                $path = New-Object System.Drawing.Drawing2D.GraphicsPath
                                $path.AddString(
                                    $lines[$lineIdx],
                                    $previewFont.FontFamily,
                                    [int]$previewFont.Style,
                                    $previewFontSize,
                                    (New-Object System.Drawing.PointF($lineX, $lineY)),
                                    $format
                                )

                                $previewGraphics.DrawPath($previewPenBlack, $path)
                                $previewGraphics.FillPath($previewBrushWhite, $path)

                                $path.Dispose()
                                $format.Dispose()
                            }
                        }
                        else {
                            # Single line rendering (classic mode)
                            $finalX = if ($useXCenter) { $previewImage.Width / 2 } else { $x }

                            $format = New-Object System.Drawing.StringFormat
                            $format.Alignment = if ($useXCenter) { [System.Drawing.StringAlignment]::Center } else { [System.Drawing.StringAlignment]::Near }
                            $format.LineAlignment = [System.Drawing.StringAlignment]::Center

                            $path = New-Object System.Drawing.Drawing2D.GraphicsPath
                            $path.AddString(
                                $formattedText,
                                $previewFont.FontFamily,
                                [int]$previewFont.Style,
                                $previewFontSize,
                                (New-Object System.Drawing.PointF($finalX, $y)),
                                $format
                            )

                            $previewGraphics.DrawPath($previewPenBlack, $path)
                            $previewGraphics.FillPath($previewBrushWhite, $path)

                            $path.Dispose()
                            $format.Dispose()
                        }
                    }

                    # Draw all text lines dynamically with X position and wrapping (no cap we looping fr)
                    for ($j = 0; $j -lt $textBoxes.Count; $j++) {
                        if (-not [string]::IsNullOrWhiteSpace($textBoxes[$j].Text)) {
                            $textX = $numericXControls[$j].Value
                            $textY = $numericYControls[$j].Value
                            $useCenter = ($textX -eq -1)
                            $actualX = if ($useCenter) { $previewImage.Width / 2 } else { $textX }
                            $wrapEnabled = $checkboxWrapControls[$j].Checked

                            & $drawPreviewText $textBoxes[$j].Text $actualX $textY $useCenter $wrapEnabled
                        }
                    }

                    # Cleanup and set preview
                    $previewGraphics.Dispose()
                    $previewFont.Dispose()
                    $previewPenBlack.Dispose()
                    $previewImage.Dispose()

                    $pictureBox.Image = $previewBitmap
                }
                catch {
                    # catch these hands (fallback to template only)
                    Write-Verbose "Preview update failed: $($_.Exception.Message)"
                }
            }

            # Load initial preview
            & $updatePreview

            # Hook up all the events to update preview (live preview goes hard)
            $comboTemplate.Add_SelectedIndexChanged({ & $updatePreview })

            # Hook up events for all text lines dynamically (array gang)
            for ($k = 0; $k -lt $textBoxes.Count; $k++) {
                $textBoxes[$k].Add_TextChanged({ & $updatePreview })
                $numericXControls[$k].Add_ValueChanged({ & $updatePreview })
                $numericYControls[$k].Add_ValueChanged({ & $updatePreview })
                $checkboxWrapControls[$k].Add_CheckedChanged({ & $updatePreview })
            }

            # Mouse drag functionality (absolute madness but it works fr fr)
            $script:isDragging = $false
            $script:dragTargetIndex = -1  # Index of text line being dragged
            $script:lastMouseY = 0

            $pictureBox.Add_MouseDown({
                param($clickSender, $clickEvent)

                if (-not $pictureBox.Image) { return }

                # Convert click coordinates to image coordinates (account for zoom)
                $displayRect = $pictureBox.ClientRectangle

                # Calculate actual image position in the control (centered with zoom)
                $imageAspect = $pictureBox.Image.Width / $pictureBox.Image.Height
                $controlAspect = $displayRect.Width / $displayRect.Height

                if ($imageAspect -gt $controlAspect) {
                    # Image is wider - fit to width
                    $displayWidth = $displayRect.Width
                    $displayHeight = [int]($displayRect.Width / $imageAspect)
                    $displayX = 0
                    $displayY = [int](($displayRect.Height - $displayHeight) / 2)
                }
                else {
                    # Image is taller - fit to height
                    $displayHeight = $displayRect.Height
                    $displayWidth = [int]($displayRect.Height * $imageAspect)
                    $displayX = [int](($displayRect.Width - $displayWidth) / 2)
                    $displayY = 0
                }

                # Convert mouse coordinates to image coordinates
                if ($clickEvent.X -lt $displayX -or $clickEvent.X -gt ($displayX + $displayWidth) -or
                    $clickEvent.Y -lt $displayY -or $clickEvent.Y -gt ($displayY + $displayHeight)) {
                    return  # Click outside image
                }

                $imageY = [int](($clickEvent.Y - $displayY) / $displayHeight * $pictureBox.Image.Height)

                # Check if clicking near any text line (50px tolerance, find closest)
                $closestIndex = -1
                $closestDistance = 999999

                for ($m = 0; $m -lt $textBoxes.Count; $m++) {
                    # Only check lines with text
                    if ([string]::IsNullOrWhiteSpace($textBoxes[$m].Text)) { continue }

                    $lineY = $numericYControls[$m].Value
                    $distance = [Math]::Abs($imageY - $lineY)

                    if ($distance -lt $closestDistance -and $distance -lt 50) {
                        $closestDistance = $distance
                        $closestIndex = $m
                    }
                }

                # Start dragging if we found a nearby text line (that's the vibe - now with X and Y drag support)
                if ($closestIndex -ge 0) {
                    $script:isDragging = $true
                    $script:dragTargetIndex = $closestIndex
                    $script:lastMouseY = $imageY
                    $pictureBox.Cursor = [System.Windows.Forms.Cursors]::SizeAll

                    # If X is centered (-1), unlock it to the actual center pixel so dragging works immediately (no more 1px workaround)
                    if ($numericXControls[$closestIndex].Value -eq -1) {
                        $numericXControls[$closestIndex].Value = [int]($pictureBox.Image.Width / 2)
                    }
                }
            })

            $pictureBox.Add_MouseMove({
                param($moveSender, $moveEvent)

                if (-not $script:isDragging -or -not $pictureBox.Image) { return }

                # Convert to image coordinates (same logic as MouseDown)
                $displayRect = $pictureBox.ClientRectangle
                $imageAspect = $pictureBox.Image.Width / $pictureBox.Image.Height
                $controlAspect = $displayRect.Width / $displayRect.Height

                if ($imageAspect -gt $controlAspect) {
                    $displayWidth = $displayRect.Width
                    $displayHeight = [int]($displayRect.Width / $imageAspect)
                    $displayX = 0
                    $displayY = [int](($displayRect.Height - $displayHeight) / 2)
                }
                else {
                    $displayHeight = $displayRect.Height
                    $displayWidth = [int]($displayRect.Height * $imageAspect)
                    $displayX = [int](($displayRect.Width - $displayWidth) / 2)
                    $displayY = 0
                }

                $imageX = [int](($moveEvent.X - $displayX) / $displayWidth * $pictureBox.Image.Width)
                $imageY = [int](($moveEvent.Y - $displayY) / $displayHeight * $pictureBox.Image.Height)

                # Clamp to image bounds
                $imageX = [Math]::Max(0, [Math]::Min($imageX, $pictureBox.Image.Width))
                $imageY = [Math]::Max(0, [Math]::Min($imageY, $pictureBox.Image.Height))

                # Update both X and Y numeric controls (this triggers preview update)
                if ($script:dragTargetIndex -ge 0 -and $script:dragTargetIndex -lt $numericYControls.Count) {
                    # Only update X if it's not set to center (-1)
                    if ($numericXControls[$script:dragTargetIndex].Value -ne -1) {
                        $numericXControls[$script:dragTargetIndex].Value = $imageX
                    }
                    $numericYControls[$script:dragTargetIndex].Value = $imageY
                }
            })

            $pictureBox.Add_MouseUp({
                param($upSender, $upEvent)

                if ($script:isDragging) {
                    $script:isDragging = $false
                    $script:dragTargetIndex = -1
                    $pictureBox.Cursor = [System.Windows.Forms.Cursors]::Default
                }
            })

            # Generate button
            $buttonGenerate = New-Object System.Windows.Forms.Button
            $buttonGenerate.Location = New-Object System.Drawing.Point 10, $buttonY
            $buttonGenerate.Size = New-Object System.Drawing.Size 740, 40
            $buttonGenerate.Text = "Generate Meme"
            $buttonGenerate.Font = New-Object System.Drawing.Font("Arial", 11, [System.Drawing.FontStyle]::Bold)
            $buttonGenerate.Add_Click({
                $script:manualTemplate = $comboTemplate.SelectedItem

                # Collect all text lines, positions, and settings directly to arrays (no ArrayList nonsense)
                $script:manualTextLines = @()
                $script:manualXPositions = @()
                $script:manualYPositions = @()
                $script:manualWrapSettings = @()

                for ($n = 0; $n -lt $textBoxes.Count; $n++) {
                    $script:manualTextLines += [string]$textBoxes[$n].Text
                    $script:manualXPositions += [int]$numericXControls[$n].Value
                    $script:manualYPositions += [int]$numericYControls[$n].Value
                    $script:manualWrapSettings += [bool]$checkboxWrapControls[$n].Checked
                }

                $form.DialogResult = [System.Windows.Forms.DialogResult]::OK
                $form.Close()
            })
            $form.Controls.Add($buttonGenerate)

            # Show form
            $result = $form.ShowDialog()

            # Cleanup
            if ($pictureBox.Image) {
                $pictureBox.Image.Dispose()
            }
            $form.Dispose()

            if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
                $template = $script:manualTemplate

                # Use script-level arrays directly (no conversion nonsense that breaks everything)
                # Check if we have any non-blank text (filter out empties)
                $hasNonBlankText = $false
                for ($idx = 0; $idx -lt $script:manualTextLines.Count; $idx++) {
                    if (-not [string]::IsNullOrWhiteSpace($script:manualTextLines[$idx])) {
                        $hasNonBlankText = $true
                        break
                    }
                }

                # Set flags for later use
                $useMultiLineMode = $hasNonBlankText

                # Backward compatibility: set topText/bottomText from first 2 lines for classic fallback
                if ($script:manualTextLines.Count -ge 1 -and -not [string]::IsNullOrWhiteSpace($script:manualTextLines[0])) {
                    $topText = $script:manualTextLines[0]
                    $topTextY = $script:manualYPositions[0]
                }
                if ($script:manualTextLines.Count -ge 2 -and -not [string]::IsNullOrWhiteSpace($script:manualTextLines[1])) {
                    $bottomText = $script:manualTextLines[1]
                    $bottomTextY = $script:manualYPositions[1]
                }
            }
            else {
                Write-Host "Meme generation cancelled (skill issue)" -ForegroundColor Yellow
                return
            }
        }

        # Validate template
        if ([string]::IsNullOrWhiteSpace($template)) {
            Write-Error "No template specified. Use -template or -manual (bruh)"
            Write-Host "Available templates:" -ForegroundColor Cyan
            $availableTemplates | ForEach-Object { Write-Host "  - $($_.BaseName)" -ForegroundColor Gray }
            return
        }

        # Find the template file
        $templateFile = $availableTemplates | Where-Object { $_.BaseName -eq $template } | Select-Object -First 1

        if (-not $templateFile) {
            Write-Error "Template '$template' not found (L + ratio)"
            Write-Host "Available templates:" -ForegroundColor Cyan
            $availableTemplates | ForEach-Object { Write-Host "  - $($_.BaseName)" -ForegroundColor Gray }
            return
        }

        # Load image
        try {
            $image = [System.Drawing.Image]::FromFile($templateFile.FullName)
            $bitmap = New-Object System.Drawing.Bitmap($image.Width, $image.Height)
            $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
            $graphics.DrawImage($image, 0, 0, $image.Width, $image.Height)

            # Set up text rendering (MAXIMUM QUALITY MODE - no more grimy text)
            $graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
            $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
            $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
            $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic

            # Font setup (Impact-style, bold and thicc)
            $fontSize = [Math]::Max(24, $image.Width / 15)
            $font = New-Object System.Drawing.Font("Impact", $fontSize, [System.Drawing.FontStyle]::Bold)
            $brushWhite = [System.Drawing.Brushes]::White
            $penBlack = New-Object System.Drawing.Pen([System.Drawing.Color]::Black, ($fontSize / 12))
            $penBlack.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round  # Smooth corners, no black streaks

            # Helper function to draw outlined text with wrapping support (the sauce with extra sauce)
            $drawOutlinedText = {
                param($text, $x, $y, $alignment, $enableWrap)

                if ([string]::IsNullOrWhiteSpace($text)) { return }

                $formattedText = switch ($textCase) {
                    'Lower'    { $text.ToLower() }
                    'Original' { $text }
                    default    { $text.ToUpper() }
                }

                # Check if wrapping is needed
                $textWidth = $graphics.MeasureString($formattedText, $font).Width
                $maxWidth = $image.Width * 0.9  # Leave 10% margin

                if ($enableWrap -and $textWidth -gt $maxWidth) {
                    # Split text into words and wrap (wrapping goes hard fr)
                    $words = $formattedText -split ' '
                    $lines = @()
                    $currentLine = ""

                    foreach ($word in $words) {
                        $testLine = if ($currentLine) { "$currentLine $word" } else { $word }
                        $testWidth = $graphics.MeasureString($testLine, $font).Width

                        if ($testWidth -gt $maxWidth -and $currentLine) {
                            $lines += $currentLine
                            $currentLine = $word
                        } else {
                            $currentLine = $testLine
                        }
                    }
                    if ($currentLine) { $lines += $currentLine }

                    # Draw each line with offset (multi-line rendering)
                    $lineHeight = $fontSize * 1.2
                    $startY = $y - (($lines.Count - 1) * $lineHeight / 2)

                    for ($lineIdx = 0; $lineIdx -lt $lines.Count; $lineIdx++) {
                        $lineY = $startY + ($lineIdx * $lineHeight)

                        $format = New-Object System.Drawing.StringFormat
                        $format.Alignment = $alignment
                        $format.LineAlignment = [System.Drawing.StringAlignment]::Center

                        $path = New-Object System.Drawing.Drawing2D.GraphicsPath
                        $path.AddString(
                            $lines[$lineIdx],
                            $font.FontFamily,
                            [int]$font.Style,
                            $fontSize,
                            (New-Object System.Drawing.PointF($x, $lineY)),
                            $format
                        )

                        $graphics.DrawPath($penBlack, $path)
                        $graphics.FillPath($brushWhite, $path)

                        $path.Dispose()
                        $format.Dispose()
                    }
                }
                else {
                    # Single line rendering (classic mode)
                    $format = New-Object System.Drawing.StringFormat
                    $format.Alignment = $alignment
                    $format.LineAlignment = [System.Drawing.StringAlignment]::Center

                    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
                    $path.AddString(
                        $formattedText,
                        $font.FontFamily,
                        [int]$font.Style,
                        $fontSize,
                        (New-Object System.Drawing.PointF($x, $y)),
                        $format
                    )

                    # Draw black outline (thicc)
                    $graphics.DrawPath($penBlack, $path)
                    # Draw white fill
                    $graphics.FillPath($brushWhite, $path)

                    $path.Dispose()
                    $format.Dispose()
                }
            }

            # Draw text lines (multi-line support with X positioning and wrapping fr fr)
            if ($useMultiLineMode -and $script:manualTextLines -and $script:manualTextLines.Count -gt 0) {
                # Manual mode with multiple text lines (using script arrays directly, no conversion bs)
                for ($p = 0; $p -lt $script:manualTextLines.Count; $p++) {
                    $currentText = $script:manualTextLines[$p]
                    if (-not [string]::IsNullOrWhiteSpace($currentText)) {
                        $textX = $script:manualXPositions[$p]
                        $textY = $script:manualYPositions[$p]
                        $wrapEnabled = $script:manualWrapSettings[$p]

                        # Determine X position and alignment
                        $useCenter = ($textX -eq -1)
                        $finalX = if ($useCenter) { $image.Width / 2 } else { $textX }
                        $alignment = if ($useCenter) { [System.Drawing.StringAlignment]::Center } else { [System.Drawing.StringAlignment]::Near }

                        & $drawOutlinedText $currentText $finalX $textY $alignment $wrapEnabled
                    }
                }
            }
            else {
                # Classic mode with just top/bottom text (backward compatibility with wrapping enabled)
                if (-not [string]::IsNullOrWhiteSpace($topText)) {
                    # Use custom Y position if provided (from manual mode), otherwise default
                    # NOTE: use $null -ne check, not if ($topTextY), because 0 is falsy fr fr
                    if ($null -ne $topTextY) {
                        $topY = $topTextY
                    }
                    else {
                        $topY = $fontSize
                    }
                    & $drawOutlinedText $topText ($image.Width / 2) $topY ([System.Drawing.StringAlignment]::Center) $true
                }

                if (-not [string]::IsNullOrWhiteSpace($bottomText)) {
                    # Use custom Y position if provided (from manual mode), otherwise default
                    # NOTE: use $null -ne check, not if ($bottomTextY), because 0 is falsy fr fr
                    if ($null -ne $bottomTextY) {
                        $bottomY = $bottomTextY
                    }
                    else {
                        $bottomY = $image.Height - ($fontSize * 1.5)
                    }
                    & $drawOutlinedText $bottomText ($image.Width / 2) $bottomY ([System.Drawing.StringAlignment]::Center) $true
                }
            }

            # Save the masterpiece
            $bitmap.Save($outputFile, [System.Drawing.Imaging.ImageFormat]::Png)

            # Cleanup (no memory leaks in this house)
            $graphics.Dispose()
            $bitmap.Dispose()
            $image.Dispose()
            $font.Dispose()
            $penBlack.Dispose()

        }
        catch {
            Write-Error "Meme generation failed: $($_.Exception.Message) (catch these hands)"
            return
        }
    }
    end {
        if (-not $script:newMemeInitOk) { return }
        if (Test-Path $outputFile) {
            # Copy to clipboard (based)
            if (-not $noClipboard) {
                try {
                    $image = [System.Drawing.Image]::FromFile($outputFile)
                    [System.Windows.Forms.Clipboard]::SetImage($image)
                    $image.Dispose()
                    Write-Host "Meme created and " -NoNewline
                    Write-Host "mogged to clipboard" -ForegroundColor Green -NoNewline
                    Write-Host " 🔥"
                }
                catch {
                    Write-Warning "Clipboard copy failed (skill issue): $($_.Exception.Message)"
                }
            }

            Write-Host "Saved to: " -NoNewline -ForegroundColor Cyan
            Write-Host $outputFile -ForegroundColor Gray

            # Open the meme (optional flex)
            try {
                Start-Process $outputFile
            }
            catch {
                # lmao whatever
            }
        }
        else {
            Write-Error "Output file not created (something broke but we ship anyway)"
        }
    }
}
