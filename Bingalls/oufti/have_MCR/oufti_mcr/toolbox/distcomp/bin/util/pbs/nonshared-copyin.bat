REM Non-shared filesystem - overwrite MDCE_STORAGE_LOCATION
set MDCE_STORAGE_LOCATION=%CD%

REM Generate the means of sleeping
echo Set Args = Wscript.Arguments >  %CD%\sleep.vbs
echo wscript.sleep Args(0)*1000   >> %CD%\sleep.vbs

REM Subroutine for copying files with retry
goto :afterCopy
:copyWithRetry
for %%i in ( 1 2 3 4 5 ) do (
    echo Copying from %2 to %3
    "%1" "%2" "%3"
    if !ERRORLEVEL! EQU 0 exit /b 0
    cscript //B !CD!\sleep.vbs %%i
)
echo Failed to copy from %2 to %3
exit /b 1
:afterCopy

echo "Copying in files to %CD%"

<COPY_FILES>

