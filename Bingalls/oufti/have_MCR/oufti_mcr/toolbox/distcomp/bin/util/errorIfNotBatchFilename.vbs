' Copyright 2010 The MathWorks, Inc.
Option Explicit

' errorIfNotBatchFilename takes a string and determines whether or not it has a 
' valid batch file extension (.bat or .cmd).
' If the filename is a valid batch file, the exit code is 0
' Otherwise, the exit code is 1.
' 
' Call with 1 argument: the filename

Dim filename, extension
filename = WScript.Arguments(0)
' Get the last 4 characters of the filename.  If filename has fewer than 
' 4 characters, then the whole string is returned.
extension = Right(filename, 4)

' Valid batch file extensions are .bat and .cmd, according to 
' http://www.microsoft.com/resources/documentation/windows/xp/all/proddocs/en-us/batch.mspx?mfr=true
Dim batExtension, cmdExtension
batExtension = ".bat"
cmdExtension = ".cmd"

' NB vbTextCompare does textual comparison - i.e. case insensitive.
' StrComp returns 0 if the strings are the same.
If (StrComp(extension, batExtension, vbTextCompare)<>0) And (StrComp(extension, cmdExtension, vbTextCompare)<>0) Then
    ' This does not have a valid batch file extension
    WScript.Quit(1)
Else
    ' This has a valid batch file extension
    WScript.Quit(0)
End If

