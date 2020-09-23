@ECHO off

REM Copyright 2010-2012 The MathWorks, Inc.

REM Check setbase has been called
IF NOT DEFINED MATBASE (
    ECHO Error: setbase.bat must be called before %~nx0
    goto endFAILED
)

SET JREBASE=%MATBASE%\sys\java\jre\%MATLAB_ARCH%\jre
SET JRECMD=%JREBASE%\bin\java
SET JRECMD_FOR_MDCS=%JREBASE%\bin\javaw
SET JRECMD_NO_CONSOLE=%JREBASE%\bin\javaw

goto endOK

:endOK
EXIT /B 0

:endFAILED
EXIT /B 1

