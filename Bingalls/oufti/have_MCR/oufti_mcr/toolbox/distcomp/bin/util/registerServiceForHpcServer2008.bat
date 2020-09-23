@echo off

REM Copyright 2008-2011 The MathWorks, Inc.

REM this is a dummy comment
REM Localize environment and enable command extensions
SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

REM Check setbase has been called
IF NOT DEFINED BASE (
    GOTO errorSetBaseNotCalled
)

REM This script determines the correct location for SOA service files on HPC Server 2008.
REM If the location is a network path, then this script will call createServiceFileForHPCServer.bat
REM to create the MDCS Service File in the correct location.  If the location is a local path,
REM then this script uses clusrun to call createServiceFileForHPCServer.bat so that 
REM it is generated in the correct local location on each compute node.

REM For v2 (HPC Server 2008)
REM The final config file either needs to go into %CCP_HOME%\ServiceRegistration 
REM or %CCP_SERVICEREGISTRATION_PATH%.  %CCP_HOME% should be defined by default 
REM (when HPC Server is installed), but CCP_SERVICEREGISTRATION_PATH is user-defined 
REM and may not exist.  If CCP_SERVICEREGISTRATION_PATH is defined, then use that location, 
REM otherwise default to %CCP_HOME%\ServiceRegistration.
REM
REM For v3 (HPC Server 2008 R2)
REM The config files needs to go into \\<headnode>\HpcServiceRegistration
REM or %CCP_SERVICEREGISTRATION_PATH%.  %CCP_SCHEDULER% should be defined by default 
REM (when HPC Server is installed), but CCP_SERVICEREGISTRATION_PATH is user-defined 
REM and may not exist.  If CCP_SERVICEREGISTRATION_PATH is defined, then use that location, 
REM otherwise default to \\<headnode>\HpcServiceRegistration.
REM
REM Note that CCP_SERVICEREGISTRATION_PATH will be a cluster environment variable in both 
REM cases.
REM
REM Use getHPCServerVersion.vbs to query the scheduler version
if defined CCP_SCHEDULER (
    for /F "delims=" %%i in ('call cscript //B "%UTILBASE%\getHPCServerVersion.vbs" "%CCP_SCHEDULER%"') do call set SCHEDULER_VERSION=%%i
    if ERRORLEVEL 1 goto failedToGetVersion
) else (
    goto badCCPSchedEnv
)

REM Nothing to do for v1 because SOA is not supported
if "%SCHEDULER_VERSION%"=="1" goto endOK

REM See if CCP_SERVICEREGISTRATION_PATH is a cluster variable
SET GET_CLUSTER_ENVIRONMENT_VARIABLE_COMMAND="%CCP_HOME%\bin\cluscfg" listenvs
FOR /F "tokens=1,2 delims==" %%I IN ('CALL !GET_CLUSTER_ENVIRONMENT_VARIABLE_COMMAND!') DO (
    IF "%%I"=="CCP_SERVICEREGISTRATION_PATH" SET CCP_SERVICEREGISTRATION_PATH=%%J
)
IF ERRORLEVEL 1 GOTO failedToGetClusterEnvironmentVariables

if not defined CCP_SERVICEREGISTRATION_PATH (
    REM Still don't have a CCP_SERVICEREGISTRATION_PATH value, so use the default
    if "%SCHEDULER_VERSION%"=="2" (
        if defined CCP_HOME (
            REM NB It's OK on windows to have multiple slashes in the path.  It will still go to the same place.
            set SERVICE_REGISTRATION_DIR=ServiceRegistration
            set CCP_SERVICEREGISTRATION_PATH=!CCP_HOME!\!SERVICE_REGISTRATION_DIR!
        ) else (
            goto badCCPHomeEnv
        )
    ) else (
        if "%SCHEDULER_VERSION%"=="3" (
            if defined CCP_SCHEDULER (
                REM NB In R2, we must put it in the relevant place in the headnode
                set SERVICE_REGISTRATION_DIR=HpcServiceRegistration
                set CCP_SERVICEREGISTRATION_PATH=\\!CCP_SCHEDULER!\!SERVICE_REGISTRATION_DIR!
            ) else (
                REM Shouldn't ever get here as we already checked that CCP_SCHEDULER exists
                goto badCCPSchedEnv
            )
        ) else (
            goto badSchedulerVersionExit
        )
    )
    ECHO Warning: The CCP_SERVICEREGISTRATION_PATH cluster environment variable does not exist. 
    ECHO Using default value !CCP_SERVICEREGISTRATION_PATH!
)

FOR /F %%I IN ('CALL cscript //B "%UTILBASE%\isNetworkPath.vbs" "%CCP_SERVICEREGISTRATION_PATH%"') DO SET IS_NETWORK_SERVICE_LOCATION=%%I

SET CREATE_SERVICE_SCRIPT=createServiceFileForHPCServer.bat
IF "%IS_NETWORK_SERVICE_LOCATION%"=="1" (
    REM The CCP_SERVICEREGISTRATION_PATH is a network location, so just generate the config file on this machine
    ECHO Generating Service Config File locally...
    CALL "%UTILBASE%\%CREATE_SERVICE_SCRIPT%" "%CCP_SERVICEREGISTRATION_PATH%"
) ELSE (
    IF NOT DEFINED CLUSRUN_COMMAND (
        IF NOT DEFINED CLUSRUN_ARGUMENTS (
            IF NOT DEFINED CLUSTER_MATLAB_ROOT (
                REM shouldn't really get in here if called correctly.
                GOTO errorNoClusrun
            )
        )
    )
    REM The CCP_SERVICEREGISTRATION_PATH is a local location, so generate on each machine
    ECHO Generating Service Config File on the cluster...
    CALL "%CLUSRUN_COMMAND%" %CLUSRUN_ARGUMENTS% "%CLUSTER_MATLAB_ROOT%\toolbox\distcomp\bin\util\%CREATE_SERVICE_SCRIPT%" "%CCP_SERVICEREGISTRATION_PATH%"
)
IF ERRORLEVEL 1 GOTO endFAILED

goto endOK


:badCCPHomeEnv
echo Error installing MdcsService.  
echo The CCP_HOME environment variable is not defined.  
echo Please specify CCP_HOME before rerunning this script.
goto endFAILED

:badCCPSchedEnv
echo Error installing MdcsService.  
echo The CCP_SCHEDULER environment variable is not defined.  
echo Please specify CCP_SCHEDULER before rerunning this script.
goto endFAILED

:badSchedulerVersionExit
echo Error installing MdcsService.  
echo %SCHEDULER_VERSION% is not a valid scheduler version.
goto endFAILED

:failedToGetClusterEnvironmentVariables
echo Failed to get cluster environment variables.
goto endFAILED

:failedToGetVersion
echo Failed to determine HPC Server Scheduler version.
goto endFAILED

:errorSetBaseNotCalled
ECHO Error: setbase.bat must be called before %~nx0
GOTO endFAILED

:errorNoClusrun
ECHO Error: Cannot run clusrun.
ECHO\
ECHO CLUSRUN_COMMAND, CLUSRUN_ARGUMENTS and CLUSTER_MATLAB_ROOT must be 
ECHO defined if CCP_SERVICEREGISTRATION_PATH is not a local location.
ECHO\
ECHO The CCP_SERVICEREGISTRATION_PATH is 
ECHO     %CCP_SERVICEREGISTRATION_PATH%
GOTO endFAILED

:endOK
ENDLOCAL
EXIT /B 0

:endFAILED
ENDLOCAL
EXIT /B 1

