@echo off

:: Copyright 2004-2013 The MathWorks, Inc.

:: NOTE - This file defines all the environment variables that are visible
:: in the wrapper configuration file. If any new environment variables need to
:: be passed in then they need to be added to this script.

:: this is a dummy comment
:: Below is the configuration file we want to write - note the use of delayed variable
:: expansion. If the path were to contain a ')' (as in Program Files (x86)) on the win64
:: platform, then the script exits unexpectedly. This is because the echo commands cannot
:: be protected with a " character.

:: NOTE it is IMPORTANT that all paths in the file below are UNC unless they are local to
:: the machine on which MDCE is running. If they are NOT UNC, MDCE will not work
set CONFIGFILE=%1

(
echo set.JRECMD_FOR_MDCS=!JRECMD_FOR_MDCS!
echo set.JREFLAGS=!JREFLAGS!

echo set.MATBASE=!MATBASE!
echo set.JREBASE=!JREBASE!

echo set.JARBASE=!JARBASE!
echo set.JAREXTBASE=!JAREXTBASE!
echo set.JAREXTBASEUTIL=!JAREXTBASEUTIL!
echo set.JINILIB=!JINILIB!

echo set.MDCE_DEFFILE=!MDCE_DEFFILE!
echo set.MDCEBASE=!MDCEBASE!
echo set.LOGBASE=!UNCLOGBASE!
echo set.CHECKPOINTBASE=!UNCCHECKPOINTBASE!

echo set.ARCH=!ARCH!
echo set.HOSTNAME=!HOSTNAME!

echo set.MDCEUSER=!MDCEUSER!

echo set.WORKER_START_TIMEOUT=!WORKER_START_TIMEOUT!

echo set.MATLAB_EXECUTABLE=!MATLAB_EXECUTABLE!

echo set.JOB_MANAGER_MAXIMUM_MEMORY=!JOB_MANAGER_MAXIMUM_MEMORY!
echo set.MDCEQE_JOBMANAGER_DEBUG_PORT=!MDCEQE_JOBMANAGER_DEBUG_PORT!
echo set.CONFIGBASE=!CONFIGBASE!

echo set.DEFAULT_JOB_MANAGER_NAME=!DEFAULT_JOB_MANAGER_NAME!
echo set.DEFAULT_WORKER_NAME=!DEFAULT_WORKER_NAME!

echo set.JOB_MANAGER_HOST=!JOB_MANAGER_HOST!
echo set.BASE_PORT=!BASE_PORT!

echo set.LOG_LEVEL=!LOG_LEVEL!

echo set.USE_SECURE_COMMUNICATION=!USE_SECURE_COMMUNICATION!
echo set.TRUSTED_CLIENTS=!TRUSTED_CLIENTS!
echo set.SHARED_SECRET_FILE=!SHARED_SECRET_FILE!
echo set.SECURITY_DIR=!SECURITY_DIR!
echo set.DEFAULT_KEYSTORE_PATH=!DEFAULT_KEYSTORE_PATH!
echo set.KEYSTORE_PASSWORD=!KEYSTORE_PASSWORD!
echo set.SECURITY_LEVEL=!SECURITY_LEVEL!
echo set.MDCE_ALLOW_GLOBAL_PASSWORDLESS_LOGON=!MDCE_ALLOW_GLOBAL_PASSWORDLESS_LOGON!
echo set.ALLOW_CLIENT_PASSWORD_CACHE=!ALLOW_CLIENT_PASSWORD_CACHE!
echo set.ADMIN_USER=!ADMIN_USER!
echo set.ALLOWED_USERS=!ALLOWED_USERS!
echo set.WORKER_DOMAIN=!WORKER_DOMAIN!

echo set.MDCS_ALL_SERVER_SOCKETS_IN_CLUSTER=!MDCS_ALL_SERVER_SOCKETS_IN_CLUSTER!
echo set.MDCS_JOBMANAGER_PEERSESSION_PORT=!MDCS_JOBMANAGER_PEERSESSION_PORT!
echo set.MDCS_WORKER_MATLABPOOL_MIN_PORT=!MDCS_WORKER_MATLABPOOL_MIN_PORT!
echo set.MDCS_WORKER_MATLABPOOL_MAX_PORT=!MDCS_WORKER_MATLABPOOL_MAX_PORT!

echo set.MDCS_LIFECYCLE_REPORTER=!MDCS_LIFECYCLE_REPORTER!
echo set.MDCS_LIFECYCLE_WORKER_HEARTBEAT=!MDCS_LIFECYCLE_WORKER_HEARTBEAT!
echo set.MDCS_LIFECYCLE_TASK_HEARTBEAT=!MDCS_LIFECYCLE_TASK_HEARTBEAT!

echo set.MDCS_ADDITIONAL_CLASSPATH=!MDCS_ADDITIONAL_CLASSPATH!

echo set.MDCS_PEER_LOOKUP_SERVICE_ENABLED=!MDCS_PEER_LOOKUP_SERVICE_ENABLED!
echo set.MDCS_PEER_LOOKUP_SERVICE_PORT=!MDCS_PEER_LOOKUP_SERVICE_PORT!

echo set.MDCE_PLATFORM_WRAPPER_CONF=!MDCE_PLATFORM_WRAPPER_CONF!

echo set.MDCS_REQUIRE_WEB_LICENSING=!MDCS_REQUIRE_WEB_LICENSING!

echo set.MDCS_SEND_ACTIVITY_NOTIFICATIONS=!MDCS_SEND_ACTIVITY_NOTIFICATIONS!
echo set.MDCS_SCRIPT_ROOT=!MDCS_SCRIPT_ROOT!

echo set.APPNAME=!APPNAME!
echo set.APP_LONG_NAME=!APP_LONG_NAME!

echo set.RELEASE_LICENSE_WHEN_IDLE=!RELEASE_LICENSE_WHEN_IDLE!
) > "!CONFIGFILE!"

:: If config file exists then exit with errorlevel 0
if exist "!CONFIGFILE!" (
    exit /B 0
) else (
    exit /B 1
)
