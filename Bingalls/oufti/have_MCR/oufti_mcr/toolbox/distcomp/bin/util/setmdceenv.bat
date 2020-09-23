@echo off

REM Copyright 2004-2013 The MathWorks, Inc.

REM this is a dummy comment

REM Set the location
REM We should probably call setJREEnv.bat from the batch files that require
REM it in toolbox\distcomp\bin rather than doing it in here.
call "%UTILBASE%\setJREEnv.bat"
IF ERRORLEVEL 1 goto endFAILED

set KEYTOOLCMD=%JREBASE%\bin\keytool
set JREFLAGS=-MDCE_DUMMY

REM limit memory and number of GC threads to something reasonable.
set COMMANDLINEJREMEMORY=-Xmx128m
set SWINGJREMEMORY=-Xmx1024m
set COMMANDLINEJREGC=-XX:ParallelGCThreads=2
set SWINGJREGC=-XX:ParallelGCThreads=4

REM Make sure we have the system temp environment variable rather than the user temp
REM NOTE CALL to expand any nested environment variables in the system temp value
for /F "delims=" %%i in ('call cscript //B "%UTILBASE%\systemenv.vbs" get TEMP') do call set TEMP=%%i

REM Deal with any overrides to the mdce_def file
if defined MDCEQE_DEFFILE if not defined MDCE_DEFFILE (
    set MDCE_DEFFILE=%MDCEQE_DEFFILE%
)
REM If no one has set the mdce_def file then set the default
if not defined MDCE_DEFFILE set MDCE_DEFFILE=%MDCEBASE%\bin\mdce_def.bat

REM Call the MDCE definition file
if exist "%MDCE_DEFFILE%" (
    call "%MDCE_DEFFILE%"
) else (
    REM NB It is very important to use delayed expansion for MDCE_DEFFILE
    REM in this echo line - just in case the MDCE_DEFFILE path contains
    REM parentheses.
    echo Unable to read MDCE definition file !MDCE_DEFFILE!
    goto endFAILED
)

REM Test if JOB_MANAGER_HOST string is empty - A dummy non-empty value must be provided
if "%JOB_MANAGER_HOST%"=="" (
    set JOB_MANAGER_HOST=MDCE_LOOKUP_NOT_SPECIFIED
)

REM Test if SHARED_SECRET_FILE string is empty - A dummy non-empty value must be provided
if "%SHARED_SECRET_FILE%"=="" (
    set SHARED_SECRET_FILE=KEYSTORE_PATH_NOT_SPECIFIED
)

REM Test if MDCE_ALLOW_GLOBAL_PASSWORDLESS_LOGON string is empty in which
REM case we set it to false.
if "%MDCE_ALLOW_GLOBAL_PASSWORDLESS_LOGON%"=="" (
    set MDCE_ALLOW_GLOBAL_PASSWORDLESS_LOGON=false
)
REM Test if ADMIN_USER string is empty in which case we set it to 'admin'.
if "%ADMIN_USER%"=="" (
    set ADMIN_USER=admin
)

REM Test if LOG_LEVEL string is empty. If so, a default value of 0 must be provided
if "%LOG_LEVEL%"=="" (
    set LOG_LEVEL=0
)
REM Test if TRUSTED_CLIENTS string is empty, if so, set to default value "true"
if "%TRUSTED_CLIENTS%"=="" (
   set TRUSTED_CLIENTS=true
)

REM Default to not use web licensing
if "%MDCS_REQUIRE_WEB_LICENSING%"=="" (
    set MDCS_REQUIRE_WEB_LICENSING=false
)

REM For backwards-compatibility keep ONLINE_LICENSE_MANAGEMENT as a
REM synonym for USE_MATHWORKS_HOSTED_LICENSE_MANAGER
IF DEFINED ONLINE_LICENSE_MANAGEMENT (
    SET MDCS_REQUIRE_WEB_LICENSING=%ONLINE_LICENSE_MANAGEMENT%   
)

REM If USE_MATHWORKS_HOSTED_LICENSE_MANAGER is set, use it. The value
REM of this flag will override ONLINE_LICENSE_MANAGEMENT
IF DEFINED USE_MATHWORKS_HOSTED_LICENSE_MANAGER (
    SET MDCS_REQUIRE_WEB_LICENSING=%USE_MATHWORKS_HOSTED_LICENSE_MANAGER%
)

REM Default is to have some server sockets on the clients
IF "%MDCS_ALL_SERVER_SOCKETS_IN_CLUSTER%"=="" (
   SET MDCS_ALL_SERVER_SOCKETS_IN_CLUSTER=false
)

REM Default is not to start the peer lookup service
IF "%MDCS_PEER_LOOKUP_SERVICE_ENABLED%"=="" (
   SET MDCS_PEER_LOOKUP_SERVICE_ENABLED=false
)

REM If the ports have not been specified fill in the defaults
IF "%MDCS_PEER_LOOKUP_SERVICE_PORT%"=="" (
   SET MDCS_PEER_LOOKUP_SERVICE_PORT=14350
)

IF "%MDCS_JOBMANAGER_PEERSESSION_PORT%"=="" (
   SET MDCS_JOBMANAGER_PEERSESSION_PORT=14351
)

REM Default is not to proxy communication
IF "%MDCS_WORKER_PROXIES_POOL_CONNECTIONS%"=="" (
   SET MDCS_WORKER_PROXIES_POOL_CONNECTIONS=false
)

IF "%MDCS_WORKER_MATLABPOOL_MIN_PORT%"=="" (
   SET MDCS_WORKER_MATLABPOOL_MIN_PORT=14352
)

IF "%MDCS_WORKER_MATLABPOOL_MAX_PORT%"=="" (
   SET MDCS_WORKER_MATLABPOOL_MAX_PORT=14416
)

IF "%MDCS_ADDITIONAL_CLASSPATH%"=="" (
   SET MDCS_ADDITIONAL_CLASSPATH=MDCS_ADDITIONAL_CLASSPATH_NOT_SPECIFIED
)

REM Default settings for lifecycle reporting
IF "%MDCS_LIFECYCLE_REPORTER%"=="" (
   SET MDCS_LIFECYCLE_REPORTER=com.mathworks.toolbox.distcomp.worker.sessiontracking.LoggingLifecycleReporter
)

IF "%MDCS_LIFECYCLE_WORKER_HEARTBEAT%"=="" (
   SET MDCS_LIFECYCLE_WORKER_HEARTBEAT=600
)

IF "%MDCS_LIFECYCLE_TASK_HEARTBEAT%"=="" (
   SET MDCS_LIFECYCLE_TASK_HEARTBEAT=60
)

REM Set default on-demand flag
IF NOT DEFINED RELEASE_LICENSE_WHEN_IDLE (
   set RELEASE_LICENSE_WHEN_IDLE=false
)

IF "%MDCS_SEND_ACTIVITY_NOTIFICATIONS%"=="" (
   SET MDCS_SEND_ACTIVITY_NOTIFICATIONS=false
)

IF NOT DEFINED MDCS_SCRIPT_ROOT (
   SET MDCS_SCRIPT_ROOT=
)

REM The next section allows command line arguments and MDCEQE_ variables 
REM to override mdce_def file settings.  

REM Allow a user to override the default base port
if defined MDCEQE_BASE_PORT (
    set BASE_PORT=%MDCEQE_BASE_PORT%
)

if defined MDCEQE_LOGBASE (
    set LOGBASE=%MDCEQE_LOGBASE%
)

if defined MDCEQE_CHECKPOINTBASE (
    set CHECKPOINTBASE=%MDCEQE_CHECKPOINTBASE%
)

REM Setting MDCEUSER means we ought to unset MDCEPASS because it would
REM be mad to use a different user and still want the possible password
REM in mdce_def.bat
if defined MDCEQE_MDCEUSER (
    set MDCEUSER=%MDCEQE_MDCEUSER%
    set MDCEPASS=
)

if defined MDCEQE_MDCEPASS (
    set MDCEPASS=%MDCEQE_MDCEPASS%
)

if defined MDCEQE_HOSTNAME (
    set HOSTNAME=%MDCEQE_HOSTNAME%
)

if defined MDCEQE_USE_SECURE_COMMUNICATION (
    set USE_SECURE_COMMUNICATION=%MDCEQE_USE_SECURE_COMMUNICATION%
)

if defined MDCEQE_TRUSTED_CLIENTS (
   set TRUSTED_CLIENTS=%MDCEQE_TRUSTED_CLIENTS%
)

if defined MDCEQE_SHARED_SECRET_FILE (
    set SHARED_SECRET_FILE=%MDCEQE_SHARED_SECRET_FILE%
)

if defined MDCEQE_SECURITY_LEVEL (
    set SECURITY_LEVEL=%MDCEQE_SECURITY_LEVEL%
)

if defined MDCEQE_REQUIRE_WEB_LICENSING (
    set MDCS_REQUIRE_WEB_LICENSING=%MDCEQE_REQUIRE_WEB_LICENSING%
)

if defined MDCEQE_ALLOW_CLIENT_PASSWORD_CACHE (
    set ALLOW_CLIENT_PASSWORD_CACHE=%MDCEQE_ALLOW_CLIENT_PASSWORD_CACHE%
)

if defined MDCEQE_ALLOWED_USERS (
    set ALLOWED_USERS=%MDCEQE_ALLOWED_USERS%
)

if defined MDCEQE_WORKER_DOMAIN (
    set WORKER_DOMAIN=%MDCEQE_WORKER_DOMAIN%
)

IF DEFINED MDCEQE_ALL_SERVER_SOCKETS_IN_CLUSTER (
   SET MDCS_ALL_SERVER_SOCKETS_IN_CLUSTER=%MDCEQE_ALL_SERVER_SOCKETS_IN_CLUSTER%
)

IF DEFINED MDCEQE_JOBMANAGER_PEERSESSION_PORT (
   SET MDCS_JOBMANAGER_PEERSESSION_PORT=%MDCEQE_JOBMANAGER_PEERSESSION_PORT%
)

IF DEFINED MDCEQE_WORKER_PROXIES_POOL_CONNECTIONS (
   SET MDCS_WORKER_PROXIES_POOL_CONNECTIONS=%MDCEQE_WORKER_POOL_CONNECTIONS%
)

IF DEFINED MDCEQE_WORKER_MATLABPOOL_MIN_PORT (
   SET MDCS_WORKER_MATLABPOOL_MIN_PORT=%MDCEQE_WORKER_MATLABPOOL_MIN_PORT%
)

IF DEFINED MDCEQE_WORKER_MATLABPOOL_MAX_PORT (
   SET MDCS_WORKER_MATLABPOOL_MAX_PORT=%MDCEQE_WORKER_MATLABPOOL_MAX_PORT%
)

IF DEFINED MDCEQE_WORKER_ONDEMAND (
	SET RELEASE_LICENSE_WHEN_IDLE=%MDCEQE_WORKER_ONDEMAND%
)

IF DEFINED MDCEQE_PEER_LOOKUP_SERVICE_ENABLED (
   SET MDCS_PEER_LOOKUP_SERVICE_ENABLED=%MDCEQE_PEER_LOOKUP_SERVICE_ENABLED%
)

IF DEFINED MDCEQE_SEND_ACTIVITY_NOTIFICATIONS (
    SET MDCS_SEND_ACTIVITY_NOTIFICATIONS=%MDCEQE_SEND_ACTIVITY_NOTIFICATIONS%
)

REM Set other security relevant properties.
set SECURITY_DIR=%CHECKPOINTBASE%\security
set DEFAULT_KEYSTORE_PATH=%SECURITY_DIR%\secret
set KEYSTORE_PASSWORD=privatepw
set KEYSTORE_ALIAS=SHARED_SECRET

REM Ensure that we have UNC versions of LOGBASE and CHECKPOINTBASE for MDCE to
REM use. However, for some things we need the original as grantUserRights often
REM fails on a UNC path
for /F "delims=" %%i in ('call cscript //B "%UTILBASE%\convertToUNC.vbs" "%LOGBASE%"') do call set UNCLOGBASE=%%i
for /F "delims=" %%i in ('call cscript //B "%UTILBASE%\convertToUNC.vbs" "%CHECKPOINTBASE%"') do call set UNCCHECKPOINTBASE=%%i


REM Verify that the host name does not contain an underscore.
if defined VALIDATE_HOSTNAME (
    if not "!HOSTNAME!"=="!HOSTNAME:_=!" (
        echo The host name  !HOSTNAME!  is invalid because it contains an underscore, _.
        echo Only letters, digits, and dash characters are legal in host names.
        echo\
        echo The host name that MDCE uses is obtained from the MDCE definition file
        echo !MDCE_DEFFILE!
        goto endFAILED
    )
)

REM The REMOTE_HOSTNAME variable defaults to HOSTNAME.
set REMOTE_HOSTNAME=%HOSTNAME%

:endOK
EXIT /B 0
:endFAILED
ECHO FAILED
EXIT /B 1

