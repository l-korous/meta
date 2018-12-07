REM === NASTAVENI ===
REM SQL credentials (! bez uvozovek)
set sqlCredentials=-S LK-HP-NEW\SQLEXPRESS

REM smaze prechozi logy
set fileNameRoot=%~dp0log\
del /Q %fileNameRoot%*

sqlcmd -d master -C -o %fileNameRoot%_db_setup.txt %sqlCredentials% -i "base\db_setup.sql"

for /f %%D in ('dir content\*/a:d /b ^| sort') do (
    for /f %%F in ('dir content\%%D\ /b ^| sort') do (
        sqlcmd -d master -C -o %fileNameRoot%_%%D_%%F.txt %sqlCredentials% -i "content\%%D\%%F"
    )
)

for /f %%F in ('dir base\version_control\ /b ^| sort') do (
    sqlcmd -d master -C -o %fileNameRoot%_%%F.txt %sqlCredentials% -i "base\version_control\%%F"
)

sqlcmd -d master -C -o %fileNameRoot%_fk.txt %sqlCredentials% -i "content\fk.sql"