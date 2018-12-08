REM === Setup ===
REM SQL credentials (! no quotes)
set sqlCredentials=-S LK-HP-NEW\SQLEXPRESS
set fileNameRoot=%~dp0log\
REM =================

del /Q %fileNameRoot%*

sqlcmd -d master -C -o %fileNameRoot%_db_setup.txt %sqlCredentials% -i "target\base\db_setup.sql"

for /f %%D in ('dir target\content\*/a:d /b ^| sort') do (
    for /f %%F in ('dir target\content\%%D\ /b ^| sort') do (
        sqlcmd -C -o %fileNameRoot%_%%D_%%F.txt %sqlCredentials% -i "target\content\%%D\%%F"
    )
)

for /f %%F in ('dir target\base\version_control\ /b ^| sort') do (
    sqlcmd -C -o %fileNameRoot%_%%F.txt %sqlCredentials% -i "target\base\version_control\%%F"
)

for /f %%F in ('dir target\content\*/a-d /b ^| sort') do (
    sqlcmd -C -o %fileNameRoot%_%%F.txt %sqlCredentials% -i "target\content\%%F"
)