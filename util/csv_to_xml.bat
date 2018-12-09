@echo off
REM === Setup ===
REM SQL credentials (! no quotes)
set sqlCredentials=-S LK-HP-NEW\SQLEXPRESS
set fileNameRoot=%~dp0log\
REM =================

IF %1.==. GOTO NoParam
IF %2.==. GOTO NoParam

bcp  "CREATE TABLE #model( _table nvarchar(max), _column nvarchar(max), _is_primary_key nvarchar(max), _is_unique nvarchar(max), _datatype nvarchar(max), _is_nullable nvarchar(max), _referenced_table nvarchar(max), _referenced_table_column nvarchar(max), _on_delete nvarchar(max) ); BULK INSERT #model FROM """%1""" WITH ( FIRSTROW = 2, FIELDTERMINATOR = ',' );UPDATE #model SET _table = replace(trim(_table), char(34), ''),_column = replace(trim(_column), char(34), ''),_is_primary_key = replace(trim(_is_primary_key), char(34), ''),_is_unique = replace(trim(_is_unique), char(34), ''),_datatype =replace(trim(_datatype), char(34), ''),_is_nullable = replace(trim(_is_nullable), char(34), ''),_referenced_table = replace(trim(_referenced_table), char(34), ''),_referenced_table_column = replace(trim(_referenced_table_column), char(34), ''),_on_delete = replace(trim(_on_delete), char(34), '');SELECT _table._table, (select _column, _is_primary_key, _is_unique, _datatype, _is_nullable, _referenced_table, _referenced_table_column, _on_delete FROM #model _column where _column._table = _table._table for xml auto, type) FROM (select distinct _table from #model) _table FOR XML auto, root ('tables'), type" queryout %2 -c -T %sqlCredentials%
goto :eof


:NoParam
    @echo on
    echo "usage: csv_to_xml.bat <csvInputFileName> <xmlOutputFileName>"