####################################
# Ticket Notes Creation Script     #
# JSON Checklist Engine            #
# Author: Christopher Pulvermacher #
####################################

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# =========================
# LOAD JSON TEMPLATES
# =========================

$TemplatePath = Join-Path $PSScriptRoot "templates"
$ChecklistTemplates = @{}

Get-ChildItem $TemplatePath -Filter *.json | ForEach-Object {

    $json = Get-Content $_.FullName -Raw | ConvertFrom-Json

    foreach ($key in $json.PSObject.Properties.Name) {
        $ChecklistTemplates[$key] = $json.$key
    }
}

# =========================
# HELPER: RESOLVE TEMPLATE
# =========================

function Get-ChecklistTemplate {
    param (
        [string]$TicketType,
        [string]$ProductType
    )

    $key = "${TicketType}_${ProductType}"
    return $ChecklistTemplates[$key]
}

# =========================
# MAIN WINDOW
# =========================

$MainWindow = New-Object System.Windows.Forms.Form
$MainWindow.Text = "Ticket Notes Program"
$MainWindow.Size = New-Object System.Drawing.Size(1200,800)
$MainWindow.StartPosition = "CenterScreen"
$MainWindow.TopMost = $true

# =========================
# DROPDOWNS (TYPE + PRODUCT)
# =========================

$TypeNotesDropdown = New-Object System.Windows.Forms.ComboBox
$TypeNotesDropdown.Location = New-Object System.Drawing.Point(10,20)
$TypeNotesDropdown.Size = New-Object System.Drawing.Size(100,20)

$ProductTypeDropdown = New-Object System.Windows.Forms.ComboBox
$ProductTypeDropdown.Location = New-Object System.Drawing.Point(10,20)
$ProductTypeDropdown.Size = New-Object System.Drawing.Size(100,20)

# Populate dropdowns dynamically from JSON keys
$ChecklistTemplates.Keys | ForEach-Object {

    $parts = $_ -split "_"

    if ($parts.Count -eq 2) {

        if ($TypeNotesDropdown.Items -notcontains $parts[0]) {
            [void]$TypeNotesDropdown.Items.Add($parts[0])
        }

        if ($ProductTypeDropdown.Items -notcontains $parts[1]) {
            [void]$ProductTypeDropdown.Items.Add($parts[1])
        }
    }
}

$TypeSelectorGroupBox = New-Object System.Windows.Forms.GroupBox
$TypeSelectorGroupBox.Text = "Ticket Type"
$TypeSelectorGroupBox.Size = New-Object System.Drawing.Size(120,60)
$TypeSelectorGroupBox.Location = New-Object System.Drawing.Point(5,15)
$TypeSelectorGroupBox.Controls.Add($TypeNotesDropdown)

$ProductSelectorGroupBox = New-Object System.Windows.Forms.GroupBox
$ProductSelectorGroupBox.Text = "Product"
$ProductSelectorGroupBox.Size = New-Object System.Drawing.Size(120,60)
$ProductSelectorGroupBox.Location = New-Object System.Drawing.Point(5,80)
$ProductSelectorGroupBox.Controls.Add($ProductTypeDropdown)

# =========================
# GLOBAL STATE
# =========================

$script:Checkboxes = @()
$script:NotesSection = $null

# =========================
# GET LIST BUTTON
# =========================

$GenerateListButton = New-Object System.Windows.Forms.Button
$GenerateListButton.Text = "Get List"
$GenerateListButton.Location = New-Object System.Drawing.Point(5,150)
$GenerateListButton.Size = New-Object System.Drawing.Size(75,25)

$GenerateListButton.Add_Click({

    # Clear old UI
    $MainWindow.Controls | Where-Object { $_.Tag -eq "Dynamic" } | ForEach-Object {
        $MainWindow.Controls.Remove($_)
    }

    if (!$TypeNotesDropdown.SelectedItem -or !$ProductTypeDropdown.SelectedItem) {
        [System.Windows.Forms.MessageBox]::Show("Select both ticket type and product type.")
        return
    }

    # Resolve template
    $template = Get-ChecklistTemplate `
        -TicketType $TypeNotesDropdown.SelectedItem `
        -ProductType $ProductTypeDropdown.SelectedItem

    if (-not $template) {
        [System.Windows.Forms.MessageBox]::Show("No template found for selection.")
        return
    }

    # Checklist container
    $ListGroupBox = New-Object System.Windows.Forms.GroupBox
    $ListGroupBox.Text = $template.Name
    $ListGroupBox.Size = New-Object System.Drawing.Size(500,615)
    $ListGroupBox.Location = New-Object System.Drawing.Point(150,15)
    $ListGroupBox.Tag = "Dynamic"

    # Notes box
    $script:NotesSection = New-Object System.Windows.Forms.TextBox
    $script:NotesSection.Multiline = $true
    $script:NotesSection.ReadOnly = $true
    $script:NotesSection.Size = New-Object System.Drawing.Size(500,615)
    $script:NotesSection.Location = New-Object System.Drawing.Point(650,15)
    $script:NotesSection.Tag = "Dynamic"

    # Reset state
    $script:Checkboxes = @()

    $yPos = 15

    # =========================
    # BUILD CHECKBOXES FROM JSON
    # =========================

    foreach ($step in $template.Steps) {

        $cb = New-Object System.Windows.Forms.CheckBox
        $cb.Text = $step.Text
        $cb.Tag  = $step.Output
        $cb.AutoSize = $true
        $cb.Location = New-Object System.Drawing.Point(5,$yPos)

        $ListGroupBox.Controls.Add($cb)
        $script:Checkboxes += $cb

        $yPos += $cb.Height + 5
    }

    # =========================
    # SELECT ALL
    # =========================

    $SelectAllCheckbox = New-Object System.Windows.Forms.CheckBox
    $SelectAllCheckbox.Text = "Select All"
    $SelectAllCheckbox.Location = New-Object System.Drawing.Point(5,225)

    $SelectAllCheckbox.Add_CheckedChanged({
        foreach ($cb in $script:Checkboxes) {
            $cb.Checked = $SelectAllCheckbox.Checked
        }
    })

    $ListGroupBox.Controls.Add($SelectAllCheckbox)

    # =========================
    # GENERATE NOTES
    # =========================

    $GenerateNotesButton = New-Object System.Windows.Forms.Button
    $GenerateNotesButton.Text = "Get Notes"
    $GenerateNotesButton.Location = New-Object System.Drawing.Point(5,180)
    $GenerateNotesButton.Size = New-Object System.Drawing.Size(75,25)

    $GenerateNotesButton.Add_Click({

        $output = foreach ($cb in $script:Checkboxes) {

            if ($cb.Checked -and -not [string]::IsNullOrWhiteSpace($cb.Tag)) {
                $cb.Tag
            }
        }

        $script:NotesSection.Text =
            if ($output) { $output -join "`r`n" }
            else { "No options selected." }
    })

    # =========================
    # COPY BUTTON
    # =========================

    $CopyNotesButton = New-Object System.Windows.Forms.Button
    $CopyNotesButton.Text = "Copy Notes"
    $CopyNotesButton.Location = New-Object System.Drawing.Point(5,210)
    $CopyNotesButton.Size = New-Object System.Drawing.Size(75,25)

    $CopyNotesButton.Add_Click({
        if ($script:NotesSection.Text) {
            [System.Windows.Forms.Clipboard]::SetText($script:NotesSection.Text)
        }
    })

    # =========================
    # ADD TO UI
    # =========================

    $MainWindow.Controls.AddRange(@(
        $ListGroupBox,
        $script:NotesSection,
        $GenerateNotesButton,
        $CopyNotesButton
    ))
})

# =========================
# ADD STATIC UI
# =========================

$MainWindow.Controls.AddRange(@(
    $TypeSelectorGroupBox,
    $ProductSelectorGroupBox,
    $GenerateListButton
))

[void]$MainWindow.ShowDialog()