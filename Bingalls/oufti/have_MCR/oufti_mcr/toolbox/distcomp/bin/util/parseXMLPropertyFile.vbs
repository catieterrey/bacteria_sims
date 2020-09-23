' Copyright 2010 The MathWorks, Inc.
Option Explicit
On Error Resume Next

' parseXMLPropertyFile.vbs parses an XML property file, extracts the properties defined
' therein and writes the properties to stdout in the format
' name=value.
' 
' The properties in the XML file must have the form:
' <property name="propName" value="propValue">
'
' Call this with 1 argument: the file to parse.
' 
' Exit codes: 
'   0 - no errors
'   100 - failed to parse XML due to invalid XML or badly defined properties
'   101 - all other errors


' Beginner's guide to VBS and XML:
' http://msdn.microsoft.com/en-us/library/aa468547.aspx
' VBS XML Reference
' http://msdn.microsoft.com/en-us/library/ms760218%28VS.85%29.aspx

Dim xmlToLoad
xmlToLoad = WScript.Arguments(0)

Dim xmlDoc
Set xmlDoc = CreateObject("Microsoft.XMLDOM")
xmlDoc.async="false"

If xmlDoc.Load(xmlToLoad) Then
    Dim propertyNodes
    Set propertyNodes = xmlDoc.getElementsByTagName("Property")
    If Err.Number <> 0 Then
        exitGenericError "Failed to get Property elements from " & xmlToLoad
    End If
    
    Dim propNode
    For Each propNode In propertyNodes
        writePropertyAttributesToStdOut propNode
        If Err.Number <> 0 Then
            exitGenericError "Failed to extract property from node"
        End If
    Next
Else
   ' The document failed to load.
    ' Obtain the ParseError object
    Dim parseError
    Set parseError = xmlDoc.parseError
    
    exitParseError "Failed to load " & xmlToLoad & "(line " & parseError.Line & ")" & vbCrLf & _
        "Reason: " & parseError.errorCode & ": " & parseError.Reason
End If

WScript.Quit(0)


Sub exitParseError(errorMessage)
    WScript.Echo errorMessage
    WScript.Quit(100)
End Sub

Sub exitGenericError(errorMessage)
    WScript.Echo errorMessage
    WScript.Echo "Original error: " & Err.Description
    WScript.Echo "Error number: " & Err.Number
    WScript.Echo "Error occurred: " & Err.Description
    WScript.Quit(101)
End Sub

' Write the values of the "name" and "value" attributes
' to stdout in the form name=value
Sub writePropertyAttributesToStdOut(propNode)
    On Error Resume Next
    Dim attribs, propName, propValue
    Set attribs = propNode.attributes
    propName = attribs.getNamedItem("name").text
    If Err.Number <> 0 Then
        exitParseError "Failed to retrieve name attribute from property node " & propNode.xml
    End If
    propValue = attribs.getNamedItem("value").text
    If Err.Number <> 0 Then
        exitParseError "Failed to retrieve value attribute from property node " & propNode.xml
    End If
    If propName <> "" Then
        WScript.StdOut.WriteLine propName & "=" & propValue
    End If
End Sub
