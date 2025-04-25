# RoboCopy

A tool to Save and Restore data from your computer using RoboCopy

# ⚠ Disclaimer ⚠ :

Be warned this tool was made only by myself with a fairly limited knowledge of PowerShell as such don't be surprised if errors happen.  
Make sure to make a backup of your data before you use this tool, if you lose any data by using this I won't take any accountability.

# Before Using

Make sure any file you have opened in another window is closed.  
Admin privileges aren't required for the tool to run, but they will be if you want to access the directory of another user than yourself.

# How To Use :

Launch ***robocopy.exe***

Select a user in the bottom right.  
Wait for the data to be recovered. 
During this time the tool might freeze, it hasn't crashed just wait.

When the window opens, select a directory from which to save or restore at the top of the window

Check which file or directory you want to save.  
By default the following directories are checked :
 - Documents
 - Downloads
 - Desktop
 - Pictures

If you want to add default directories you can add them in ***default.txt***

In addition those, one of the directory checked by default that you can select is ***AppData (small)***.  
It is a version of AppData that will only contain the directories in ***default_appdata.txt***.  
It was added because of the long time it took to save the entire AppData folder.  
If you want to add default AppData directories you can add them in ***default_appdata.txt***  

The size of each folder/file is written next to it in Mb. 
As the value is rounded some folders or files may be displayed as empty even though they have data in them. 
Files and folders under 5 Kb will be displayed as empty

Once you think you've checked everything, just click on the Save button and everything you've checked will be copied from your<br> ***C:\Users\\[username]*** to the selected folder 

If you restore data, no matter what directories/files you have checked, everything will be restored from the selected folder to your<br> ***C:\Users\\[username]***

Once the process of saving/restoring is finished, a log file named ***robocopy_log*** will be created inside the target directory

# Added details :

This tool won't save data from folders or files that need admin privileges to be read.  
The full code is inside ***robocopy.ps1***, if you ever want to edit it go ahead but ***make sure to credit me if you post it online***.  
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

The executable and script won't be fully operational without the other files. The following features won't be working :
 - Having default folders checked
 - Having the AppData (small)
 - Having a log once the save/restore is complete
