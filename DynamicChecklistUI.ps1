####################################
# Ticket Notes Creation Script     #
# JSON Checklist Engine            #
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

function Get-ChecklistTemplate {
    param ($TicketType, $ProductType)

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
# DROPDOWNS
# =========================

$TypeNotesDropdown = New-Object System.Windows.Forms.ComboBox
$TypeNotesDropdown.Location = New-Object System.Drawing.Point(10,20)
$TypeNotesDropdown.Size = New-Object System.Drawing.Size(120,20)

$ProductTypeDropdown = New-Object System.Windows.Forms.ComboBox
$ProductTypeDropdown.Location = New-Object System.Drawing.Point(10,80)
$ProductTypeDropdown.Size = New-Object System.Drawing.Size(120,20)

# Populate dropdowns
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
$TypeSelectorGroupBox.Size = New-Object System.Drawing.Size(150,60)
$TypeSelectorGroupBox.Location = New-Object System.Drawing.Point(5,15)
$TypeSelectorGroupBox.Controls.Add($TypeNotesDropdown)

$ProductSelectorGroupBox = New-Object System.Windows.Forms.GroupBox
$ProductSelectorGroupBox.Text = "Product"
$ProductSelectorGroupBox.Size = New-Object System.Drawing.Size(150,60)
$ProductSelectorGroupBox.Location = New-Object System.Drawing.Point(5,85)
$ProductSelectorGroupBox.Controls.Add($ProductTypeDropdown)

# =========================
# GLOBAL STATE
# =========================

$script:Checkboxes = @()

# =========================
# STATIC CHECKLIST CONTAINER
# =========================

$script:ListGroupBox = New-Object System.Windows.Forms.GroupBox
$script:ListGroupBox.Text = "Checklist"
$script:ListGroupBox.Size = New-Object System.Drawing.Size(500,615)
$script:ListGroupBox.Location = New-Object System.Drawing.Point(150,15)
$MainWindow.Controls.Add($script:ListGroupBox)

# =========================
# NOTES SECTION (ONCE)
# =========================

$script:NotesSection = New-Object System.Windows.Forms.TextBox
$script:NotesSection.Multiline = $true
$script:NotesSection.ReadOnly = $true
$script:NotesSection.Size = New-Object System.Drawing.Size(500,615)
$script:NotesSection.Location = New-Object System.Drawing.Point(650,15)
$MainWindow.Controls.Add($script:NotesSection)

# =========================
# BUTTONS (ONCE)
# =========================

$GenerateListButton = New-Object System.Windows.Forms.Button
$GenerateListButton.Text = "Get List"
$GenerateListButton.Location = New-Object System.Drawing.Point(5,160)
$GenerateListButton.Size = New-Object System.Drawing.Size(120,25)

$GenerateNotesButton = New-Object System.Windows.Forms.Button
$GenerateNotesButton.Text = "Get Notes"
$GenerateNotesButton.Location = New-Object System.Drawing.Point(5,190)
$GenerateNotesButton.Size = New-Object System.Drawing.Size(120,25)

$CopyNotesButton = New-Object System.Windows.Forms.Button
$CopyNotesButton.Text = "Copy Notes"
$CopyNotesButton.Location = New-Object System.Drawing.Point(5,220)
$CopyNotesButton.Size = New-Object System.Drawing.Size(120,25)

$MainWindow.Controls.AddRange(@(
    $TypeSelectorGroupBox,
    $ProductSelectorGroupBox,
    $GenerateListButton,
    $GenerateNotesButton,
    $CopyNotesButton
))

# =========================
# GENERATE LIST
# =========================

$GenerateListButton.Add_Click({

    if (-not $TypeNotesDropdown.SelectedItem -or -not $ProductTypeDropdown.SelectedItem) {
        [System.Windows.Forms.MessageBox]::Show("Select both ticket type and product type.")
        return
    }

    $template = Get-ChecklistTemplate `
        -TicketType $TypeNotesDropdown.SelectedItem `
        -ProductType $ProductTypeDropdown.SelectedItem

    if (-not $template) {
        [System.Windows.Forms.MessageBox]::Show("No template found.")
        return
    }

    # Clear old checkboxes safely
    foreach ($cb in $script:Checkboxes) {
        $script:ListGroupBox.Controls.Remove($cb)
        $cb.Dispose()
    }

    $script:Checkboxes = @()

    $script:ListGroupBox.Text = $template.Name

    $yPos = 20

    foreach ($step in $template.Steps) {

        $cb = New-Object System.Windows.Forms.CheckBox
        $cb.Text = $step.Text
        $cb.Tag = $step.Output
        $cb.AutoSize = $true
        $cb.Location = New-Object System.Drawing.Point(10,$yPos)

        $script:ListGroupBox.Controls.Add($cb)
        $script:Checkboxes += $cb

        $yPos += 25
    }
})

# =========================
# GENERATE NOTES
# =========================

$GenerateNotesButton.Add_Click({

    $output = foreach ($cb in $script:Checkboxes) {
        if ($cb.Checked -and $cb.Tag) {
            $cb.Tag
        }
    }

    $script:NotesSection.Text =
        if ($output) { $output -join "`r`n" }
        else { "No options selected." }
})

# =========================
# COPY NOTES
# =========================

$CopyNotesButton.Add_Click({
    if ($script:NotesSection.Text) {
        [System.Windows.Forms.Clipboard]::SetText($script:NotesSection.Text)
    }
})

# =========================
# SHOW UI
# =========================

[void]$MainWindow.ShowDialog()