
' Copyright 2004-2005 The MathWorks, Inc.

action = WScript.Arguments(0)
sVarName = WScript.Arguments(1)
Set shell = WScript.CreateObject( "WScript.Shell" )
Set iSysEnv = shell.Environment("SYSTEM")

Select Case LCase(action)
    Case "get"
        WScript.Stdout.Write( iSysEnv.Item(sVarName) )
    Case "set"
        sVarValue = WScript.Arguments(2)
        iSysEnv.Item(sVarName) = sVarValue
    Case "erase"
        iSysEnv.remove(sVarName)
End Select


