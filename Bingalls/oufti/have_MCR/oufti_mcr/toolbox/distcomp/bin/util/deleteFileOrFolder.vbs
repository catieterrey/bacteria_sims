' Copyright 2008 The MathWorks, Inc.

' Run with cscript deleteFileOrFolder.vbs  fileOrDirectory
' The argument fileOrDirectory may contain the wildcard character, but
' it must not end with a trailing backslash.
' The script performs a recursive delete of fileOrDirectory, but it does
' not delete any read-only files.

' Force variables to be declared before use
Option Explicit

' Exit with an appropriate error message if the global error number is not equal
' to okError
Sub handleError(path, okError)
   if Err.Number <> okError then 
       Wscript.Echo "Error deleting " & path & ": " & Err.Description 
       Wscript.Echo "(Error " & Err.Number & ")"
       WScript.Quit(1)
   else
      Err.Clear
   end if 
End Sub 

' The main program.  

dim path
path = WScript.Arguments(0)
dim fso
Set fso = CreateObject("Scripting.FileSystemObject")
' Declare the error codes that can be expected during normal operation.
dim pathNotFoundError
pathNotFoundError = 76
dim fileNotFoundError
fileNotFoundError = 53
dim force
force = true

On Error Resume Next  ' Do not throw an error if delete fails.
' The Delete method cannot expand wildcards, so we have to call
' both DeleteFolder and DeleteFile.

call fso.DeleteFolder(path, force)
if Err.Number <> 0 then
   call handleError(path, pathNotFoundError)
End If

call fso.DeleteFile(path, force)
if Err.Number <> 0 then
   call handleError(path, fileNotFoundError)
End If

