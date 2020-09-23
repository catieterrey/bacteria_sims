' Copyright 2005-2010 The MathWorks, Inc.

' Run with cscript convertToUNC.vbs mypath
' to convert mypath from mapped drives to a UNC path.
' This script returns mypath if mypath is not the absolute
' path to a mapped drive.

' Returns true if and only if the input argument is a network
' drive and has a drive letter
Function isNetworkDriveWithDriveLetter(path)
    Set fso = CreateObject("Scripting.FileSystemObject")
    driveName = fso.GetDriveName(path)
    Set drive = fso.GetDrive(driveName)
    hasDriveLetter = drive.DriveLetter <> ""
    ' Drive Types listed here: http://msdn.microsoft.com/en-us/library/ys4ctaz0%28v=VS.85%29.aspx
    isNetworkDrive = (drive.DriveType = 3)
    isNetworkDriveWithDriveLetter = isNetworkDrive And hasDriveLetter
End Function

' Converts a drive path to a UNC path.
' Input is assumed to satisfy the regular expression 
' "^[A-Za-z]:"
' Think of these two function calls:
' 1) drivePathToUNC("s:\myfile.txt")
' 2) drivePathToUNC("s:myfile.txt")
' in these two different cases:
' a) The drive s: maps to \\myhost\mydir
' b) The drive s: is a local drive
' In the case of a, we want to return "\\myhost\mydir\myfile.txt"
' In the case of b, we want to return the input unmodified.
' Thus, we don't even bother returning "s:\myfile.txt" for the input in 2).
Function drivePathToUNC(path)
    Set fso = CreateObject("Scripting.FileSystemObject")
    driveName = fso.GetDriveName(path)
    Set drive = fso.GetDrive(driveName)
    If drive.ShareName <> "" Then
        ' Remove the drive letter and colon, then see if we need to stitch
        ' in a "\" before adding the UNC path onto the front of it.
        pathWithDriveLetterRemoved = Mid(path, 3)
        If (Left(pathWithDriveLetterRemoved, 1) <> "/") And (Left(pathWithDriveLetterRemoved, 1) <> "\") Then
            pathWithDriveLetterRemovedremainder = "\" + pathWithDriveLetterRemoved
        End If
        drivePathToUNC = drive.ShareName + pathWithDriveLetterRemoved
    Else
        ' Return the input unmodified if the share name was empty
        drivePathToUNC = path
    End If
End Function

' The main program.  
' Take care to return the input unmodified if it is not in terms of 
' a mapped drive.

path = WScript.Arguments(0)
If isNetworkDriveWithDriveLetter(path) = True Then
    UNC = drivePathToUNC(path)
    WScript.Stdout.Write UNC 
Else
    WScript.Stdout.Write path
End If
