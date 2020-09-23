' Copyright 2008-2010 The MathWorks, Inc.
'   

' Run with cscript replaceStringInFile sourceFile, destinationFile, N, 
'       stringToBeReplaced1, stringToReplaceWith1, ..., stringToBeReplacedN, stringToReplaceWithN
' The script will replace all instances of stringToBeReplaced with stringToReplaceWith

' Error handlers should set an appropriate error code since this script will 
' be run in batch mode

' Force variables to be declared before use
Option Explicit

' Parse input arguments
Dim allArguments, sourceFilename, destinationFilename, numStringsToReplace, findStringIndex
Set allArguments = WScript.Arguments
findStringIndex = 3
' Need at least 3 arguments
If allArguments.Count < findStringIndex Then
    echoError "Incorrect usage: replaceStringInFile requires at least " & findStringIndex & " arguments."
    WScript.Quit(3)
End If

sourceFilename = allArguments(0)
destinationFilename = allArguments(1)
numStringsToReplace = allArguments(2)

' Check that we have at least 1 string to replace
If numStringsToReplace < 1 Then
    echoError "No strings to replace"
    WScript.Quit(0)
End If
' Need at least numStringsToReplace*2 more arguments
If allArguments.Count < findStringIndex + numStringsToReplace*2 Then
    echoError "Incorrect usage: Not enough input arguments for " & numStringsToReplace & " strings to replace."
    WScript.Quit(3)
End If

' Don't throw errors, instead handle them using handleError
On Error Resume Next

Dim origFileContents
' Read the source file
origFileContents = readTextFile(sourceFilename)
If Err.Number <> 0 Then
    handleReadError sourceFilename
End If

' Replace the strings
Dim replacedFileContents, argumentOffset, count, findString, replaceWithString
replacedFileContents = origFileContents
For count = 0 to numStringsToReplace - 1
    argumentOffset = findStringIndex + count * 2
    findString = allArguments(argumentOffset)
    replaceWithString = allArguments(argumentOffset + 1)
    WScript.Echo "Replacing " & findString & " with " & replaceWithString & "."
    replacedFileContents = Replace(replacedFileContents, findString, replaceWithString)
Next

' Open the destination file for writing
writeFile destinationFilename, replacedFileContents
' Write the destination file
If Err.Number <> 0 Then
    handleWriteFileError destinationFilename
End If

'Read in a text file
Function readTextFile(fileName)
    If fileName<>"" Then
        Dim fileSystem, fileStream
        Set fileSystem = CreateObject("Scripting.FileSystemObject")
        If fileSystem.FileExists(fileName) = True Then 
            Set fileStream = fileSystem.OpenTextFile(fileName)
            readTextFile = fileStream.ReadAll
            fileStream.Close
        End If
    End If
End Function


'Write a text file with the specified contents
Sub writeFile(fileName, contents)
    Dim fileStream
    If fileName<>"" Then
        Dim fileSystem
        Set fileSystem = CreateObject("Scripting.FileSystemObject")
        ' If the file already exists, delete it.  Do this because
        ' CreateTextFile seems to throw an error if the file already exists
        ' even if you set the overwriteFile flag to true
        If fileSystem.FileExists(fileName) Then
            WScript.Echo "Deleting file " & fileName
            Dim forceDeletion
            forceDeletion = True
            fileSystem.DeleteFile fileName, forceDeletion
        End If
        ' Open a file for writing, overwiting if it already exists
        ' If we cannot open a file in the specified location then this will 
        ' throw an error.
        Dim overwriteFile
        overwriteFile = True
        WScript.Echo "Creating file " & fileName
        Set fileStream = fileSystem.CreateTextFile(fileName, overwriteFile)
    End If
    If contents<>"" Then
        ' If we cannot write to the specified stream then this will 
        ' throw an error.
        WScript.Echo "Writing to file " & fileName
        fileStream.Write contents
    End If
    fileStream.Close
End Sub

' Error handling function - display the message and quit with error code 1
Sub handleReadError(filename)
    echoError "Error reading " & filename
    WScript.Quit(1)
End Sub

' Error handling function for write file- display the message and quit with
' error code 2
Sub handleWriteFileError(filename)
    echoError "Error writing to " & filename
    WScript.Quit(2)
End Sub

Sub echoError(errorMessage)
    WScript.Echo errorMessage
    WScript.Echo "Original error: " & Err.Description
    WScript.Echo "Error number: " & Err.Number
End Sub