use meta_target_3
GO

EXEC sp_MSforeachtable "ALTER TABLE ? NOCHECK CONSTRAINT all";

    DECLARE @table_name nvarchar(255);
    DECLARE @table_action nvarchar(255);
    DECLARE @SQL NVARCHAR(MAX) = N'';

    DECLARE @column_name nvarchar(255);
    DECLARE @column_name_prev nvarchar(255);
    DECLARE @column_datatype_new nvarchar(255);
    DECLARE @column_is_primary_key_new bit;
    DECLARE @column_is_required_new bit;

    DECLARE table_cursor CURSOR FOR
	   select
	   isnull(table_new.table_name, table_prev.table_name),
	   case
		  when table_prev.table_name is null then 'NEW'
		  when table_new.table_name is null then 'DROP'
		  else 'POSSIBLY UPDATE'
	   end as [action]
	   from
		  (select * from meta.[table] where model_version = (select max(model_version) from meta.model_version)) table_new
	   full join
		  (select * from meta.[table] where model_version = (select max(model_version) from meta.model_version mv_prev where exists (select model_version from meta.model_version mv where mv.model_version > mv_prev.model_version))) table_prev
	   on
		  table_new.table_name = table_prev.table_name;

    OPEN table_cursor
    FETCH NEXT FROM table_cursor INTO @table_name, @table_action;
    WHILE @@FETCH_STATUS = 0  
    BEGIN
	   DECLARE @hist_table_name nvarchar(255) = concat('hist_', @table_name);
	   DECLARE @conflicts_table_name nvarchar(255) = concat('conflicts_', @table_name);
	   DECLARE @temp_table_name nvarchar(255) = concat('__new_', @table_name);
	   DECLARE @temp_hist_table_name nvarchar(255) = concat('__new_hist_', @table_name);
	   DECLARE @temp_conflicts_table_name nvarchar(255) = concat('__new_conflicts_', @table_name);

	   IF @table_action = 'NEW' BEGIN
		  EXEC sp_rename @temp_table_name, @table_name;
		  EXEC sp_rename @temp_hist_table_name, @hist_table_name;
		  EXEC sp_rename @temp_conflicts_table_name, @conflicts_table_name;
	   END
	   ELSE IF @table_action = 'DROP' BEGIN
		  SET @SQL = 'DROP TABLE ' + @table_name;
		  EXEC sp_executesql @SQL;
		  SET @SQL = 'DROP TABLE ' + @hist_table_name;
		  EXEC sp_executesql @SQL;
		  SET @SQL = 'DROP TABLE ' + @conflicts_table_name;
		  EXEC sp_executesql @SQL;
	   END
	   ELSE BEGIN -- POSSIBLY UPDATE
		  -- put together insert statement
		  DECLARE @insert_statement nvarchar(max) = 'INSERT INTO ' + @temp_table_name + ' SELECT ';
		  
		  DECLARE column_cursor CURSOR FOR
			 select
			 column_new.column_name,
			 column_prev.column_name,
			 datatype_new.datatype_sql,
			 column_new.is_primary_key,
			 column_new.is_required
			 from
				(select * from meta.[column] where model_version = (select max(model_version) from meta.model_version)) column_new
			 inner join
				meta.[datatype] datatype_new
				    on datatype_new.datatype_name = column_new.datatype_name
			 left join
				(select * from meta.[column] where model_version = (select max(model_version) from meta.model_version mv_prev where exists (select model_version from meta.model_version mv where mv.model_version > mv_prev.model_version))) column_prev
				    on column_new.column_name = column_prev.column_name and column_new.table_name = column_prev.table_name
			 where
				column_new.table_name = @table_name

		  -- TODO: select count(*) with differences, use that for history table backup
		  OPEN column_cursor
		  FETCH NEXT FROM column_cursor INTO @column_name, @column_name_prev, @column_datatype_new, @column_is_primary_key_new, @column_is_required_new
		  WHILE @@FETCH_STATUS = 0  
		  BEGIN
			 SET @insert_statement = @insert_statement + 'CAST(ISNULL(' + quotename(@column_name_prev) + ', ';
			 IF ((@column_is_primary_key_new = 1) OR (@column_is_required_new = 1))
				SET @insert_statement = @insert_statement + 
				CASE
				    WHEN @column_datatype_new = 'NVARCHAR(255)' THEN ''''''
				    WHEN @column_datatype_new = 'NVARCHAR(MAX)' THEN ''''''
				    WHEN @column_datatype_new = 'INT' THEN '0'
				    WHEN @column_datatype_new = 'FLOAT' THEN '0'
				    WHEN @column_datatype_new = 'DATETIME' THEN ''''''
				    WHEN @column_datatype_new = 'DATE' THEN ''''''
				    WHEN @column_datatype_new = 'TIME' THEN ''''''
				    WHEN @column_datatype_new = 'BIT' THEN '0'
				END;
			 ELSE
				SET @insert_statement = @insert_statement + 'NULL';

			 SET @insert_statement = @insert_statement + ') AS ' + @column_datatype_new + '), ';

			 FETCH NEXT FROM column_cursor INTO @column_name, @column_name_prev, @column_datatype_new, @column_is_primary_key_new, @column_is_required_new
		  END
		  CLOSE column_cursor;
		  DEALLOCATE column_cursor;

		  SET @insert_statement = @insert_statement + 'branch_name FROM ' + @table_name;
		  EXEC sp_executesql @insert_statement;

		  -- Drop the old tables, including FKs
		  SET @SQL = '';
		  SELECT @SQL += 'ALTER TABLE dbo.' + t0.name + ' DROP CONSTRAINT ' + fk.name + '; ' from sys.foreign_keys fk join sys.tables t on fk.referenced_object_id = t.object_id join sys.tables t0 on fk.parent_object_id = t0.object_id where t.name = @table_name;
		  EXEC sp_executesql @SQL;
		  SET @SQL = 'DROP TABLE ' + @table_name;
		  EXEC sp_executesql @SQL;

		  -- Hist table (including deletion of foreign keys on old history table)
		  DECLARE @backup_hist_table_name nvarchar(255) = 'hist_' + @table_name + '_' + cast(isnull((select max(cast(right(table_name, 1) as int)) from INFORMATION_SCHEMA.tables where table_name like 'hist_' + @table_name + '%[0-9]'), '0') as nvarchar(255));
		  SET @SQL = '';
		  SELECT @SQL += 'ALTER TABLE dbo.' + t.name + ' DROP CONSTRAINT ' + fk.name + '; ' from sys.foreign_keys fk join sys.tables t on fk.parent_object_id = t.object_id where t.name like 'hist_%';
		  EXEC sp_executesql @SQL;
		  EXEC sp_rename @hist_table_name, @backup_hist_table_name;
		  EXEC sp_rename @temp_hist_table_name, @hist_table_name;

		  -- Conflict table
		  SET @SQL = 'DROP TABLE ' + @conflicts_table_name;
		  EXEC sp_executesql @SQL;
		  EXEC sp_rename @temp_conflicts_table_name, @conflicts_table_name;
	   END

	   FETCH NEXT FROM table_cursor INTO @table_name, @table_action;
    END
    CLOSE table_cursor;  
    DEALLOCATE table_cursor;
    
    -- Rename constraints
    SET @SQL = '';
    SELECT @sql += 'EXEC sp_rename ' + fk.name + ', ' + replace(fk.name, '__new_', '') + '; ' from sys.foreign_keys as fk where name like '%__new_%';
    EXEC sp_executesql @SQL;

exec sp_MSforeachtable "ALTER TABLE ? WITH CHECK CHECK CONSTRAINT all"