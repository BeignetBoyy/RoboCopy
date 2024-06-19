# RoboCopy

A tool to Save and Restore data from your C:\Users\<username> using RoboCopy

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


