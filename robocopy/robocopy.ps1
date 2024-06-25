Add-Type -AssemblyName System.Windows.Forms

<# Pour convertir en executable modifier $script_dir = split-path -parent $MyInvocation.MyCommand.Definition en :
 
    $currentExePath = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
    $script_dir = split-path -parent $currentExePath
#>

# Recuperation des dossiers AppData dans fichier texte
$script_dir = split-path -parent $MyInvocation.MyCommand.Definition
$appdata_directories = Get-Content -Path "$script_dir\default_appdata.txt"
# Dossier à selectionner par défaut
$checkedArray = Get-Content -Path "$script_dir\default.txt"


# Fontion de sauvegarde
function Backup-Directories {
    param (
        [string]$backupDir,
        $selectedItems,
        $username
    )
    $sourceDir = "C:\Users\$username"
    
    foreach ($directory_full in $selectedItems) {

            # Récupération du nom du dossier
            $directory = $directory_full.Split("~~~~")[0]

            # Gestion pour Appdata (small)
            if($directory -eq "AppData (small)"){
                foreach($app_dir in $appdata_directories){
                    $sourcePath = Join-Path $sourceDir "AppData\$app_dir"
                    $destPath = Join-Path $backupDir "AppData\$app_dir"

                    if (Test-Path $sourcePath) {

                        # Ajout d'une barre de progression
                        $index = [Array]::IndexOf($appdata_directories, $app_dir)
                        Write-Progress -PercentComplete ($index/$appdata_directories.Count*100)  -Activity "Sauvegarde de $directory" -Status "Sauvegarde de $sourcePath dans $destPath"
                       
                        # Sauvegarde de $sourcePath dans $destPath
                        robocopy "$sourcePath" "$destPath" /E /COPY:DAT /R:1 /W:1 /log+:"$backupDir\robocopy.log"
                        
                    } else {
                        Write-Output "The directory $sourcePath does not exist."
                    }

                }
            }else{
                
                $sourcePath = Join-Path $sourceDir $directory
                $destPath = Join-Path $backupDir $directory
                
                # Ajout d'une barre de progression
                $index = [Array]::IndexOf($selectedItems, $directory_full)
                Write-Progress -PercentComplete ($index/$selectedItems.Count*100)  -Activity "Sauvegarde de $directory" -Status "Sauvegarde de $sourcePath dans $destPath"

                # Sauvegarde des fichiers
                if(Test-path -Path $sourcePath -pathtype leaf){

                    # Sauvegarde de $sourcePath dans $destPath"
                    robocopy "$sourceDir" "$backupDir" "$directory" /E /COPY:DAT /R:1 /W:1 /XD * /log+:"$backupDir\robocopy.log"

                # Sauvegarde des dossiers
                }else{
                    if (Test-Path $sourcePath) {

                        # Sauvegarde de $sourcePath dans $destPath"
                        robocopy "$sourcePath" "$destPath" /E /COPY:DAT /R:1 /W:1 /log+:"$backupDir\robocopy.log"
                    
                    } else {
                        Write-Output "The directory $sourcePath does not exist."
                    }
                }


            }

    }

    # Stop la barre de progression
    Write-Progress -Completed -Activity "OK"
    Write-Host "Sauvegarde terminée. Sauvegardé dans $backupDir"
}

# Fonction de restauration
function Restore-Directories {
    param (
        [string]$backupDir,
        $username
    )
    $destDir = "C:\Users\$username"
    $restoreDir = Get-ChildItem -Path $backupDir -Force
    
    foreach ($directory in $restoreDir) {

            $sourcePath = Join-Path $backupDir $directory
            $destPath = Join-Path $destDir $directory
                
            # Ajout d'une barre de progression
            $index = [Array]::IndexOf($restoreDir, $directory)
            Write-Progress -PercentComplete ($index/$restoreDir.Count*100)  -Activity "Restauration de $directory" -Status "Restauration de $sourcePath dans $destPath"

            # Dossiers
            if(Test-path -Path $sourcePath -pathtype leaf){

                # Sauvegarde de $sourcePath dans $destPath
                robocopy "$backupDir" "$destDir" "$directory" /E /COPY:DAT /R:1 /W:1 /XD * /log+:"$backupDir\robocopy.log"

            # Fichiers
            }else{
                if (Test-Path $sourcePath) {
                    # Restauration de $sourcePath dans $destPath
                    robocopy "$sourcePath" "$destPath" /E /COPY:DAT /R:1 /W:1
                
                } else {
                    Write-Output "The directory $sourcePath does not exist."
                }
            }
    }
    Write-Progress -Completed -Activity "OK"
    Write-Host "Restauration terminée. Restauré dans $destDir"
}

# Fonction qui permet de selectionner le dossier cible
function Browse-BackupDir {
    $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    if ($folderBrowser.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $backupDirEntry.Text = $folderBrowser.SelectedPath
    }
}

# Verifie si il faut les permissions admin pour acceder au dossier
function Check-AdminRights {
    param (
        [string]$folderPath
    )
    try {
        # Tentaive de recupereation des dossier
        $items = Get-ChildItem -Path $folderPath -ErrorAction Stop
        return $false
    } catch {
        # Si il y a une erreur on estime qu'il s'agit d'un manque de permission
        return $true
    }
}


function Update-Folders {
    
    param(
        $checkList,
        $username
    )

    $checkList.Items.Clear()

    # Recupération des Dossiers et Fichiers
    $selectedDirectories = @{}
    $userDir = "C:\Users\$username"
    $existingDirectories = Get-ChildItem -Path $userDir -Directory -Force | Where-Object { -not ($_.Attributes -match "ReparsePoint") } 
    $existingFiles = Get-ChildItem -Path $userDir -File -Force | Where-Object { -not ($_.Attributes -match "ReparsePoint") }

    # Ajout dossiers AppData
    $appdata_size = 0

    foreach($directory in $appdata_directories){
        $full_dir = "$userDir\AppData\$directory"

        if(Test-Path -Path $full_dir){
            $size = (Get-ChildItem -Path $full_dir -File -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
            $appdata_size += $size
        }
    }

    $appdata_size_MB = $appdata_size / 1MB
    $appdata_size_MB = [Math]::Round($appdata_size_MB,2)

    [void]$checkList.Items.Add("AppData (small)~~~~$appdata_size_MB Mo")
    $index = [Array]::IndexOf($checkList.Items, "AppData (small)~~~~$appdata_size_MB Mo")
    $checkList.SetItemChecked($index,$true)


    #Ajout Dossiers
    foreach ($directory in $existingDirectories) {

        $index = [Array]::IndexOf($existingDirectories, $directory)
        
        Write-Progress -PercentComplete ($index/$existingDirectories.Count*100) -Activity "Récupération de données de l'utilisateur $username" -Status "Récupération de $directory"

        $requiresAdmin = Check-AdminRights -folderPath $directory.FullName

        if(-not $requiresAdmin){

            try{
                $size = (Get-ChildItem -Path $directory.FullName -File -Recurse -ErrorAction SilentlyContinue| Measure-Object -Property Length -Sum).Sum
                $sizeInMB = $size / 1MB
                $sizeInMB = [Math]::Round($sizeInMB,2)

                [void]$checkList.Items.Add("$directory~~~~$sizeInMB Mo")
                if($checkedArray.Contains($directory.Name)){
                    $index = [Array]::IndexOf($checkList.Items, "$directory~~~~$sizeInMB Mo")
                    $checkList.SetItemChecked($index,$true)
                }
            }catch{
                
            }
        }
    }


    #Ajout Fichiers
    foreach ($file in $existingFiles) {
        $index = [Array]::IndexOf($existingFiles, $file)
        
        Write-Progress -PercentComplete ($index/$existingFiles.Count*100) -Activity "Récupération de données de l'utilisateur $username" -Status "Récupération de $file"

            $size = $file.length
            $sizeInMB = $size / 1MB
            $sizeInMB = [Math]::Round($sizeInMB,2)

            [void]$checkList.Items.Add("$file~~~~$sizeInMB Mo")
            if($checkedArray.Contains($file.Name)){
                $index = [Array]::IndexOf($checkList.Items, "$file~~~~$sizeInMB Mo")
                $checkList.SetItemChecked($index,$true)
        }
    }
    Write-Progress -Completed -Activity "OK"
    Write-Host "Données récupérées avec succés" 
}

# Creation du formulaire
$form = New-Object System.Windows.Forms.Form
$form.Text = "Sauvegarde et Restauration de fichiers"
$form.Size = New-Object System.Drawing.Size(500, 410)
$form.StartPosition = "CenterScreen"

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

$checkList = New-Object System.Windows.Forms.CheckedListBox
$checkList.Name = "CheckList"
$checkList.Location = New-Object System.Drawing.Point(10, 60)
$checkList.Size = New-Object System.Drawing.Size(460, 250)
$checkList.CheckOnClick = $true

$form.Controls.Add($checkList)

#Bouton sauvegarder
$backupButton = New-Object System.Windows.Forms.Button
$backupButton.Text = "Sauvegarder"
$backupButton.Location = New-Object System.Drawing.Point(10, 320)
$backupButton.Size = New-Object System.Drawing.Point(100, 30)
$backupButton.Add_Click({
    $selectedItems = $form.Controls["CheckList"].CheckedItems
    $backupDir = $backupDirEntry.Text

    if($backupDir -and $chooseUser.SelectedItem){
        Backup-Directories -backupDir $backupDir -selectedItems $selectedItems -username $chooseUser.SelectedItem
    }else {
        [System.Windows.Forms.MessageBox]::Show("Veuillez remplir tous les champs !")
    }
})
$form.Controls.Add($backupButton)

# Bouton restaurer
$restoreButton = New-Object System.Windows.Forms.Button
$restoreButton.Text = "Restaurer"
$restoreButton.Location = New-Object System.Drawing.Point(120, 320)
$restoreButton.Size = New-Object System.Drawing.Point(100, 30)
$restoreButton.Add_Click({
    $backupDir = $backupDirEntry.Text
    Restore-Directories -backupDir $backupDir -username $chooseUser.SelectedItem

    if($backupDir -and $chooseUser.SelectedItem){
        Restore-Directories -backupDir $backupDir -username $chooseUser.SelectedItem
    }else {
        [System.Windows.Forms.MessageBox]::Show("Veuillez remplir tous les champs !")
    }
})
$form.Controls.Add($restoreButton)

$userLabel = New-Object System.Windows.Forms.Label
$userLabel.Text = "Choisir l'utilisateur"
$userLabel.Location = New-Object System.Drawing.Point(260, 310)
$userLabel.Size = New-Object System.Drawing.Point(150, 20)
$form.Controls.Add($userLabel)

$chooseUser = New-Object System.Windows.Forms.ComboBox
$chooseUser.Name = "User"
$chooseUser.Location = New-Object System.Drawing.Point(260, 330)
$chooseUser.Size = New-Object System.Drawing.Point(150, 20)
$form.Controls.Add($chooseUser)

$current_user = $Env:UserName

$users = Get-ChildItem -Path C:\Users -Directory
foreach($user in $users){
    [void]$chooseUser.Items.Add($user)

    if("$user" -eq $current_user){
        $chooseUser.SelectedItem = $user
        Update-Folders -checkList $checkList -username $chooseUser.SelectedItem
    }
}

$chooseUser.Add_SelectedIndexChanged({
    Update-Folders -checkList $checkList -username $chooseUser.SelectedItem
})

# Affichage du formulaire
$form.Add_Shown({ $form.Activate() })
[void] $form.ShowDialog()
