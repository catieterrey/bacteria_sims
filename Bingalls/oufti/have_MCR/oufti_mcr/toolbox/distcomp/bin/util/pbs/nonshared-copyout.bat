echo "Copying resulting files back to the client"

<COPY_FILES>

if not "%ERRORLEVEL%"=="0" (
  echo "An error ocurred copying files to client, exiting"
  exit 1
)

