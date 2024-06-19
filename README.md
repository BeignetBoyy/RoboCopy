# RoboCopy

A tool to Save and Restore data from your C:\Users\<username> using RoboCopy

# ⚠ Disclaimer ⚠ :

Be warned this tool was made only by myself with a fairly limited knowledge of PowerShell as such don't be surprised if errors happen.
Make sure to make a backup of your data before you use this tool, if you lose any data by using this I won't take any accountability.

# How To Use :

Launch robocopy.exe

Wait for the data to be recovered 

When the window opens, select a directory from which to save or restore at the top of the window

Check which file or directory you want to save.
By default the following directories are checked :
 - Documents
 - Downloads
 - Desktop
 - Pictures

If you want to add default directories you can add them in default.txt

In addition those, one of the directory checked by default that you can select is AppData (small). 
It is a version of AppData that will only contain the directories in default_appdata.txt.
It was added because of the long time it took to save the entire AppData folder. 
If you want to add default AppData directories you can add them in default_appdata.txt

The size of each folder/file is written next to it in Mb. 
As the value is rounded some folders or files may be displayed as empty even tho they have data in them.

Once you think you've checked everything, just click on the Save button and everything you've checked will be copied from you C:\Users\<username> to the selected folder 

If you restore data, no matter what directories/files you have checked, everything will be restored from the selected folder to your C:\Users\<username>

# Added details :

This tool won't save data from folders or files that need admin privileges to be read.
The full code is inside robocopy.ps1, if you ever want to edit it go ahead but make sure to credit me if you post it online.
If you want to recompile as an exe after editing it here is how i've managed to do it :

Replace this line : 
```
$script_dir = split-path -parent $MyInvocation.MyCommand.Definition
```
By these two :
```
$currentExePath = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
$script_dir = split-path -parent $currentExePath
```

Then compile the script into an executable whichever way you want (i used win-ps2exe)
Once complete, change the line back to what it was (so you can run the script itself if you want)
