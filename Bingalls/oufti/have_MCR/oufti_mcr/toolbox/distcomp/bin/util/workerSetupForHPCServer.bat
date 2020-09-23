@ECHO off

REM Copyright 2010-2011 The MathWorks, Inc.

REM Localize environment and enable command extensions
SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

REM ========================= pathsetup.bat (start) ============================
REM Get the current script directory and the name of this script
SET SCRIPT_LOCATION=%~dp0
SET SCRIPTNAME=%~n0
REM Set BASE to be the toolbox\distcomp\bin location by stripping off "util\"
SET BASE=%SCRIPT_LOCATION:util\=%

REM Set some base directories
CALL "%BASE%\util\setbase.bat"
REM ========================= pathsetup.bat (end) ==============================

REM This script will perform all the setup steps required for a worker.  The 
REM intention is for this script to be called using the clusrun command supplied
REM with HPC Server.
REM
REM The steps are:
REM     1: Add MATLAB to the Windows Firewall
REM     2: Add assemblies to the code access security policy if 
REM     we are actually running from a network drive
REM     3: Install the Visual C Runtime libraries on the nodes
REM     4: Register MDCSServiceForPCT with HPC Server


REM Step 1: Add MATLAB to the Windows Firewall
ECHO Adding MATLAB to the Windows Firewall...
CALL "%BASE%\addMatlabToWindowsFirewall.bat"
IF ERRORLEVEL 1 GOTO endFAILED

REM Step 2: Add assemblies to the code access security policy if 
REM we are actually running from a network drive
REM If we are on a network drive, this file will be called using the UNC 
REM path, so we need to parse BASE to see if there is a "\\" at the beginning 
REM of it
FOR /F %%I in ('CALL cscript //B "%UTILBASE%\isNetworkPath.vbs" "%BASE%"') DO SET IS_NETWORK_INSTALL=%%I
IF ERRORLEVEL 1 GOTO endFAILED
IF "%IS_NETWORK_INSTALL%"=="1" (
    ECHO Adding assemblies to the Code Access Security Policy...
    CALL "%UTILBASE%\addAssembliesToCaspol.bat" -all
    IF ERRORLEVEL 1 GOTO endFAILED
)

REM Step 3: Install the Visual C Runtime libraries on the nodes
ECHO Installing the Visual C Runtime libraries...
CALL "%UTILBASE%\installVCRT.bat" 
IF ERRORLEVEL 1 GOTO endFAILED

:endOK
ENDLOCAL
EXIT /B 0


:endFAILED
ECHO Script %SCRIPTNAME% unable to complete successfully - exiting
ENDLOCAL
EXIT /B 1

