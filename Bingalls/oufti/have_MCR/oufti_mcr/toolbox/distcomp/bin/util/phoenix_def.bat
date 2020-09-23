@echo off
REM Copyright 2008-2010 The MathWorks, Inc.

REM WARNING - Do not modify any of these properties when an application
REM  using this configuration file has been installed as a service.
REM  Please uninstall the service before modifying this section.  The
REM  service can then be reinstalled.

set APPNAME=mdced
set APP_LONG_NAME=MATLAB Distributed Computing Server

set MDCE_PLATFORM_WRAPPER_CONF=!CONFIGBASE!\wrapper-phoenix-!ARCH!.config
set MATLAB_EXECUTABLE=!MATBASE!\bin\!ARCH!\matlab.exe

exit /b 0
