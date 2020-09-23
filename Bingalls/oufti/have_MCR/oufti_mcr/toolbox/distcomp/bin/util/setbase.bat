
REM Copyright 2004-2013 The MathWorks, Inc.

REM this is a dummy comment
REM This batch file sets some base directory information for use 
REM in following scripts. It is assumed that an environment variable
REM BASE exists which is the toolbox\distcomp\bin\ directory in mdce

REM Convert the script directory from using a mapped drive into using a UNC path,
REM or leave it unmodified if it is not using a mapped drive.
for /F "delims=" %%i in ('call cscript //B "%BASE%\util\convertToUNC.vbs" "%BASE%"') do call set BASE=%%i

REM Remove \toolbox\distcomp\bin\ from BASE to get MATBASE
SET MATBASE=%BASE:\toolbox\distcomp\bin\=%
SET MDCEBASE=%MATBASE%\toolbox\distcomp
SET CONFIGBASE=%MDCEBASE%\config
SET UTILBASE=%MDCEBASE%\bin\util

REM Figure out whether we are running on win64 or win32.  This is from matlab.bat
REM Note that we need MATBASE to be defined before we choose which architecture 
REM to use.
set CPU=x86
if "%PROCESSOR_ARCHITECTURE%" == "AMD64" (
  set CPU=x64
) else if "%PROCESSOR_ARCHITEW6432%" == "AMD64" (
  set CPU=x64
)

set MATLAB_ARCH=win32
if "%CPU%" == "x64" (
  if exist "%MATBASE%\bin\win64" (
    set MATLAB_ARCH=win64
  ) else (
    set CPU=x86
  )
)

REM Set the ARCH
set ARCH=!MATLAB_ARCH!

set BINBASE=%MDCEBASE%\bin\%ARCH%
SET MATBINARCH=%MATBASE%\bin\%ARCH%
SET JARBASE=%MATBASE%\java\jar\toolbox
SET JAREXTBASEUTIL=%MATBASE%\java\jarext
SET JAREXTBASE=%MATBASE%\java\jarext\distcomp
SET JINILIB=%JAREXTBASE%\jini2\lib
SET MATJARBASE=%MATBASE%\java\jar

REM The jars required to make remote commands to start/stop services
SET REMOTE_COMMAND_REQS=%JINILIB%\start.jar;%JINILIB%\destroy.jar;%JINILIB%\phoenix.jar;%JINILIB%\reggie.jar;%JINILIB%\jini-ext.jar
REM The jars required to use remote execution
SET REMOTE_EXECUTION_REQS=%MATBASE%\java\jarext\jsch.jar


SET DISTCOMP_ONLY_CLASSPATH=%JARBASE%\distcomp.jar;%JARBASE%\parallel\pctutil.jar;%JARBASE%\parallel\util.jar

SET MAT_UTIL_JAR=%MATJARBASE%\util.jar
SET MAT_FOUNDATION_JAR=%MATJARBASE%\foundation_libraries.jar
SET DISTCOMP_REQS=%JAREXTBASEUTIL%\commons-lang.jar
SET MAT_RESOURCE_CORE=%MATJARBASE%\resource_core.jar
SET MAT_PARALLEL_RES=%MATJARBASE%\resources\parallel_res.jar

REM The classpath that all the start and stop scripts should use.
SET REMOTE_COMMAND_CLASSPATH=%DISTCOMP_ONLY_CLASSPATH%;%REMOTE_COMMAND_REQS%;%MAT_UTIL_JAR%;%DISTCOMP_REQS%;%MAT_FOUNDATION_JAR%;%MAT_RESOURCE_CORE%;%MAT_PARALLEL_RES%
REM The classpath that all the remote scripts should use
SET REMOTE_EXECUTION_CLASSPATH=%DISTCOMP_ONLY_CLASSPATH%;%REMOTE_EXECUTION_REQS%;%MAT_UTIL_JAR%;%DISTCOMP_REQS%;%MAT_FOUNDATION_JAR%;%MAT_RESOURCE_CORE%;%MAT_PARALLEL_RES%

REM Default user to run MDCS as on windows
set SYSTEMUSER=.\LocalSystem

REM Library path for the java
set NATIVE_LIBRARY_PATH=%MATBASE%\bin\%ARCH%
set PATH=%PATH%;%NATIVE_LIBRARY_PATH%
goto endOK

:endOK
EXIT /B 0
