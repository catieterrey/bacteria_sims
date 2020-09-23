@echo off

REM Copyright 2008-2013 The MathWorks, Inc.


REM ---------------------------------------------
REM Delete all files related to the mdce service
REM The environment variables UTILBASE, CHECKPOINTBASE, LOGBASE and SECURITY_DIR
REM need to be defined before calling this script.
REM DELETE_CONFIG_FILE also needs to be defined, and
REM wrapper-phoenix-environment.config is deleted if and only if its value is 1.
REM ---------------------------------------------

REM Make sure we don't accidentally delete any files by checking whether
REM environment variables are defined.

REM We do not put trailing slashes on directories.
REM We use /Nologo rather than //B because we want error messages from the
REM vbscript to be displayed to the console
if not "%CHECKPOINTBASE%"=="" (
    cscript /Nologo "%UTILBASE%"\deleteFileOrFolder.vbs "%CHECKPOINTBASE%"\*_jobmanager_log
    if ERRORLEVEL 1 GOTO endFAILED
    cscript /Nologo "%UTILBASE%"\deleteFileOrFolder.vbs "%CHECKPOINTBASE%"\*_lookup_log
    if ERRORLEVEL 1 GOTO endFAILED
    cscript /Nologo "%UTILBASE%"\deleteFileOrFolder.vbs "%CHECKPOINTBASE%"\*_mlworker_log
    if ERRORLEVEL 1 GOTO endFAILED
    cscript /Nologo "%UTILBASE%"\deleteFileOrFolder.vbs "%CHECKPOINTBASE%"\*_phoenix_log
    if ERRORLEVEL 1 GOTO endFAILED
    cscript /Nologo "%UTILBASE%"\deleteFileOrFolder.vbs "%CHECKPOINTBASE%"\*_sharedvm_log
    if ERRORLEVEL 1 GOTO endFAILED
    cscript /Nologo "%UTILBASE%"\deleteFileOrFolder.vbs "%CHECKPOINTBASE%"\mdced.pid
    if ERRORLEVEL 1 GOTO endFAILED
    if "%DELETE_CONFIG_FILE%"=="1" (
        cscript /Nologo "%UTILBASE%"\deleteFileOrFolder.vbs "%CHECKPOINTBASE%"\wrapper-phoenix-environment.config
            if ERRORLEVEL 1 GOTO endFAILED
    )
    if "%PRESERVEJOBS%"=="0" (
        cscript /Nologo "%UTILBASE%"\deleteFileOrFolder.vbs "%CHECKPOINTBASE%"\*_jobmanager_storage
            if ERRORLEVEL 1 GOTO endFAILED
    )
)
if not "%LOGBASE%"=="" (
    cscript /Nologo "%UTILBASE%"\deleteFileOrFolder.vbs "%LOGBASE%"\jobmanager_*.log
    if ERRORLEVEL 1 GOTO endFAILED
    cscript /Nologo "%UTILBASE%"\deleteFileOrFolder.vbs "%LOGBASE%"\jobmanager_*.lck
    if ERRORLEVEL 1 GOTO endFAILED
    cscript /Nologo "%UTILBASE%"\deleteFileOrFolder.vbs "%LOGBASE%"\worker-*.log
    if ERRORLEVEL 1 GOTO endFAILED
    cscript /Nologo "%UTILBASE%"\deleteFileOrFolder.vbs "%LOGBASE%"\worker-*.lck
    if ERRORLEVEL 1 GOTO endFAILED
    cscript /Nologo "%UTILBASE%"\deleteFileOrFolder.vbs "%LOGBASE%"\mdce-service.log
    if ERRORLEVEL 1 GOTO endFAILED
)
if not "%SECURITY_DIR%"=="" (
    REM Delete the security files only if we aren't preserving the database, otherwise
    REM we may not be able to read the jobs stored in the database in the future.
    if "%PRESERVEJOBS%"=="0" (
        cscript /Nologo "%UTILBASE%"\deleteFileOrFolder.vbs "%SECURITY_DIR%"\aes_private
        if ERRORLEVEL 1 GOTO endFAILED
        cscript /Nologo "%UTILBASE%"\deleteFileOrFolder.vbs "%SECURITY_DIR%"\public
        if ERRORLEVEL 1 GOTO endFAILED
        cscript /Nologo "%UTILBASE%"\deleteFileOrFolder.vbs "%SECURITY_DIR%"\private
        if ERRORLEVEL 1 GOTO endFAILED
    )
)

EXIT /B 0

:endFAILED
EXIT /B 1

