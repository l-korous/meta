@echo off
REM =================
REM %1 Model XML path
set templatesPath=%~dp0templates
set targetPath=%~dp0target
REM =================
IF %1.==. GOTO NoParam

REM Delete target
del /Q %targetPath%\*

for /f %%F in ('dir %templatesPath%\*/a-d /b ^| sort') do call :MakeCall %%F, %1
echo  Generation successful.
goto :eof

:NoParam
    echo "usage: generage_target.bat <xmlModelFile>"
    goto :eof
    
:MakeCall
    echo|set /p="."
    set file=%~1
    set model=%~2
    xsltproc --stringparam metaDbName meta3 %templatesPath%\%file% %model% > %targetPath%\%file:~0, -5%.sql