@echo off
REM =================
REM %1 Model XML path
REM =================
IF %1.==. GOTO NoParam

for /f %%D in ('dir templates\*/a:d /b ^| sort') do (
    for /f %%F in ('dir templates\%%D\ /b ^| sort') do call :MakeCall %%D, %%F, %1
)
goto :eof

:NoParam
    @echo on
    echo "usage: generage_target.bat <xmlModelFile>"
    goto :eof
    
:MakeCall
    set dir=%~1
    set file=%~2
    set model=%~3
    echo "xsltproc --stringparam metaDbName meta3 templates\%dir%\%file% %model% > ..\target\%dir%\%file:~0, -5%.sql"
    xsltproc --stringparam metaDbName meta3 templates\%dir%\%file% %model% > ..\target\%dir%\%file:~0, -5%.sql
    goto :eof