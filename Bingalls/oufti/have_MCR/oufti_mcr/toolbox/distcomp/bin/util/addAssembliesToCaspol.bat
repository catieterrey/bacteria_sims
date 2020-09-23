@echo off

REM Copyright 2008-2010 The MathWorks, Inc.

REM this is a dummy comment
REM Localize environment and enable command extensions
SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

REM Check setbase has been called
IF NOT DEFINED MATBASE (
    GOTO errorSetBaseNotCalled
)

REM This script will add all the .NET assemblies that form part of PCT and MDCS to 
REM the MathWorks_Zone in the .NET Code Access Security Policy.  


if "%1"=="-client" (
    set ADD_PCT_ASSEMBLIES=1
    shift
) else (
    if "%1"=="-cluster" (
        set ADD_MDCS_ASSEMBLIES=1
        shift
    ) else (
        if "%1"=="-all" (
            set ADD_PCT_ASSEMBLIES=1
            set ADD_MDCS_ASSEMBLIES=1
            shift
        ) else (
            goto printSyntax
        )
    )
)

REM The cscript command to run the vbs file that will add assemblies to the MathWorks_Zone
SET VBS_COMMAND_TO_RUN=cscript /nologo "%MATBASE%\toolbox\matlab\winfun\private\addAssemblyToDotnetMathWorksZone.vbs"

REM Loop through all assemblies listed in clientAssemblies.list
if defined ADD_PCT_ASSEMBLIES (
    FOR /F "usebackq eol=# tokens=1,2 delims=," %%I IN ("%UTILBASE%\clientAssemblies.list") do (
        call %VBS_COMMAND_TO_RUN% "%%I" "%%J"
        if ERRORLEVEL 1 goto endFAILED
    )
)

REM Loop through all assemblies listed in workerAssemblies.list
if defined ADD_MDCS_ASSEMBLIES (
    FOR /F "usebackq eol=# tokens=1,2 delims=," %%I IN ("%UTILBASE%\workerAssemblies.list") do (
        call %VBS_COMMAND_TO_RUN% "%%I" "%%J"
        if ERRORLEVEL 1 goto endFAILED
    )
)

goto endOK


: printSyntax
echo\
echo addAssembliesToCaspol: Add .NET assemblies used in Parallel Computing
echo                        Toolbox and MATLAB Distributed Computing Server
echo                        to the Microsoft .NET Code Access Security Policy.
echo                        This may need to be done if either product is run
echo                        from a network installation.
echo\
echo Usage:  addAssembliesToCaspol [ -client ^| -cluster ^| -all ]
echo\
echo -client                Add the .NET assemblies used in Parallel Computing
echo                        Toolbox to the Microsoft .NET Code Access Security
echo                        Policy.
echo\
echo -cluster               Add the .NET assemblies used in MATLAB Distributed
echo                        Computing Server to the Microsoft .NET Code Access
echo                        Security Policy.
echo\
echo -all                   Add the .NET assemblies used in both Parallel 
echo                        Computing Toolbox and MATLAB Distributed Computing 
echo                        Server to the Microsoft .NET Code Access Security 
echo                        Policy.
echo\


:errorSetBaseNotCalled
ECHO Error: setbase.bat must be called before %~nx0
GOTO endFAILED


:endOK
ENDLOCAL
EXIT /B 0


:endFAILED
ENDLOCAL
EXIT /B 1

