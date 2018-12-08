@echo off
REM === Setup ===
REM SQL credentials (! no quotes)
set sqlCredentials=-S LK-HP-NEW\SQLEXPRESS
set fileNameRoot=%~dp0log\
REM =================

IF %1.==. GOTO NoParam
IF %2.==. GOTO NoParam

bcp  "CREATE TABLE #model( _table nvarchar(max), _column nvarchar(max), _is_primary_key nvarchar(max), _is_unique nvarchar(max), _datatype nvarchar(max), _is_nullable nvarchar(max), _references nvarchar(max), _on_delete nvarchar(max) ); BULK INSERT #model FROM """%1""" WITH ( FIRSTROW = 2, FIELDTERMINATOR = ',' ); SELECT _table._table, (select _column, _is_primary_key, _is_unique, _datatype, _is_nullable, _references, _on_delete FROM #model _column where _column._table = _table._table for xml auto, type) FROM (select distinct _table from #model) _table FOR XML auto, root ('tables')" queryout %2 -c -T %sqlCredentials%
goto :eof


:NoParam
    @echo on
    echo "usage: csv_to_xml.bat <csvInputFileName> <xmlOutputFileName>"