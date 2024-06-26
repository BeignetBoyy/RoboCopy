Add-Type -AssemblyName System.Windows.Forms

<# To compile the script into an exe change this line 

    $script_dir = split-path -parent $MyInvocation.MyCommand.Definition 
    
    with these two :
 
    $currentExePath = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
    $script_dir = split-path -parent $currentExePath
#>

$script_dir = split-path -parent $MyInvocation.MyCommand.Definition

# Getting the list of default appdata folders from file
$appdata_directories = Get-Content -Path "$script_dir\default_appdata.txt"
# Getting the list of default folders from file
$checkedArray = Get-Content -Path "$script_dir\default.txt"


# Save function
function Backup-Directories {
    param (
        [string]$backupDir,
        $selectedItems,
        $username
    )
    $sourceDir = "C:\Users\$username"
    
    foreach ($directory_full in $selectedItems) {

            # Getting the directory/file name (FolderName~~~~FolderSize --> FolderName)
            $directory = $directory_full.Split("~~~~")[0]

            # Manages save for Default appdata folders
            if($directory -eq "AppData (small)"){
                foreach($app_dir in $appdata_directories){
                    $sourcePath = Join-Path $sourceDir "AppData\$app_dir"
                    $destPath = Join-Path $backupDir "AppData\$app_dir"

                    if (Test-Path $sourcePath) {

                        # Adding a progress bar
                        $index = [Array]::IndexOf($appdata_directories, $app_dir)
                        Write-Progress -PercentComplete ($index/$appdata_directories.Count*100)  -Activity "Saving $directory" -Status "Saving $sourcePath into $destPath"
                       
                        # Saved $sourcePath into $destPath
                        robocopy "$sourcePath" "$destPath" /E /COPY:DAT /R:1 /W:1 /log+:"$backupDir\robocopy.log"
                        
                    } else {
                        Write-Output "The directory $sourcePath does not exist."
                    }

                }
            }else{
                
                $sourcePath = Join-Path $sourceDir $directory
                $destPath = Join-Path $backupDir $directory
                
                # Adding a progress bar
                $index = [Array]::IndexOf($selectedItems, $directory_full)
                Write-Progress -PercentComplete ($index/$selectedItems.Count*100)  -Activity "Saving $directory" -Status "Saving $sourcePath into $destPath"

                # Saving files
                if(Test-path -Path $sourcePath -pathtype leaf){

                    # Saved $sourcePath into $destPath"
                    robocopy "$sourceDir" "$backupDir" "$directory" /E /COPY:DAT /R:1 /W:1 /XD * /log+:"$backupDir\robocopy.log"

                # Saving directories
                }else{
                    if (Test-Path $sourcePath) {

                        # Saved $sourcePath into $destPath"
                        robocopy "$sourcePath" "$destPath" /E /COPY:DAT /R:1 /W:1 /log+:"$backupDir\robocopy.log"
                    
                    } else {
                        Write-Output "The directory $sourcePath does not exist."
                    }
                }


            }

    }

    # Stops the progress bar
    Write-Progress -Completed -Activity "OK"
    Write-Host "Save complete. Saved into $backupDir"
}

# Restore function
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
                
            # Adding a progress bar
            $index = [Array]::IndexOf($restoreDir, $directory)
            Write-Progress -PercentComplete ($index/$restoreDir.Count*100)  -Activity "Restoring $directory" -Status "Restoring $sourcePath into $destPath"

            # Directories
            if(Test-path -Path $sourcePath -pathtype leaf){

                # Restored $sourcePath into $destPath
                robocopy "$backupDir" "$destDir" "$directory" /E /COPY:DAT /R:1 /W:1 /XD * /log+:"$backupDir\robocopy.log"

            # Files
            }else{
                if (Test-Path $sourcePath) {
                    # Restored $sourcePath into $destPath
                    robocopy "$sourcePath" "$destPath" /E /COPY:DAT /R:1 /W:1
                
                } else {
                    Write-Output "The directory $sourcePath does not exist."
                }
            }
    }
    Write-Progress -Completed -Activity "OK"
    Write-Host "Restoration completed. Restored into $destDir"
}

# Selects the target directory from the File browser
function Browse-BackupDir {
    $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    if ($folderBrowser.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $backupDirEntry.Text = $folderBrowser.SelectedPath
    }
}

# Checks if admin privileges are needed to access the folder
function Check-AdminRights {
    param (
        [string]$folderPath
    )
    try {
        # Attempt to access the folder
        $items = Get-ChildItem -Path $folderPath -ErrorAction Stop
        return $false
    } catch {
        # In case of an error we assume it was due to a lack of admin rights
        return $true
    }
}

# Updates the list of folders depending on the selected user
function Update-Folders {
    
    param(
        $checkList,
        $username
    )

    $checkList.Items.Clear()

    # Getting Files and Folders
    $selectedDirectories = @{}
    $userDir = "C:\Users\$username"
    $existingDirectories = Get-ChildItem -Path $userDir -Directory -Force | Where-Object { -not ($_.Attributes -match "ReparsePoint") } 
    $existingFiles = Get-ChildItem -Path $userDir -File -Force | Where-Object { -not ($_.Attributes -match "ReparsePoint") }

    # Adding default AppData folders
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

    [void]$checkList.Items.Add("AppData (small)~~~~$appdata_size_MB Mb")
    $index = [Array]::IndexOf($checkList.Items, "AppData (small)~~~~$appdata_size_MB Mb")
    $checkList.SetItemChecked($index,$true)


    # Adding Folders
    foreach ($directory in $existingDirectories) {

        $index = [Array]::IndexOf($existingDirectories, $directory)
        
        Write-Progress -PercentComplete ($index/$existingDirectories.Count*100) -Activity "Reading data of user $username" -Status "Current folder : $directory"

        $requiresAdmin = Check-AdminRights -folderPath $directory.FullName

        if(-not $requiresAdmin){

            try{
                $size = (Get-ChildItem -Path $directory.FullName -File -Recurse -ErrorAction SilentlyContinue| Measure-Object -Property Length -Sum).Sum
                $sizeInMB = $size / 1MB
                $sizeInMB = [Math]::Round($sizeInMB,2)

                [void]$checkList.Items.Add("$directory~~~~$sizeInMB Mb")
                if($checkedArray.Contains($directory.Name)){
                    $index = [Array]::IndexOf($checkList.Items, "$directory~~~~$sizeInMB Mb")
                    $checkList.SetItemChecked($index,$true)
                }
            }catch{
                
            }
        }
    }


    # Adding files
    foreach ($file in $existingFiles) {
        $index = [Array]::IndexOf($existingFiles, $file)
        
        Write-Progress -PercentComplete ($index/$existingFiles.Count*100) -Activity "Reading data of user $username" -Status "Current file : $file"

            $size = $file.length
            $sizeInMB = $size / 1MB
            $sizeInMB = [Math]::Round($sizeInMB,2)

            [void]$checkList.Items.Add("$file~~~~$sizeInMB Mb")
            if($checkedArray.Contains($file.Name)){
                $index = [Array]::IndexOf($checkList.Items, "$file~~~~$sizeInMB Mb")
                $checkList.SetItemChecked($index,$true)
        }
    }
    Write-Progress -Completed -Activity "OK"
    Write-Host "Data obtained succesfuly" 
}

# Creating form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Backup and Restoration of files and folders"
$form.Size = New-Object System.Drawing.Size(500, 410)
$form.StartPosition = "CenterScreen"

$backupDirLabel = New-Object System.Windows.Forms.Label
$backupDirLabel.Text = "Target Directory:"
$backupDirLabel.Location = New-Object System.Drawing.Point(10, 20)
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

# Save button
$backupButton = New-Object System.Windows.Forms.Button
$backupButton.Text = "Save"
$backupButton.Location = New-Object System.Drawing.Point(10, 320)
$backupButton.Size = New-Object System.Drawing.Point(100, 30)
$backupButton.Add_Click({
    $selectedItems = $form.Controls["CheckList"].CheckedItems
    $backupDir = $backupDirEntry.Text

    if($backupDir -and $chooseUser.SelectedItem){
        Backup-Directories -backupDir $backupDir -selectedItems $selectedItems -username $chooseUser.SelectedItem
    }else {
        [System.Windows.Forms.MessageBox]::Show("Please fill in all fields !")
    }
})
$form.Controls.Add($backupButton)

# Restore button
$restoreButton = New-Object System.Windows.Forms.Button
$restoreButton.Text = "Restore"
$restoreButton.Location = New-Object System.Drawing.Point(120, 320)
$restoreButton.Size = New-Object System.Drawing.Point(100, 30)
$restoreButton.Add_Click({
    $backupDir = $backupDirEntry.Text

    if($backupDir -and $chooseUser.SelectedItem){
        Restore-Directories -backupDir $backupDir -username $chooseUser.SelectedItem
    }else {
        [System.Windows.Forms.MessageBox]::Show("Please fill in all fields !")
    }
})
$form.Controls.Add($restoreButton)

$userLabel = New-Object System.Windows.Forms.Label
$userLabel.Text = "Choose user"
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

# Show form
$form.Add_Shown({ $form.Activate() })
[void] $form.ShowDialog()
