@echo off
REM Copyright 2008 The MathWorks, Inc.

REM Localize environment and enable command extensions
SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION
REM Returns with a zero error status if and only if the specified
REM action is valid given the current status of the MDCE service.
REM
REM This batch file relies on the following environment variables
REM being pre-defined:
REM   ACTION           <-- Comes from mdce.bat
REM   UTILBASE         <-- Comes from mdce.bat
REM   INSTALL_ACTION   <-- Comes from mdce.bat
REM   START_ACTION     <-- Comes from mdce.bat
REM   CONSOLE_ACTION   <-- Comes from mdce.bat
REM   STOP_ACTION      <-- Comes from mdce.bat
REM   UNINSTALL_ACTION <-- Comes from mdce.bat
REM   SCRIPTNAME       <-- Comes from mdce.bat
REM   APPNAME          <-- The service name registered with Windows


set SERVICE_STATUS=NotInstalled
for /F "delims=" %%i in ('call "%BINBASE%\serviceStatus.exe" %APPNAME%') do %%i
REM At this point, SERVICE_STATUS is either undefined or has one of the
REM following values:
REM NotInstalled  
REM Stopped       
REM Running       
REM Paused  This should never happen with Wrapper, so we error.
REM Unknown This should never happen, so we error.
REM 
REM Additionally, SERVICE_ERROR is either 0 or it contains an error message.
if not defined SERVICE_ERROR        goto :Unknown
if not defined SERVICE_STATUS       goto :Unknown
if not "%SERVICE_ERROR%" == "0"     goto :ServiceError

REM First handle the invalid service states.
if "%SERVICE_STATUS%" == "Paused"   goto :Paused
if "%SERVICE_STATUS%" == "Unknown"  goto :Unknown

if "%ACTION%"=="%INSTALL_ACTION%"   goto :install
if "%ACTION%"=="%START_ACTION%"     goto :startOrConsole
if "%ACTION%"=="%CONSOLE_ACTION%"   goto :startOrConsole
if "%ACTION%"=="%STOP_ACTION%"      goto :stop
if "%ACTION%"=="%UNINSTALL_ACTION%" goto :uninstall

:endOK
exit /b 0
:endFAILED
exit /b 1

REM ---------------------------------------------
REM Service must not be installed if we are to install it.
:install
if "%SERVICE_STATUS%"=="NotInstalled" (
    goto endOK
)
if "%SERVICE_STATUS%"=="Running" (
  echo Cannot install %SCRIPTNAME%: Service is currently running
) else (
  echo Cannot install %SCRIPTNAME%: Service is already installed
)
goto endFAILED
REM ---------------------------------------------

REM ---------------------------------------------
REM Service must be stopped for us to start it.
:startOrConsole
if "%SERVICE_STATUS%"=="Stopped" (
    goto endOK
)
if "%SERVICE_STATUS%"=="Running" (  
  echo Cannot start %SCRIPTNAME%: The service is currently running 
) else (
  echo Cannot start %SCRIPTNAME%: The service is currently not installed
)
goto endFAILED
REM ---------------------------------------------

REM ---------------------------------------------
REM Service must be running for us to stop it.
:stop
if "%SERVICE_STATUS%"=="Running" (
    goto endOK
)
if "%SERVICE_STATUS%"=="NotInstalled" (
    echo Cannot stop %SCRIPTNAME%: The service is currently not installed
) else (
    echo Cannot stop %SCRIPTNAME%: The service is currently not running
)
goto endFAILED
REM ---------------------------------------------

REM ---------------------------------------------
REM Service must be installed if we are to uninstall it.  
REM It may or may not be running.
:uninstall
if "%SERVICE_STATUS%"=="NotInstalled" (
    echo Cannot uninstall %SCRIPTNAME%: The service is currently not installed
    goto endFAILED
)
goto endOK
REM ---------------------------------------------

REM ---------------------------------------------
REM 
:Unknown
   echo Failed to get status of %SCRIPTNAME% and cannot proceed.
   goto :endFailed
REM ---------------------------------------------

REM ---------------------------------------------
REM 
:Paused
   echo %SCRIPTNAME% is paused.  Resume service before trying again.
   goto :endFailed
REM ---------------------------------------------

REM ---------------------------------------------
REM 
:ServiceError
   echo !SERVICE_ERROR!
   goto :endFailed
REM ---------------------------------------------



