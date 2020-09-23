' Copyright 2006-2010 The MathWorks, Inc.

' For the code below see -
' http://www.microsoft.com/technet/scriptcenter/scripts/network/firewall/default.mspx
'  and
' http://www.microsoft.com/technet/scriptcenter/scripts/network/firewall/nwfwvb01.mspx
' http://www.microsoft.com/technet/scriptcenter/scripts/network/firewall/nwfwvb02.mspx
Sub addExeToStandardAndCurrentProfile(name, exe)
    Set objFirewall = CreateObject("HNetCfg.FwMgr")
    Set objPolicy = objFirewall.LocalPolicy
    Set currentProfile = objPolicy.CurrentProfile

    ' Check that the firewall is actually enabled before proceeding.
    If Not currentProfile.FirewallEnabled Then
        WScript.Stdout.WriteLine "Not adding " & name & " to the Windows Firewall because the Windows Firewall is not enabled."
        Exit Sub
    End If

    Set standardProfile = objPolicy.GetProfileByType(1)
    ' Check if already there in the authorized applications
    FOUND = false
    For Each app in currentProfile.AuthorizedApplications
        If app.ProcessImageFileName = exe Then
            FOUND = true
        End If
    Next
    If Not FOUND Then
        Set authApp = CreateObject("HNetCfg.FwAuthorizedApplication")
        authApp.Name = name
        authApp.ProcessImageFileName = exe   
        currentProfile.AuthorizedApplications.Add(authApp)
        ' Do it again as it seems we need a new object for the second call
        Set authApp = CreateObject("HNetCfg.FwAuthorizedApplication")
        authApp.Name = name
        authApp.ProcessImageFileName = exe
        standardProfile.AuthorizedApplications.Add(authApp)
        ' Tell the user we have done it
        WScript.Stdout.WriteLine "Adding " & name & " to the windows firewall settings with path "
        WScript.Stdout.WriteLine exe    
    End If
End Sub


'' See http://msdn.microsoft.com/en-us/library/aa366442(v=VS.85).aspx
Function isWindowsFirewallServiceRunning
    ' Is the Windows Firewall/Internet Connection Sharing (ICS) Service
    ' running? If not, can't be using Windows Firewall
    Set objShell = CreateObject("Shell.Application")
    ' NB The service name changed between XP and Vista, so check them both.
    isWindowsFirewallServiceRunningInXP = objShell.IsServiceRunning("SharedAccess")
    isWindowsFirewallServiceRunningInVista = objShell.IsServiceRunning("MpsSvc")
    isWindowsFirewallServiceRunning = isWindowsFirewallServiceRunningInXP Or isWindowsFirewallServiceRunningInVista
End Function

' The main program. The 2 input arguments to this script are
' the name you wish to give to this firewall rule and the location
' of the executable to run - the exe may be referenced by a network
' drive, in which case we will convert to a UNC path
name = WScript.Arguments(0)
exe  = WScript.Arguments(1)

' First check if the Windows Firewall Service is running.  If not,
' we can't be using the Windows Firewall, so just quit.  If the service
' is not running, but the previous state of the Firewall is set to "On",
' then the call to CreateObject("HNetCfg.FwMgr") in 
' addExeToStandardAndCurrentProfile will error.  
If Not isWindowsFirewallServiceRunning Then
    WScript.Stdout.WriteLine "Not adding " & name & " to the Windows Firewall because the firewall service is not running."
    WScript.Quit(0)
End If

' Clear the error object to see if any errors are thrown by this
On Error Resume Next
Err.Clear
call addExeToStandardAndCurrentProfile(name, exe)
If Err.Number <> 0 Then
    WScript.Stdout.WriteLine "Unable to change windows firewall settings. Error given :"
    WScript.Stdout.WriteLine  Err.Description
End If

