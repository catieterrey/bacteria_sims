@ECHO OFF

REM Copyright 2011 The MathWorks, Inc.

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

REM This script takes the MdcsServiceForPCT.config file in distcomp/config and generates
REM a new version of this config that has a PCT version-specific filename and is stored
REM in the directory that is passed in.  The magic string in the config file is also
REM replaced with the appropriate MDCEBASE.
REM 

SET POSSIBLY_QUOTED_CCP_SERVICEREGISTRATION_PATH=%1
REM Remove any surrounding double quotes from the path that is passed in.
REM %%~A means "%%A without quotes".  Must use "usebackq" in case 
REM POSSIBLY_QUOTED_CCP_SERVICEREGISTRATION_PATH contains a network path that is not quoted.
FOR /F "usebackq tokens=*" %%A IN ('!POSSIBLY_QUOTED_CCP_SERVICEREGISTRATION_PATH!') DO SET CCP_SERVICEREGISTRATION_PATH=%%~A

IF "%CCP_SERVICEREGISTRATION_PATH%"=="" (
    goto printSyntax
)

REM Check that CCP_SERVICEREGISTRATION_PATH exists
if not exist "%CCP_SERVICEREGISTRATION_PATH%" goto badCCPEnvNotExist

REM Find the original MdcsServiceForPCT.config file
set MDCS_SERVICE_CONFIG_DIR=%MDCEBASE%\config
set CONFIG_FILENAME=MdcsServiceForPCT
set ORIG_MDCS_SERVICE_CONFIG=%MDCS_SERVICE_CONFIG_DIR%\%CONFIG_FILENAME%.config
REM Generate the final version-specific filename for the new config file
FOR /F "delims=" %%I IN ('CALL "%UTILBASE%\getPCTVersion.bat"') DO CALL SET PCT_VERSION=%%I
IF ERRORLEVEL 1 goto failedToGetPCTVersion
set VERSION_SPECIFIC_MDCS_SERVICE_CONFIG=%CCP_SERVICEREGISTRATION_PATH%\%CONFIG_FILENAME%%PCT_VERSION%.config
set MICROSOFT_HPC_SCHEDULER_SESSION_ASSEMBLY_VERSION=2

REM Replace the MDCS base location in the original .config file with the correct one
if exist "%ORIG_MDCS_SERVICE_CONFIG%" (
    if exist "%VERSION_SPECIFIC_MDCS_SERVICE_CONFIG%" (
        echo Warning: !VERSION_SPECIFIC_MDCS_SERVICE_CONFIG! already exists.  This will be overwritten.
    )
    REM These are the strings in the original config file that we need to replace
    set NUM_STRINGS_TO_REPLACE=2
    set MDCS_BASE_DIR_STRING_TO_REPLACE=$MDCS_BASE_DIRECTORY$
    set HPCS_VERSION_STRING_TO_REPLACE=$HPC_SERVER_SCHEDULER_VERSION$

    REM Call the vbs file in batch mode and use the error codes to determine if something went wrong
    cscript /B "%UTILBASE%\replaceStringInFile.vbs" ^
        "%ORIG_MDCS_SERVICE_CONFIG%" "%VERSION_SPECIFIC_MDCS_SERVICE_CONFIG%" ^
        !NUM_STRINGS_TO_REPLACE! ^
        "!MDCS_BASE_DIR_STRING_TO_REPLACE!" "%MDCEBASE%" ^
        "!HPCS_VERSION_STRING_TO_REPLACE!" %MICROSOFT_HPC_SCHEDULER_SESSION_ASSEMBLY_VERSION%

    REM Error codes from replaceStringInFile: 
    REM  1 = failed to read file
    REM  2 = failed to write to destination file
    REM  3 = Incorrect usage of replaceStringInFile (Shouldn't get this)
    if ERRORLEVEL 3 goto failedReplaceStringInternalError
    if ERRORLEVEL 2 goto failedToWriteFile
    if ERRORLEVEL 1 goto failedToReadFile
) else (
    echo Could not find !ORIG_MDCS_SERVICE_CONFIG!
    goto endFAILED
)

GOTO endOK

:printSyntax
ECHO\
ECHO Usage:  createServiceFileForHPCServer serviceRegistrationPath 

GOTO endOK

:badCCPEnvNotExist
echo %CCP_SERVICEREGISTRATION_PATH% does not exist.
goto endFAILED

:failedToGetPCTVersion
echo Failed to determine PCT version.
goto endFAILED

:failedToWriteFile
echo Failed to write file %VERSION_SPECIFIC_MDCS_SERVICE_CONFIG%.  
goto endFAILED

:failedToReadFile
echo Failed to read file %ORIG_MDCS_SERVICE_CONFIG%.  
goto endFAILED

:failedReplaceStringInternalError
echo Internal error occurred when calling replaceStringInFile.
goto endFAILED

:endOK
ENDLOCAL
EXIT /B 0

:endFAILED
ECHO Script %SCRIPTNAME% unable to complete successfully - exiting
ENDLOCAL
EXIT /B 1

