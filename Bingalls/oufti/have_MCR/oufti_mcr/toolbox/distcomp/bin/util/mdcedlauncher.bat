@ECHO OFF

REM Copyright 2010-2013 The MathWorks, Inc.

REM This calls the "right" mdced.exe for the current platform
REM Since it calls setbase.bat loads of useful environment
REM variables are available in the config file

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

REM Can now call the right mdced.exe and pass in the correct arch
CALL "%MATBINARCH%\mdced.exe" %*

ENDLOCAL
EXIT /B %ERRORLEVEL%
