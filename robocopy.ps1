Add-Type -AssemblyName System.Windows.Forms

# Default directories to be checked
$checkedArray = "Documents", "Downloads", "Desktop", "Pictures"

# Pour convertir en executable modifier $script_dir = split-path -parent $MyInvocation.MyCommand.Definition en :
# 
# $currentExePath = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
# $script_dir = split-path -parent $currentExePath

# Recuperation des dossiers AppData dans fichier texte
$script_dir = split-path -parent $MyInvocation.MyCommand.Definition
$appdata_directories = Get-Content -Path "$script_dir\default_appdata.txt"
$title = Get-Content -Path "$script_dir\title.txt"

foreach($line in $title){
    Write-Host $line
}


# Function to backup directories
function Backup-Directories {
    param (
        [string]$backupDir,
        $selectedItems
    )
    $username = $Env:UserName
    $sourceDir = "C:\Users\$username"
    
    foreach ($directory in $selectedItems) {

            $directory = $directory.Split("~~~~")[0]

            if($directory -eq "AppData (small)"){
                foreach($app_dir in $appdata_directories){
                    $sourcePath = Join-Path $sourceDir "AppData\$app_dir"
                    $destPath = Join-Path $backupDir "AppData\$app_dir"

                    if (Test-Path $sourcePath) {
                        Write-Host "Sauvegarde de $sourcePath dans $destPath"
                        robocopy "$sourcePath" "$destPath" /E /COPY:DAT /R:1 /W:1 /log+:"$backupDir\robocopy.log"
                        
                    } else {
                        Write-Output "The directory $sourcePath does not exist."
                    }

                }
            }else{
                
                $sourcePath = Join-Path $sourceDir $directory
                $destPath = Join-Path $backupDir $directory
                

                if(Test-path -Path $sourcePath -pathtype leaf){

                    Write-Host "Sauvegarde de $sourcePath dans $destPath"
                    robocopy "$sourceDir" "$backupDir" "$directory" /E /COPY:DAT /R:1 /W:1 /XD * /log+:"$backupDir\robocopy.log"
                }else{
                    if (Test-Path $sourcePath) {

                        Write-Host "Sauvegarde de $sourcePath dans $destPath"
                        robocopy "$sourcePath" "$destPath" /E /COPY:DAT /R:1 /W:1 /log+:"$backupDir\robocopy.log"
                    
                    } else {
                        Write-Output "The directory $sourcePath does not exist."
                    }
                }


            }

    }
    Write-Host "Sauvegarde terminée. Sauvegardé dans $backupDir"
}

# Function to restore directories
function Restore-Directories {
    param (
        [string]$backupDir
    )
    $username = $Env:UserName
    $destDir = "C:\Users\$username"
    $restoreDir = Get-ChildItem -Path $backupDir -Force
    
    foreach ($directory in $restoreDir) {

            $sourcePath = Join-Path $backupDir $directory
            $destPath = Join-Path $destDir $directory

            if(Test-path -Path $sourcePath -pathtype leaf){

                Write-Host "Sauvegarde de $sourcePath dans $destPath"
                robocopy "$backupDir" "$destDir" "$directory" /E /COPY:DAT /R:1 /W:1 /XD * /log+:"$backupDir\robocopy.log"
            }else{
                if (Test-Path $sourcePath) {
                    Write-Host "Restauration de $sourcePath dans $destPath"
                    robocopy "$sourcePath" "$destPath" /E /COPY:DAT /R:1 /W:1
                
                } else {
                    Write-Output "The directory $sourcePath does not exist."
                }
            }
    }
    Write-Host "Restauration terminée. Restauré dans $backupDir"
}

# Function to browse backup directory
function Browse-BackupDir {
    $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    if ($folderBrowser.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $backupDirEntry.Text = $folderBrowser.SelectedPath
    }
}

function Check-AdminRights {
    param (
        [string]$folderPath
    )
    try {
        # Attempt to get the list of items in the folder
        $items = Get-ChildItem -Path $folderPath -ErrorAction Stop
        return $false
    } catch {
        # If an error occurs, assume it's due to lack of permissions
        return $true
    }
}


# Create the form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Sauvegarde et Restauration de fichiers"
$form.Size = New-Object System.Drawing.Size(500, 410)
$form.StartPosition = "CenterScreen"

# Backup directory entry
$backupDirLabel = New-Object System.Windows.Forms.Label
$backupDirLabel.Text = "Backup Directory:"
$backupDirLabel.Location = New-Object System.Drawing.Point(10, 20)
$backupDirLabel.Size = New-Object System.Drawing.Size(120, 20)
$form.Controls.Add($backupDirLabel)

$backupDirEntry = New-Object System.Windows.Forms.TextBox
$backupDirEntry.Location = New-Object System.Drawing.Point(10, 20)
$backupDirLabel.Size = New-Object System.Drawing.Size(120, 20)
$form.Controls.Add($backupDirLabel)

$backupDirEntry = New-Object System.Windows.Forms.TextBox
$backupDirEntry.Location = New-Object System.Drawing.Point(140, 18)
$backupDirEntry.Size = New-Object System.Drawing.Size(230, 20)
$form.Controls.Add($backupDirEntry)

$browseButton = New-Object System.Windows.Forms.Button
$browseButton.Text = "Browse"
$browseButton.Location = New-Object System.Drawing.Point(380, 16)
$browseButton.Add_Click({ Browse-BackupDir })
$form.Controls.Add($browseButton)

# Directories to backup
$selectedDirectories = @{}
$username = $Env:UserName
$userDir = "C:\Users\$username"
$existingDirectories = Get-ChildItem -Path $userDir -Directory -Force | Where-Object { -not ($_.Attributes -match "ReparsePoint") }
$existingFiles = Get-ChildItem -Path $userDir -File -Force | Where-Object { -not ($_.Attributes -match "ReparsePoint") }

$checkList = New-Object System.Windows.Forms.CheckedListBox
$checkList.Name = "CheckList"
$checkList.Location = New-Object System.Drawing.Point(10, 60)
$checkList.Size = New-Object System.Drawing.Size(460, 250)
$checkList.CheckOnClick = $true


# Ajout dossiers AppData
$appdata_size = 0

foreach($directory in $appdata_directories){
    $full_dir = "$userDir\AppData\$directory"

    if(Test-Path -Path $full_dir){
        $size = (Get-ChildItem -Path $full_dir -File -Recurse | Measure-Object -Property Length -Sum).Sum
        $appdata_size += $size
    }
}

$appdata_size_MB = $appdata_size / 1MB
$appdata_size_MB = [Math]::Round($appdata_size_MB,2)

$checkList.Items.Add("AppData (small)~~~~$appdata_size_MB Mo")
$index = [Array]::IndexOf($checkList.Items, "AppData (small)~~~~$appdata_size_MB Mo")
$checkList.SetItemChecked($index,$true)


#Ajout Dossiers
foreach ($directory in $existingDirectories) {

    $requiresAdmin = Check-AdminRights -folderPath $directory.FullName

    if(-not $requiresAdmin){
        $size = (Get-ChildItem -Path $directory.FullName -File -Recurse | Measure-Object -Property Length -Sum).Sum
        $sizeInMB = $size / 1MB
        $sizeInMB = [Math]::Round($sizeInMB,2)

        [void]$checkList.Items.Add("$directory~~~~$sizeInMB Mo")
        if($checkedArray.Contains($directory.Name)){
            $index = [Array]::IndexOf($checkList.Items, "$directory~~~~$sizeInMB Mo")
            $checkList.SetItemChecked($index,$true)
        }
    }
}


#Ajout Fichiers
foreach ($file in $existingFiles) {

        $size = $file.length
        $sizeInMB = $size / 1MB
        $sizeInMB = [Math]::Round($sizeInMB,2)

        [void]$checkList.Items.Add("$file~~~~$sizeInMB Mo")
        if($checkedArray.Contains($file.Name)){
            $index = [Array]::IndexOf($checkList.Items, "$file~~~~$sizeInMB Mo")
            $checkList.SetItemChecked($index,$true)
    }
}

$form.Controls.Add($checkList)

# Start Backup Button
$backupButton = New-Object System.Windows.Forms.Button
$backupButton.Text = "Sauvegarder"
$backupButton.Location = New-Object System.Drawing.Point(10, 320)
$backupButton.Size = New-Object System.Drawing.Point(100, 30)
$backupButton.Add_Click({
    $selectedItems = $form.Controls["CheckList"].CheckedItems
    $backupDir = $backupDirEntry.Text
    Backup-Directories -backupDir $backupDir -selectedItems $selectedItems
})
$form.Controls.Add($backupButton)

# Start Restore Button
$restoreButton = New-Object System.Windows.Forms.Button
$restoreButton.Text = "Restaurer"
$restoreButton.Location = New-Object System.Drawing.Point(120, 320)
$restoreButton.Size = New-Object System.Drawing.Point(100, 30)
$restoreButton.Add_Click({
    $backupDir = $backupDirEntry.Text
    Restore-Directories -backupDir $backupDir
})
$form.Controls.Add($restoreButton)

# Show the form
$form.Add_Shown({ $form.Activate() })
[void] $form.ShowDialog()
