' Copyright 2007-2013 The MathWorks, Inc.

' Function prototype : grantUserRights.vbs mode PathToControl UserName Permission
' 
' mode is either "-set" or "-modify"
'
' PathToControl MUST be a mapped drive specification to the path that 
'   you wish to gran the user full control of.
'
' UserName is expected to be in the format DOMAIN\username or username
'   if the latter (just username) is found the DOMAIN is assumed to be '.'
'
' Permission must be one of "Traversal", "ReadOnly", "ReadWrite" or "FullControl"
'

Option Explicit

Dim intRetVal, strModifyOrSet, strFilePath, strUserName, strPermission, strArray

' Check we have th ecorrect number of arguments
If WScript.Arguments.Count <> 4 Then
    WScript.Echo "Incorrect number of arguments passed to script. Got " & WScript.Arguments.Count & " and expected 4."
    WScript.Quit(1)
End If

' Pick up the input arguments - mode, path and Domain\Username
strModifyOrSet = WScript.Arguments(0)
strFilePath = WScript.Arguments(1)
strUserName = WScript.Arguments(2)
strPermission = WScript.Arguments(3)

' NOTE - strArray will be of size 0 if no '\' is found
strArray = split(strUserName, "\")
' Check to ensure that a domain and username have been presented
' If not default the domain to '.'
If UBound(strArray) < 1 Then
    ReDim strArray(2)
    strArray(1) = strUserName
    strArray(0) = "."
End If

' Do nothing if username or domain are empty strings. If they are empty
' then you find that you add the BUILTIN group to the ACL's
If Len(strArray(0)) = 0 Or Len(strArray(1)) = 0 Then
    WScript.Quit(0)
End If

' Currently we will only ever search the local machine '.' to change the file perms. 
' This could possibly be extended to allow us to search remote machines and thus
' modify UNC paths if the need arises.
If strModifyOrSet = "-modify" Then
    intRetVal = ModifyFilePerm(".", strFilePath, strArray(1), strArray(0), strPermission, "u")
ElseIf strModifyOrSet = "-set" Then
    intRetVal = SetFilePerm(".", strFilePath, strArray(1), strArray(0), strPermission, "u")
Else    
    WScript.Echo "Unknown mode '" & strModifyOrSet & "'"
    intRetVal = 1
End If

WScript.Quit(intRetVal)

' This function adds permissions strAccessLvl "Traversal", "ReadOnly", "ReadWrite" or "FullControl"
' to user specified by strDomain\strUsername of strUtype 'u(ser), g(roup)' on path strFilePath 
' found on computer strComputer
Function ModifyFilePerm(strComputer, strFilePath, strUsername, strDomain, strAccessLvl, strUtype)
    Dim dacl, root, SecDesc, intRetVal
    Dim wmiFileSecSetting, wmiFileSetting, wmiSecurityDescriptor
    
    On Error Resume Next
    
    Set root = GetObject("winmgmts:{impersonationLevel=impersonate,(Security)}!\\" & strComputer & "\root\cimv2")
    Set SecDesc = root.Get("Win32_SecurityDescriptor").SpawnInstance_

    strFilePath = replace(strFilePath,"\","\\")
    Set wmiFileSetting = root.Get("Win32_Directory='" & strFilePath & "'")
    Set wmiFileSecSetting = root.Get("Win32_LogicalFileSecuritySetting.path='" & strFilePath & "'")
    'you can have problems here if you have no descriptor ie only everyone listed.
    intRetVal = wmiFileSecSetting.GetSecurityDescriptor(wmiSecurityDescriptor)
    ' Obtain existing security descriptor for folder
    If Err <> 0 Then
        WScript.Quit(1)
    End If
    ' Retrieve the content of Win32_SecurityDescriptor DACL property.
    dacl = wmiSecurityDescriptor.dacl
    ' Add the correct ACE to the DACL
    AddUserAce dacl, strUsername, strDomain, strUtype, strComputer, strAccessLvl, root
    SecDesc.Properties_.Item("DACL") = dacl

    ' See http://msdn.microsoft.com/en-us/library/aa384887(VS.85).aspx
    ' Return the value from ChangeSecurityPermissions to indicate we have succeded
    Const CHANGE_DACL_SECURITY_INFORMATION = 4
    ModifyFilePerm = wmiFileSetting.ChangeSecurityPermissions(SecDesc, CHANGE_DACL_SECURITY_INFORMATION)
    
    Set root = nothing
    Set SecDesc = Nothing
    Set wmiFileSecSetting = nothing
    Set wmiFileSetting = nothing
End Function

' This function sets permissions strAccessLvl "Traversal", "ReadOnly", "ReadWrite" or "FullControl" 
' to user specified by strDomain\strUsername of strUtype 'u(ser), g(roup)' on path strFilePath 
' found on computer strComputer
Function SetFilePerm(strComputer, strFilePath, strUsername, strDomain, strAccessLvl, strUtype)
    Dim dacl
    Dim  root, SecDesc, intRetVal
    Dim wmiFileSecSetting, wmiFileSetting, wmiSecurityDescriptor
    
    On Error Resume Next
    
    Set root = GetObject("winmgmts:{impersonationLevel=impersonate,(Security)}!\\" & strComputer & "\root\cimv2")
    Set SecDesc = root.Get("Win32_SecurityDescriptor").SpawnInstance_

    strFilePath = replace(strFilePath,"\","\\")
    Set wmiFileSetting = root.Get("Win32_Directory='" & strFilePath & "'")
    Set wmiFileSecSetting = root.Get("Win32_LogicalFileSecuritySetting.path='" & strFilePath & "'")
    'you can have problems here if you have no descriptor ie only everyone listed.
    intRetVal = wmiFileSecSetting.GetSecurityDescriptor(wmiSecurityDescriptor)
    ' Obtain existing security descriptor for folder
    If Err <> 0 Then
        WScript.Quit(1)
    End If
    ' Retrieve the content of Win32_SecurityDescriptor DACL property.
    dacl = wmiSecurityDescriptor.DACL
    ' Add the correct ACE to the DACL
    SetUserAce dacl, strUsername, strDomain, strUtype, strComputer, strAccessLvl, root
    SecDesc.Properties_.Item("DACL") = dacl

    ' See http://msdn.microsoft.com/en-us/library/aa384887(VS.85).aspx
    ' Return the value from ChangeSecurityPermissions to indicate we have succeded
    Const CHANGE_DACL_SECURITY_INFORMATION = 4
    SetFilePerm = wmiFileSetting.ChangeSecurityPermissions(SecDesc, CHANGE_DACL_SECURITY_INFORMATION)
    
    Set root = nothing
    Set SecDesc = Nothing
    Set wmiFileSecSetting = nothing
    Set wmiFileSetting = nothing
End Function

Function ModifyUserAce( byref dacl, intArrAceMax, strUsername, strDomain, strUtype, strComputer, strAccessLvl, byref root )
    'Copy dacl to new ACE array then add specified user/group to ACE array and return it.
    ReDim preserve dacl(intArrAceMax)
    
    Set dacl(intArrAceMax) = root.Get("Win32_Ace").SpawnInstance_
    If strAccessLvl = "Traversal" Then
        dacl(intArrAceMax).Properties_.Item("AccessMask") = AccessMask("Traversal")
    ElseIf strAccessLvl = "ReadOnly" Then
        dacl(intArrAceMax).Properties_.Item("AccessMask") = AccessMask("ReadOnly") 
    ElseIf strAccessLvl = "ReadWrite" Then
        dacl(intArrAceMax).Properties_.Item("AccessMask") = AccessMask("ReadWrite")
    ElseIf strAccessLvl = "FullControl" Then
        dacl(intArrAceMax).Properties_.Item("AccessMask") = AccessMask("FullControl")
    Else 
        WScript.Echo "Unknown access level: " & strAccessLvl
        WScript.Quit(1)
    End If    
    Const OBJECT_INHERIT_ACE = &H1
    Const CONTAINER_INHERIT_ACE = &H2
    dacl(intArrAceMax).Properties_.Item("AceFlags") = OBJECT_INHERIT_ACE OR CONTAINER_INHERIT_ACE
    dacl(intArrAceMax).Properties_.Item("AceType") = 0 ' Access Allowed type
    dacl(intArrAceMax).Properties_.Item("Trustee") = GetObjTrustee(strUsername, strDomain, strUtype, root)
End Function

Function SetUserAce( byref dacl, strUsername, strDomain, strUtype, strComputer, strAccessLvl, byref root )
    Dim intArrAceMax
    intArrAceMax = 0
    ModifyUserAce dacl, intArrAceMax, strUserName, strDomain, strUtype, strComputer, strAccessLvl, root
End Function

Function AddUserAce( byref dacl, strUsername, strDomain, strUtype, strComputer, strAccessLvl, byref root )
    Dim intArrAceMax
    intArrAceMax = UBound(dacl) + 1
    ModifyUserAce dacl, intArrAceMax, strUserName, strDomain, strUtype, strComputer, strAccessLvl, root
End Function

Function GetObjTrustee(strUsername, strDomain, strUtype, byref root)
    'Get and user/group object to copy user/group sid to new trustee instance to be returned
    Dim objTrustee, account, accountSID, localRoot, objNet
    
    On Error Resume Next
    
    Set localRoot = GetObject("Winmgmts:{impersonationlevel=impersonate}!//./root/cimv2")
    Set objTrustee = root.Get("Win32_Trustee").Spawninstance_
    ' It appears that domain cannot be '.' but needs to be the name of the local machine to
    ' correctly resolve an account
    If strDomain = "." Then
        Set objNet = CreateObject("WScript.NetWork")
        strDomain = objNet.ComputerName 
    End If
    ' Special case the situation where the username is S-***** as we are going to treat this
    ' as a SID directly.
    If Left(strUsername, 2) = "S-" Then
        Set accountSID = localRoot.Get("Win32_SID.SID='" & strUsername & "'")
        strDomain = accountSID.ReferencedDomainName
        strUsername = accountSID.AccountName
    Else
        ' For some reason you can't seem to be able to connect remotely to get account, so we need
        ' to use the local 
        If strUtype = "g" Then
            Set account = localRoot.Get("Win32_Group.Name='" & strUsername & "',Domain='" & strDomain &"'")
        Else
            Set account = localRoot.Get("Win32_Account.Name='" & strUsername & "',Domain='" & strDomain &"'")
        End If
        ' Might be unable to find the relevent account
        If Err <> 0 Then
            WScript.Quit(1)
        End If
        Set accountSID = localRoot.Get("Win32_SID.SID='" & account.SID & "'")
    End If
    objTrustee.Domain = strDomain
    objTrustee.Name = strUsername
    objTrustee.Properties_.item("SID") = accountSID.BinaryRepresentation    
    Set GetObjTrustee = objTrustee
    
    Set accountSID = nothing
    Set account = nothing
    Set objTrustee = nothing
    Set localRoot = nothing
End Function

Function AccessMask(strMaskType)
    ' See http://msdn.microsoft.com/en-us/library/aa394063(VS.85).aspx
    Const FILE_READ_DATA        = &H1
    Const FILE_LIST_DIRECTORY   = &H1 'FILE_LIST_DIRECTORY is same as FILE_READ_DATA
    Const FILE_WRITE_DATA       = &H2
    Const FILE_ADD_FILE         = &H2 'FILE_ADD_FILE is same as FILE_WRITE_DATA
    Const FILE_APPEND_DATA      = &H4
    Const FILE_ADD_SUBDIRECTORY = &H4 'FILE_ADD_SUBDIRECTORY is same as FILE_APPEND_DATA
    Const FILE_READ_EA          = &H8
    Const FILE_WRITE_EA         = &H10
    Const FILE_EXECUTE          = &H20
    Const FILE_TRAVERSE         = &H20 'FILE_TRAVERSE is same as FILE_EXECUTE
    Const FILE_DELETE_CHILD     = &H40
    Const FILE_READ_ATTRIBUTES  = &H80
    Const FILE_WRITE_ATTRIBUTES = &H100
    Const DELETE                = &H10000
    Const READ_CONTROL          = &H20000
    Const WRITE_DAC             = &H40000
    Const WRITE_OWNER           = &H80000
    Const SYNCHRONIZE           = &H100000
    
    Dim READ_MASK, WRITE_MASK, FULLCONTROL_MASK
    
    READ_MASK = _
        FILE_READ_DATA OR _
        FILE_LIST_DIRECTORY OR  _
        FILE_READ_EA OR _
        FILE_EXECUTE OR _ 
        FILE_TRAVERSE OR _
        FILE_READ_ATTRIBUTES OR _
        READ_CONTROL OR _
        SYNCHRONIZE

    WRITE_MASK = _
        READ_MASK OR _
        FILE_WRITE_DATA OR _
        FILE_ADD_FILE OR _
        FILE_APPEND_DATA OR _
        FILE_ADD_SUBDIRECTORY OR _        
        FILE_WRITE_EA OR _        
        FILE_WRITE_ATTRIBUTES OR _
        DELETE

    FULLCONTROL_MASK = _
        WRITE_MASK OR _
        FILE_DELETE_CHILD OR _
        WRITE_DAC OR _
        WRITE_OWNER

    If strMaskType = "Traversal" Then
        AccessMask = FILE_TRAVERSE
    ElseIf strMaskType = "ReadOnly" Then
        AccessMask = READ_MASK
    ElseIf strMaskType = "ReadWrite" Then
        AccessMask = WRITE_MASK
    ElseIf strMaskType = "FullControl" Then  
        AccessMask = FULLCONTROL_MASK
    Else
        WScript.Echo "Unknown Mask Type '" & strMaskType & "'"
        WScript.Quit(1)
    End If       

End Function
