' Copyright 2010 The MathWorks, Inc.

' Run with cscript isFillPath.vbs filePath
' Exits with 0 if the path is an full, absolute 
' path, and 1 if it is relative.

' Force variables to be declared before use
Option Explicit

' Get the path we are checking from the input 
' arguments. 
Dim inputPath
inputPath = WScript.Arguments(0)

' Create the file system object
Dim oFSO
Set oFSO = CreateObject("Scripting.FileSystemObject")

' Get the absolute path for the input path
Dim absolutePath
absolutePath = oFSO.GetAbsolutePathName(inputPath)

' Compare the 2 strings in upper case
If StrComp(Ucase(inputPath),Ucase(absolutePath)) = 0 Then
    WScript.Echo inputPath + " is a full path"
    WScript.Quit(0)
Else
    WScript.Echo inputPath + " is not a full path"
    WScript.Quit(1)
End If
