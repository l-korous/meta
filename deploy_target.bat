@echo off
REM === Setup ===
REM SQL credentials (! no quotes)
set sqlCredentials=-S LK-HP-NEW\SQLEXPRESS
set logDir=%~dp0log
set targetPath=%~dp0target
REM =================

REM Delete logs
del /Q %logDir%*

REM Deploy
for /f %%F in ('dir %targetPath%\*/a-d /b ^| sort') do (
    echo|set /p="."
    sqlcmd -b -C -o %logDir%/%%F.txt %sqlCredentials% -i "%targetPath%\%%F" -f 65001
    IF ERRORLEVEL 1 goto err_handler
)
echo  Deployment successful.
goto :eof

:err_handler
echo Errors occured, deployment NOT successful.