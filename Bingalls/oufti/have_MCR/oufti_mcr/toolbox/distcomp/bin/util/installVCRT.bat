@echo off
REM Copyright 2006-2010 The MathWorks, Inc.
REM
REM This script checks whether the required run-time libraries are installed on
REM this machine, and installs them if they are not.
REM
REM Note: We cannot just call "matlab -silent_install_vcrt", because
REM it does not perform a VCRT check before running the VCRT installers.
REM The VCRT installers will exit quickly if the relevant VCRTs are already
REM installed, but waiting for them to start and exit still takes a few
REM seconds, whereas VCRT_check.exe will return immediately.
REM
REM This script requires setbase.bat to be invoked first so that MATBASE
REM and MATLAB_ARCH environment variables have been defined.

REM Localize environment and enable command extensions
SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION 

REM Check setbase has been called
IF NOT DEFINED MATBASE (
    REM If we get here, setbase was not called
    ECHO Error: setbase.bat must be called before %~nx0
    EXIT /B 1
)

REM Call matlab -query, and execute the output, redirecting stdout and stderr
REM from that output to NULL.
REM For 11a, we will get 2 lines related to Visual C++ Redistributables followed
REM by "set MATLAB_ARCH=xxxx" and "set MATLAB_ERROR=yyyyy"
REM MATLAB_ERROR indicates whether or not the VCRTs have been installed.
FOR /F "delims=" %%I IN ('"%MATBASE%\bin\matlab" -query') DO (
    %%I>NUL 2>NUL
)
IF NOT DEFINED MATLAB_ERROR GOTO badEnvExit

IF "%MATLAB_ERROR%"=="1" (
    REM install the run-time silently
    "!MATBASE!\bin\matlab" -silent_install_vcrt 
    IF ERRORLEVEL 1 GOTO endFAILED
)

goto endOK

:endOK
EXIT /B 0

:endFAILED
ECHO\
ECHO Failed to install the required run-time libraries on this machine.  
ECHO Note that Administrator privileges are needed.
ECHO\
EXIT /B 1

:badEnvExit
ECHO 'MATLAB -query' did not set all required environment variables.
EXIT /B 1
