@ECHO off

REM Copyright 2010 The MathWorks, Inc.

REM Localize environment and enable command extensions
SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

REM Share a folder on the network, creating it if it doesn't already exist.
REM If the share name is already in use, this will delete the existing share
REM and replace it with this one.
REM See the printSyntax label for details on the syntax.

REM Share location and share name must always be specified
SET POSSIBLY_QUOTED_SHARE_LOCATION=%1
SET POSSIBLY_QUOTED_SHARE_NAME=%2
IF NOT DEFINED POSSIBLY_QUOTED_SHARE_LOCATION GOTO printSyntax
IF NOT DEFINED POSSIBLY_QUOTED_SHARE_NAME GOTO printSyntax

REM Remove surrounding quotes from the share location and share name
FOR /F "usebackq tokens=*" %%A IN ('!POSSIBLY_QUOTED_SHARE_LOCATION!') DO SET SHARE_LOCATION=%%~A
FOR /F "usebackq tokens=*" %%A IN ('!POSSIBLY_QUOTED_SHARE_NAME!') DO SET SHARE_NAME=%%~A

REM Check that we've been given a drive letter by searching for a colon.
REM Note the escaping of "|" in the CALL.  Use delayed expansion
REM in case SHARE_LOCATION contains parentheses
FOR /F "tokens=*" %%i IN ('CALL ECHO !SHARE_LOCATION! ^| findstr /C:":"') DO SET DRIVE_LETTER_EXISTS=%%i
IF "%DRIVE_LETTER_EXISTS%"=="" GOTO printSyntax

REM Set default permissions to full control.  
SET SHARE_PERMISSIONS=FULL

REM Don't bother setting default share remarks - if they are not passed in, then
REM it will just be expanded to empty later.

REM Now parse the optional args
:shift2
SHIFT

:shift1
SHIFT

IF "%1"=="-description" (
    SET SHARE_REMARKS=%2
    GOTO shift2
) 
IF "%1"=="-R" (
    SET SHARE_PERMISSIONS=READ
    GOTO shift1
) 

REM We only reach this point once we have exhausted all valid arguments.
IF NOT "%1"=="" (
    GOTO printSyntax
)

REM Create the share location if it doesn't exist
IF NOT EXIST "%SHARE_LOCATION%" (
    ECHO Creating folder !SHARE_LOCATION!
    MKDIR "%SHARE_LOCATION%"
)

REM ECHO    Sharing folder %SHARE_LOCATION% as %SHARE_NAME%
SET NET_SHARE=net share
SET NET_SHARE_COMMAND_REMARKS_FLAG=/Remark:
SET NET_SHARE_COMMAND_DELETE_FLAG=/delete
REM NB the /grant option exists only in Vista onwards (and not in XP)
SET NET_SHARE_GRANT_PERMISSIONS_FLAG=/grant:everyone,%SHARE_PERMISSIONS%

REM Delete the share if it already exists.  "net share" will list the 
REM current shares, so see if we can find the share name in that list.
FOR /F "tokens=*" %%i IN ('CALL %NET_SHARE% ^| findstr /I /C:"%SHARE_NAME%"') DO (
    SET SHARE_FOUND=%%i
)
IF NOT "%SHARE_FOUND%"=="" (
    CALL %NET_SHARE% "%SHARE_NAME%" %NET_SHARE_COMMAND_DELETE_FLAG%
)

REM Share the folder with the specified name
REM Start by calling the net share command with the /grant flag.  This will
REM always fail if we are on XP (the /grant option was introduced in Vista)
REM so we'll have to check for an error and try it again without the grant 
REM flag.  Note that this is not ideal, since this could result in a shared 
REM folder on Windows 7/Vista where users do not have write access.  
REM Annoyingly, there is no easy way to determine the exact Windows version - 
REM the ver command returns the same version number for Windows Server 2008 
REM and Windows 7.  You can get the product name as a string from the registry, 
REM but having to do string parsing is not a robust way of determining the version.
REM
REM Note that if this script was not called with the -description flag, then 
REM %SHARE_REMARKS% will just expand to empty, which is OK.
SET NET_SHARE_WITHOUT_GRANT=%NET_SHARE% "%SHARE_NAME%"="%SHARE_LOCATION%" %NET_SHARE_COMMAND_REMARKS_FLAG%%SHARE_REMARKS%

REM Ensure we redirect the stderr to NUL to avoid the net share syntax being echoed
REM to stdout in XP.
CALL %NET_SHARE_WITHOUT_GRANT% %NET_SHARE_GRANT_PERMISSIONS_FLAG% 2>NUL

IF ERRORLEVEL 1 (
    REM Calling net share with /grant failed, so try without the grant flag
    REM If this still fails, then something really went wrong.
    CALL %NET_SHARE_WITHOUT_GRANT%
    IF ERRORLEVEL 1 GOTO endFAILED
)

goto endOK

:printSyntax
ECHO\
ECHO createSharedFolder:    Share a folder on Windows, creating it if it does not 
ECHO                        already exist.
ECHO\
ECHO Usage:  createSharedFolder drive:folder sharename [-description "text"] [ -R ]
ECHO\
ECHO -description           The description of the file share.  
ECHO\
ECHO -R                     Everyone is granted read access only.  This is ignored 
ECHO                        when run on Windows XP.
ECHO\
ECHO By default, everyone is granted full control to the share.  To change this,
ECHO use the -R option.

GOTO endFAILED

:endOK
ENDLOCAL
EXIT /B 0

:endFAILED
ENDLOCAL
EXIT /B 1

