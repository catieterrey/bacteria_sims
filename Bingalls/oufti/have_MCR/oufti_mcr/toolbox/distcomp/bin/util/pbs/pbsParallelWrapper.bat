REM PBS -v MDCE_DECODE_FUNCTION,MDCE_STORAGE_LOCATION,MDCE_STORAGE_CONSTRUCTOR,MDCE_JOB_LOCATION,MDCE_CMR,MDCE_MATLAB_EXE,MDCE_MATLAB_ARGS,MDCE_TOTAL_TASKS,MDCE_SCHED_TYPE,MDCE_DEBUG,MLM_WEB_LICENSE,MLM_WEB_USER_CRED,MLM_WEB_ID
REM PBS -j oe

@echo off
REM This wrapper script is used by the pbsscheduler to call MPIEXEC to launch
REM MATLAB on the hosts allocated by PBS. We use "worker.bat" rather than
REM "matlab.bat" to ensure that the exit code from MATLAB is correctly
REM interpreted by MPIEXEC. 
REM
REM The following environment variables must be forwarded to the MATLABs:
REM - MDCE_DECODE_FUNCTION
REM - MDCE_STORAGE_LOCATION
REM - MDCE_STORAGE_CONSTRUCTOR
REM - MDCE_JOB_LOCATION
REM - MDCE_DEBUG
REM 
REM This is done using the "-genvlist" option to MPIEXEC. 
REM

REM Copyright 2006-2012 The MathWorks, Inc.

SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION 

if "x!MDCE_CMR!" == "x" (
  REM No ClusterMatlabRoot set, just call mw_mpiexec and matlab.bat directly.
  set MPIEXEC=mw_mpiexec
) else (
  REM Use ClusterMatlabRoot to find mpiexec wrapper and matlab.bat
  set MPIEXEC="!MDCE_CMR!\bin\mw_mpiexec"
)

set GENVLIST=MDCE_DECODE_FUNCTION,MDCE_STORAGE_LOCATION,MDCE_STORAGE_CONSTRUCTOR,MDCE_JOB_LOCATION,MDCE_DEBUG,MDCE_SCHED_TYPE,MLM_WEB_LICENSE,MLM_WEB_USER_CRED,MLM_WEB_ID

REM The actual call to MPIEXEC. Must use call for the mw_mpiexec.bat wrapper to
REM ensure that we can modify the return code from mpiexec.
echo !MPIEXEC! -noprompt -delegate -l -exitcodes -genvlist %GENVLIST% -machinefile %PBS_NODEFILE% -n %MDCE_TOTAL_TASKS% !MDCE_MATLAB_EXE! %MDCE_MATLAB_ARGS%
call !MPIEXEC! -noprompt -delegate -l -exitcodes -genvlist %GENVLIST% -machinefile %PBS_NODEFILE% -n %MDCE_TOTAL_TASKS% !MDCE_MATLAB_EXE! %MDCE_MATLAB_ARGS%

REM If MPIEXEC exited with code 42, this indicates a call to MPI_Abort from
REM within MATLAB. In this case, we do not wish PBS to think that the job failed
REM - the task error state within MATLAB will correctly indicate the job outcome.
set MPIEXEC_ERRORLEVEL=!ERRORLEVEL!
if %MPIEXEC_ERRORLEVEL% == 42 (
   echo Overwriting MPIEXEC exit code from 42 to zero (42 indicates a user-code failure)
   exit 0
) else (
   exit %MPIEXEC_ERRORLEVEL%
)
