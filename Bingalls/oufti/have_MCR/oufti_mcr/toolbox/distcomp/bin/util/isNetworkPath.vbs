' Copyright 2010 The MathWorks, Inc.

' Run with cscript isNetworkPath.vbs filePath
' Writes 0 or 1 to stdout.  If 1, then the path 
' is a network drive.

' Force variables to be declared before use
Option Explicit

' Get the path we are checking from the input 
' arguments. 
Dim inputPath, fso, driveName, drive, isNetworkPath
inputPath = WScript.Arguments(0)

Set fso = CreateObject("Scripting.FileSystemObject")
driveName = fso.GetDriveName(inputPath)
WScript.Echo "Drive name: " & driveName
Set drive = fso.GetDrive(driveName)
' Drive Types listed here: http://msdn.microsoft.com/en-us/library/ys4ctaz0%28v=VS.85%29.aspx
isNetworkPath = (drive.DriveType = 3)

If isNetworkPath Then
    WScript.Stdout.Write 1
Else
    WScript.Stdout.Write 0
End If
WScript.Quit(0)

