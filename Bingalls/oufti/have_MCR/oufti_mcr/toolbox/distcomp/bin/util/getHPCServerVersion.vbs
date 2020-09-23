' Copyright 2010 The MathWorks, Inc.
'   

' Run with cscript getHPCServerVersion schedulerHostname
' This script will write the scheduler version to stdout.

' Error handlers should set an appropriate error code since this script will 
' be run in batch mode

' Force variables to be declared before use
Option Explicit

' Parse input arguments
Dim schedulerHostname
schedulerHostname = WScript.Arguments(0)

' Don't throw errors, instead handle them using handleErrorAndQuit
On Error Resume Next

Dim schedulerVersion
schedulerVersion = -1
schedulerVersion = getVersionFromHPCServer(schedulerHostname)
If schedulerVersion = -1 Then
    ' Couldn't get the version from HPC Server libraries, so now try CCS.  
    ' We have to assume that if we weren't able to get the version number out 
    ' of HPC Server, but we could create a CCS Scheduler and connect to it, then
    ' the scheduler is version 1.  This isn't entirely accurate since it could
    ' just mean that only the v1 client utilties are installed on this machine. 
    ' (You can use v1 client utilities to connect to all versions.)  Since this
    ' script is designed to be run on the cluster headnode, this shouldn't be an
    ' issue, since the headnode is guaranteed to have the correct version of the 
    ' libraries installed!

    ' Clear the error first so we don't detect it again.
    Err.Clear
    Dim canConnectUsingCcs
    canConnectUsingCcs = False
    canConnectUsingCcs = canCreateAndConnectComputeCluster(schedulerHostname)
    If canConnectUsingCcs Then
        schedulerVersion = 1
    Else
        handleErrorAndQuit "Error creating connection to " & schedulerHostname
    End If
End If

WScript.Stdout.Write schedulerVersion


' Try to get the version of the scheduler using the HPC Server libraries
Function getVersionFromHPCServer(schedulerHostname)
    Dim scheduler
    Set scheduler = CreateObject("Microsoft.Hpc.Scheduler.Scheduler")
    If Err.Number <> 0 Then
        Exit Function
    End If
    
    scheduler.Connect schedulerHostname
    If Err.Number <> 0 Then
        WScript.Echo "error connecting v2"
        Exit Function
    End If
    
    ' Get HPC Server to tell us what the server version is.
    Dim version
    Set version = scheduler.GetServerVersion()
    getVersionFromHPCServer = version.Major
End Function

' Try to connect to the scheduler using the CCS libraries
Function canCreateAndConnectComputeCluster(schedulerHostname)
    Dim scheduler
    Set scheduler = CreateObject("Microsoft.ComputeCluster.Cluster")
    If Err.Number <> 0 Then
        Exit Function
    End If
    scheduler.Connect schedulerHostname
    If Err.Number <> 0 Then
        WScript.Echo "error connecting v1"
        Exit Function
    End If
    canCreateAndConnectComputeCluster = True
End Function


Sub handleErrorAndQuit(errorMessage)
    WScript.Echo errorMessage
    WScript.Echo "Original error: " & Err.Description
    WScript.Echo "Error number: " & Err.Number
    WScript.Quit(1)
End Sub

