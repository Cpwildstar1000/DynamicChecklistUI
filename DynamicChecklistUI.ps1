####################################
# Ticket Notes Script (JSON Engine)
####################################

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# =========================
# LOAD ALL TEMPLATES
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
# MAIN FORM
# =========================

$MainWindow = New-Object System.Windows.Forms.Form
$MainWindow.Text = "Ticket Notes Program"
$MainWindow.Size = New-Object System.Drawing.Size(1200,800)
$MainWindow.StartPosition = "CenterScreen"

# =========================
# GLOBAL STATE
# =========================

$script:Checkboxes = @()
$script:SelectedTemplate = $null

# =========================
# TEMPLATE DROPDOWN
# =========================

$TemplateDropdown = New-Object System.Windows.Forms.ComboBox
$TemplateDropdown.Location = New-Object System.Drawing.Point(10,20)
$TemplateDropdown.Size = New-Object System.Drawing.Size(300,25)
$TemplateDropdown.DropDownStyle = "DropDownList"

foreach ($key in $ChecklistTemplates.Keys) {
    [void]$TemplateDropdown.Items.Add($key)
}

# =========================
# GROUPBOX (CHECKLIST)
# =========================

$script:ListGroupBox = New-Object System.Windows.Forms.GroupBox
$script:ListGroupBox.Text = "Checklist"
$script:ListGroupBox.Size = New-Object System.Drawing.Size(500,700)
$script:ListGroupBox.Location = New-Object System.Drawing.Point(10,60)
$MainWindow.Controls.Add($script:ListGroupBox)

# =========================
# NOTES BOX
# =========================

$script:NotesSection = New-Object System.Windows.Forms.TextBox
$script:NotesSection.Multiline = $true
$script:NotesSection.ReadOnly = $true
$script:NotesSection.ScrollBars = "Vertical"
$script:NotesSection.Size = New-Object System.Drawing.Size(600,700)
$script:NotesSection.Location = New-Object System.Drawing.Point(520,60)
$MainWindow.Controls.Add($script:NotesSection)

# =========================
# BUTTONS
# =========================

$GenerateButton = New-Object System.Windows.Forms.Button
$GenerateButton.Text = "Load Checklist"
$GenerateButton.Location = New-Object System.Drawing.Point(320,20)
$GenerateButton.Size = New-Object System.Drawing.Size(120,25)

$NotesButton = New-Object System.Windows.Forms.Button
$NotesButton.Text = "Generate Notes"
$NotesButton.Location = New-Object System.Drawing.Point(450,20)
$NotesButton.Size = New-Object System.Drawing.Size(120,25)

$CopyButton = New-Object System.Windows.Forms.Button
$CopyButton.Text = "Copy"
$CopyButton.Location = New-Object System.Drawing.Point(580,20)
$CopyButton.Size = New-Object System.Drawing.Size(80,25)

$MainWindow.Controls.AddRange(@(
    $TemplateDropdown,
    $GenerateButton,
    $NotesButton,
    $CopyButton
))

# =========================
# LOAD CHECKLIST
# =========================

$GenerateButton.Add_Click({

    if (-not $TemplateDropdown.SelectedItem) {
        [System.Windows.Forms.MessageBox]::Show("Select a template.")
        return
    }

    $templateKey = $TemplateDropdown.SelectedItem
    $template = $ChecklistTemplates[$templateKey]

    if (-not $template) {
        [System.Windows.Forms.MessageBox]::Show("Template not found.")
        return
    }

    $script:SelectedTemplate = $template

    # Clear old checkboxes
    foreach ($cb in $script:Checkboxes) {
        $script:ListGroupBox.Controls.Remove($cb)
        $cb.Dispose()
    }

    $script:Checkboxes = @()

    $script:ListGroupBox.Text = $template.Name

    $y = 25

    foreach ($step in $template.Steps) {

        $cb = New-Object System.Windows.Forms.CheckBox
        $cb.Text = $step.Text
        $cb.Tag = $step.Output
        $cb.AutoSize = $true
        $cb.Location = New-Object System.Drawing.Point(10, $y)

        $script:ListGroupBox.Controls.Add($cb)
        $script:Checkboxes += $cb

        $y += 22
    }
})

# =========================
# GENERATE NOTES
# =========================

$NotesButton.Add_Click({

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

$CopyButton.Add_Click({
    if ($script:NotesSection.Text) {
        [System.Windows.Forms.Clipboard]::SetText($script:NotesSection.Text)
    }
})

# =========================
# RUN
# =========================

[void]$MainWindow.ShowDialog()