@ECHO off

REM Copyright 2010 The MathWorks, Inc.

REM Localize environment and enable command extensions
SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

REM Get the current PCT Version string by calling into Java.  The version
REM string is written to stdout.

REM Add the JRE Environment
CALL "%UTILBASE%\setJREEnv.bat"
IF ERRORLEVEL 1 goto endFAILED

SET JAVA_UTIL_VERSION_COMMAND="%JRECMD%" ^
    -classpath "%DISTCOMP_ONLY_CLASSPATH%" ^
    com.mathworks.toolbox.distcomp.util.Version
REM Call the Java command and store the output in PCT_VERSION
FOR /F "delims=" %%I IN ('CALL %JAVA_UTIL_VERSION_COMMAND%') DO CALL SET PCT_VERSION=%%I
IF ERRORLEVEL 1 goto endFAILED

REM Write the version to stdout
ECHO %PCT_VERSION%
GOTO endOK

:endOK
ENDLOCAL
EXIT /B 0

:endFAILED
ENDLOCAL
EXIT /B 1

