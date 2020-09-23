call :copyWithRetry "<RCP>" "<IN>" "<OUT>"
if %ERRORLEVEL% NEQ 0 ( 
   echo Error copying from "<IN>" to "<OUT>" 
   exit /b 1
)