REM For job arrays - calculate MDCE_TASK_ID from PBS_ARRAY_INDEX
set MDCE_TASK_ID=%PBS_ARRAY_INDEX%

for %%x in ( <SKIP_LIST> ) do (
    if %PBS_ARRAY_INDEX% GEQ %%x set /a MDCE_TASK_ID=1 + !MDCE_TASK_ID!
)
