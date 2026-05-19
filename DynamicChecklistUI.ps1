Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# =========================
# LOAD ALL TEMPLATE FILES
# =========================

$TemplatePath = Join-Path $PSScriptRoot "templates"

# Structure:
# $ChecklistTemplates[Category][TemplateKey]
$ChecklistTemplates = @{}

Get-ChildItem $TemplatePath -Filter *.json | ForEach-Object {

    $category = $_.BaseName   # Setup / Deployment / Return

    $json = Get-Content $_.FullName -Raw | ConvertFrom-Json

    if (-not $ChecklistTemplates.ContainsKey($category)) {
        $ChecklistTemplates[$category] = @{}
    }

    foreach ($key in $json.PSObject.Properties.Name) {
        $ChecklistTemplates[$category][$key] = $json.$key
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
# CATEGORY DROPDOWN
# =========================

$CategoryDropdown = New-Object System.Windows.Forms.ComboBox
$CategoryDropdown.Location = New-Object System.Drawing.Point(10,20)
$CategoryDropdown.Size = New-Object System.Drawing.Size(150,25)
$CategoryDropdown.DropDownStyle = "DropDownList"

foreach ($cat in $ChecklistTemplates.Keys) {
    [void]$CategoryDropdown.Items.Add($cat)
}

# =========================
# TEMPLATE DROPDOWN
# =========================

$TemplateDropdown = New-Object System.Windows.Forms.ComboBox
$TemplateDropdown.Location = New-Object System.Drawing.Point(170,20)
$TemplateDropdown.Size = New-Object System.Drawing.Size(250,25)
$TemplateDropdown.DropDownStyle = "DropDownList"

# When category changes → populate templates
$CategoryDropdown.Add_SelectedIndexChanged({

    $TemplateDropdown.Items.Clear()

    $selectedCategory = $CategoryDropdown.SelectedItem

    foreach ($templateKey in $ChecklistTemplates[$selectedCategory].Keys) {
        [void]$TemplateDropdown.Items.Add($templateKey)
    }
})

# =========================
# CHECKLIST UI
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

$LoadButton = New-Object System.Windows.Forms.Button
$LoadButton.Text = "Load Checklist"
$LoadButton.Location = New-Object System.Drawing.Point(430,20)

$NotesButton = New-Object System.Windows.Forms.Button
$NotesButton.Text = "Get Notes"
$NotesButton.Location = New-Object System.Drawing.Point(560,20)

$CopyButton = New-Object System.Windows.Forms.Button
$CopyButton.Text = "Copy"
$CopyButton.Location = New-Object System.Drawing.Point(690,20)

$MainWindow.Controls.AddRange(@(
    $CategoryDropdown,
    $TemplateDropdown,
    $LoadButton,
    $NotesButton,
    $CopyButton
))

# =========================
# LOAD CHECKLIST
# =========================

$LoadButton.Add_Click({

    if (-not $CategoryDropdown.SelectedItem -or -not $TemplateDropdown.SelectedItem) {
        [System.Windows.Forms.MessageBox]::Show("Select category and template.")
        return
    }

    $category = $CategoryDropdown.SelectedItem
    $templateKey = $TemplateDropdown.SelectedItem

    $template = $ChecklistTemplates[$category][$templateKey]

    if (-not $template) {
        [System.Windows.Forms.MessageBox]::Show("Template not found.")
        return
    }

    $script:SelectedTemplate = $template

    # clear old checkboxes
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
# COPY
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