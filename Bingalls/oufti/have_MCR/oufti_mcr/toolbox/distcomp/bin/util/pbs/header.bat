<HEADERS>

REM Copyright 2007-2012 The MathWorks, Inc.

if "x%MDCE_DECODE_FUNCTION%" == "x" (
    @echo Fatal error: environment variable MDCE_DECODE_FUNCTION is not set on the cluster
    @echo This may happen if you have used '-v' in your scheduler SubmitArguments
    @echo Please either use another means to transmit the information, or use '-V'
    exit /b 1
)
        

setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

cd /d %TMPDIR%
