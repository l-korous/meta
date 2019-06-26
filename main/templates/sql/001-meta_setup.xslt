<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:meta="meta">
    <xsl:import href="../utilities.xsl"/>
	<xsl:output method="text" indent="no" encoding="UTF-8" omit-xml-declaration="yes" />
	<xsl:strip-space elements="*"/>
    <xsl:template match="configurations">
USE <xsl:value-of select="//configuration[@key='DbName']/@value" />

/** Special case - function used in check constraint. Done this way because of MSSQL limitations about CREATE FUNCTION being first in batch etc. **/
IF OBJECT_ID ('dbo.[branch]', 'U') IS NOT NULL ALTER TABLE dbo.[branch] DROP CONSTRAINT CHK_branch_last_closed_version_name;
IF OBJECT_ID ('dbo.is_version_closed') IS NOT NULL DROP FUNCTION dbo.is_version_closed;
GO
CREATE FUNCTION dbo.is_version_closed (@version_name NVARCHAR(255)) RETURNS BIT
AS
BEGIN
    IF @version_name IS NULL
       RETURN 1
    IF (SELECT version_status FROM dbo.[version] WHERE version_name = @version_name) = 'CLOSED'
        return 1
    return 0
END
GO
IF OBJECT_ID ('dbo.[branch]', 'U') IS NOT NULL ALTER TABLE dbo.[branch] ADD CONSTRAINT CHK_branch_last_closed_version_name CHECK (dbo.is_version_closed(last_closed_version_name) = 1);
GO
    
IF OBJECT_ID ('meta.get_tables') IS NOT NULL DROP PROCEDURE meta.get_tables;
GO
CREATE PROCEDURE meta.get_tables
AS
BEGIN
    SET XACT_ABORT, NOCOUNT ON
    DECLARE @msg nvarchar(255)
    BEGIN TRY
        SELECT table_name FROM meta.[table];
    END TRY
    BEGIN CATCH
    END CATCH
END
GO

IF OBJECT_ID ('meta.get_columns') IS NOT NULL DROP PROCEDURE meta.get_columns;
GO
CREATE PROCEDURE meta.get_columns
(@table_name nvarchar(255) = '')
AS
BEGIN
    SET XACT_ABORT, NOCOUNT ON
    DECLARE @msg nvarchar(255)
    BEGIN TRY
        SELECT column_name, column_order, table_name, datatype_name, is_primary_key, is_unique, is_required FROM meta.[column]
        WHERE (@table_name = '' OR table_name = @table_name)
        ORDER BY column_order;
    END TRY
    BEGIN CATCH
    END CATCH
END
GO

IF OBJECT_ID ('meta.get_references') IS NOT NULL DROP PROCEDURE meta.get_references;
GO
CREATE PROCEDURE meta.get_references
(@table_name nvarchar(255) = '', @column_name nvarchar(255) = '')
AS
BEGIN
    SET XACT_ABORT, NOCOUNT ON
    DECLARE @msg nvarchar(255)
    BEGIN TRY
        -- SANITY CHECKS
        IF (@table_name = '' AND @column_name &lt;&gt; '') BEGIN
            set @msg = 'ERROR: Column name set, but table name not';
            THROW 50000, @msg, 1
        END
        SELECT reference_name, referencing_table_name, referencing_column_name, referenced_table_name, referenced_column_name, on_delete FROM meta.[reference]
        WHERE (@table_name = '' OR referencing_table_name = @table_name)
        AND (@column_name = '' OR referencing_column_name = @column_name);
    END TRY
    BEGIN CATCH
    END CATCH
END
GO


IF (
        NOT (
            EXISTS (
                SELECT * FROM <xsl:value-of select="//configuration[@key='DbName']/@value" />.sys.TABLES t inner join <xsl:value-of select="//configuration[@key='DbName']/@value" />.sys.schemas s ON t.schema_id = s.schema_id AND t.name = 'table' and s.name = 'meta'
            )
        )
    )
BEGIN
    CREATE TABLE meta.[configuration] (
        [key] nvarchar(max),
        [value] nvarchar(max)
    );
    
    CREATE TABLE dbo.[branch]
    (
        branch_name NVARCHAR(255) PRIMARY KEY,
        start_master_version_name NVARCHAR(255),
        last_closed_version_name NVARCHAR(255),
        current_version_name NVARCHAR(255)
    );

    CREATE TABLE dbo.[version]
    (
        version_name NVARCHAR(255) PRIMARY KEY,
        branch_name NVARCHAR(255),
        previous_version_name NVARCHAR(255),
        version_order int, -- Internal, only gives order on a particular branch
        version_status nvarchar(255)
    );
    
    CREATE TABLE meta.[datatype] (
        datatype_name nvarchar(255) primary key,
        datatype_sql nvarchar(255)
    );  

    CREATE TABLE meta.[model_version] (
        model_version int PRIMARY KEY IDENTITY(1, 1)
    );

    CREATE TABLE meta.[table] (
        model_version int,
        table_name nvarchar(255),
        PRIMARY KEY (model_version, table_name)
    );

    CREATE TABLE meta.[column] (
        model_version int,
        column_name nvarchar(255),
        column_order int,
        table_name nvarchar(255), 
        datatype_name nvarchar(255),
        is_primary_key bit,
        is_unique bit,
        is_required bit,
        PRIMARY KEY (model_version, [table_name], [column_name])
    ); 

    CREATE TABLE meta.[reference] (
        model_version int,
        reference_name nvarchar(255),
        referencing_table_name nvarchar(255),
        referencing_column_name nvarchar(255),
        referenced_table_name nvarchar(255),
        referenced_column_name nvarchar(255),
        on_delete nvarchar(255),
        PRIMARY KEY (model_version, [reference_name], [referencing_table_name], [referencing_column_name], [referenced_table_name], [referenced_column_name])
    );

    ALTER TABLE dbo.[branch] ADD CONSTRAINT FK_branch_start_master_version_name FOREIGN KEY (start_master_version_name) REFERENCES dbo.[version] (version_name);
    ALTER TABLE dbo.[branch] ADD CONSTRAINT FK_branch_last_closed_version_name FOREIGN KEY (last_closed_version_name) REFERENCES dbo.[version] (version_name);
    ALTER TABLE dbo.[branch] ADD CONSTRAINT FK_branch_current_version_name FOREIGN KEY (current_version_name) REFERENCES dbo.[version] (version_name);
    ALTER TABLE dbo.[branch] ADD CONSTRAINT CHK_branch_last_closed_version_name CHECK (dbo.is_version_closed(last_closed_version_name) = 1);
    ALTER TABLE dbo.[version] ADD CONSTRAINT FK_version_previous_version_name FOREIGN KEY (previous_version_name) REFERENCES dbo.[version] (version_name);
    ALTER TABLE dbo.[version] ADD CONSTRAINT FK_version_branch_name FOREIGN KEY (branch_name) REFERENCES dbo.[branch] (branch_name);
    ALTER TABLE meta.[table] ADD CONSTRAINT FK_table_model_version FOREIGN KEY (model_version) REFERENCES meta.[model_version] (model_version);
    ALTER TABLE meta.[column] ADD CONSTRAINT FK_column_model_version FOREIGN KEY (model_version) REFERENCES meta.[model_version] (model_version);
    ALTER TABLE meta.[column] ADD CONSTRAINT FK_column_table FOREIGN KEY (model_version, table_name) REFERENCES meta.[table] (model_version, table_name);
    ALTER TABLE meta.[column] ADD CONSTRAINT FK_column_datatype FOREIGN KEY (datatype_name) REFERENCES meta.[datatype] (datatype_name);
    ALTER TABLE meta.[reference] ADD CONSTRAINT FK_reference_model_version FOREIGN KEY (model_version) REFERENCES meta.[model_version] (model_version);
    ALTER TABLE meta.[reference] ADD CONSTRAINT FK_reference_referencing_table_name FOREIGN KEY (model_version, referencing_table_name) REFERENCES meta.[table] (model_version, table_name);
    ALTER TABLE meta.[reference] ADD CONSTRAINT FK_reference_referenced_table_name FOREIGN KEY (model_version, referenced_table_name) REFERENCES meta.[table] (model_version, table_name);
    ALTER TABLE meta.[reference] ADD CONSTRAINT FK_reference_referencing_column_name FOREIGN KEY (model_version, referencing_table_name, referencing_column_name) REFERENCES meta.[column] (model_version, table_name, column_name);
    ALTER TABLE meta.[reference] ADD CONSTRAINT FK_reference_referenced_column_name FOREIGN KEY (model_version, referenced_table_name, referenced_column_name) REFERENCES meta.[column] (model_version, table_name, column_name);
    
    INSERT INTO dbo.[branch] VALUES ('master', NULL, NULL, NULL)
    INSERT INTO dbo.[version] VALUES ('initial_version', 'master', NULL, 0, 'OPEN')
    UPDATE dbo.[branch] SET current_version_name = (select top 1 version_name from dbo.[version] where version_name = 'initial_version')

    INSERT INTO meta.[datatype] VALUES ('string', 'NVARCHAR(255)');
    INSERT INTO meta.[datatype] VALUES ('long_string', 'NVARCHAR(MAX)');
    INSERT INTO meta.[datatype] VALUES ('int', 'INT');
    INSERT INTO meta.[datatype] VALUES ('float', 'FLOAT');
    INSERT INTO meta.[datatype] VALUES ('datetime', 'DATETIME');
    INSERT INTO meta.[datatype] VALUES ('date', 'DATE');
    INSERT INTO meta.[datatype] VALUES ('boolean', 'BIT');
    INSERT INTO meta.[datatype] VALUES ('time', 'TIME');
END

TRUNCATE TABLE meta.[configuration];

<xsl:for-each select="//configuration" >
    INSERT INTO meta.[configuration] VALUES ('<xsl:value-of select="@key" />', '<xsl:value-of select="@value" />')
</xsl:for-each>

</xsl:template>
<xsl:template match="tables">
INSERT INTO meta.[model_version] DEFAULT VALUES;
<xsl:for-each select="//table" >
    INSERT INTO meta.[table] VALUES ((SELECT MAX(model_version) from meta.[model_version]), '<xsl:value-of select="@table_name" />')
    <xsl:for-each select="columns/column" >
        INSERT INTO meta.[column] VALUES ((SELECT MAX(model_version) from meta.[model_version]), '<xsl:value-of select="@column_name" />',
            <xsl:value-of select="position()" />,
            '<xsl:value-of select="../../@table_name" />',
            '<xsl:value-of select="@datatype" />',
            '<xsl:value-of select="@is_primary_key" />',
            '<xsl:value-of select="@is_unique" />',
            '<xsl:value-of select="@is_required" />')
    </xsl:for-each>
</xsl:for-each>
<xsl:for-each select="references/reference" >
    INSERT INTO meta.[reference] VALUES ((SELECT MAX(model_version) from meta.[model_version]), '<xsl:value-of select="@reference_name" />',
        '<xsl:value-of select="@referencing_table_name" />',
        '<xsl:value-of select="@referencing_column_name" />',
        '<xsl:value-of select="@referenced_table_name" />',
        '<xsl:value-of select="@referenced_column_name" />',
        '<xsl:value-of select="@on_delete" />')
</xsl:for-each>
    
IF OBJECT_ID ('meta.create_insert_column_query') IS NOT NULL DROP FUNCTION meta.create_insert_column_query;
GO
CREATE FUNCTION meta.create_insert_column_query
(@column_name nvarchar(255), @column_name_prev nvarchar(255), @column_datatype_new nvarchar(255), @column_datatype_prev nvarchar(255), @column_is_primary_key_new bit, @column_is_required_new bit)
RETURNS nvarchar(max)
AS
BEGIN
    DECLARE @SQL NVARCHAR(MAX) = 'CAST(';
    DECLARE @have_to_null bit = 0;

    IF (
	   (((@column_datatype_new = 'INT') OR (@column_datatype_new = 'FLOAT')) AND ((@column_datatype_prev = 'DATE') OR (@column_datatype_prev = 'TIME')))
	   OR
	   (((@column_datatype_new = 'DATE') OR (@column_datatype_new = 'TIME')) AND ((@column_datatype_prev = 'INT') OR (@column_datatype_prev = 'FLOAT')))
    )
	   SET @have_to_null = 1;

    IF ((@have_to_null = 1) OR (@column_name_prev IS NULL)) BEGIN
	   IF ((@column_is_primary_key_new = 1) OR (@column_is_required_new = 1))
		  SET @SQL = @SQL + CASE
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
		  SET @SQL = @SQL + 'NULL';
    END
    ELSE
	   SET @SQL = @SQL + quotename(@column_name_prev);
    SET @SQL = @SQL + ' AS ' + @column_datatype_new + '), ';

    RETURN(@SQL);
END
GO
IF OBJECT_ID ('meta.alter_model') IS NOT NULL DROP PROCEDURE meta.alter_model;
GO
CREATE PROCEDURE meta.alter_model
AS
BEGIN
    SET XACT_ABORT, NOCOUNT ON
    DECLARE @msg nvarchar(255)
    BEGIN TRY
    BEGIN TRANSACTION
       DECLARE @table_name nvarchar(255);
	   DECLARE @table_action nvarchar(255);
	   DECLARE @SQL NVARCHAR(MAX) = N'';

	   DECLARE @column_name nvarchar(255);
	   DECLARE @column_name_prev nvarchar(255);
	   DECLARE @column_datatype_new nvarchar(255);
	   DECLARE @column_datatype_prev nvarchar(255);
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
			 SET @SQL = 'DROP TABLE dbo.' + @table_name;
			 EXEC sp_executesql @SQL;
			 SET @SQL = 'DROP TABLE dbo.' + @hist_table_name;
			 EXEC sp_executesql @SQL;
			 SET @SQL = 'DROP TABLE dbo.' + @conflicts_table_name;
			 EXEC sp_executesql @SQL;
		  END
		  ELSE BEGIN -- (possibly) @table_action ~ 'UPDATE'
			 DECLARE @changed_model bit;
			 SET @changed_model = case when (
				select count(*) from
				    (select * from meta.[column] where model_version = (select max(model_version) from meta.model_version)) column_new
				full join
				    (select * from meta.[column] where model_version = (select max(model_version) from meta.model_version mv_prev where exists (select model_version from meta.model_version mv where mv.model_version > mv_prev.model_version))) column_prev
					   on column_new.column_name = column_prev.column_name and column_new.table_name = column_prev.table_name
				where (column_new.table_name = @table_name or column_prev.table_name = @table_name)
				    and (
				    column_new.datatype_name &lt;&gt; column_prev.datatype_name or
				    column_new.is_primary_key &lt;&gt; column_prev.is_primary_key or
				    column_new.is_required &lt;&gt; column_prev.is_required or
				    column_new.column_name is null or
				    column_prev.column_name is null or
				    column_new.is_unique &lt;&gt; column_prev.is_unique
				    )
			 ) > 0 then 1 else 0 end;

			 IF @changed_model = 1 BEGIN

				-- put together insert statement by going through all new columns, possibly finding old ones to them
				DECLARE @insert_statement nvarchar(max) = 'INSERT INTO ' + @temp_table_name + ' SELECT ';
		  
				DECLARE column_cursor CURSOR FOR
				    select
				    column_new.column_name,
				    column_prev.column_name,
				    datatype_new.datatype_sql,
				    datatype_prev.datatype_sql,
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
				    left join
					   meta.[datatype] datatype_prev
						  on datatype_prev.datatype_name = column_prev.datatype_name
				    where
					   column_new.table_name = @table_name

				OPEN column_cursor
				FETCH NEXT FROM column_cursor INTO @column_name, @column_name_prev, @column_datatype_new, @column_datatype_prev, @column_is_primary_key_new, @column_is_required_new
				WHILE @@FETCH_STATUS = 0  
				BEGIN
				    SET @insert_statement = @insert_statement + meta.create_insert_column_query(@column_name, @column_name_prev, @column_datatype_new, @column_datatype_prev, @column_is_primary_key_new, @column_is_required_new);

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
				SET @SQL = 'DROP TABLE dbo.' + @table_name;
				EXEC sp_executesql @SQL;

				-- Hist table (including deletion of foreign keys on old history table)
				DECLARE @backup_hist_table_name nvarchar(255) = 'hist_' + @table_name + '_' + cast(isnull((select max(cast(right(table_name, 1) as int)) from INFORMATION_SCHEMA.tables where table_name like 'hist_' + @table_name + '%[0-9]'), '0') as nvarchar(255));
				SET @SQL = '';
				SELECT @SQL += 'ALTER TABLE dbo.' + @hist_table_name + ' DROP CONSTRAINT ' + fk.name + '; ' from sys.foreign_keys fk join sys.tables t on fk.parent_object_id = t.object_id where t.name = @hist_table_name;
				EXEC sp_executesql @SQL;
				EXEC sp_rename @hist_table_name, @backup_hist_table_name;
				EXEC sp_rename @temp_hist_table_name, @hist_table_name;

				-- Conflict table
				SET @SQL = 'DROP TABLE dbo.' + @conflicts_table_name;
				EXEC sp_executesql @SQL;
				EXEC sp_rename @temp_conflicts_table_name, @conflicts_table_name;
			 END
			 ELSE BEGIN -- no change, therefore drop old, rename new (to have the FKs with __new_)
				SET @SQL = '';
                SELECT @SQL += 'ALTER TABLE dbo.' + t0.name + ' DROP CONSTRAINT ' + fk.name + '; ' from sys.foreign_keys fk join sys.tables t on fk.referenced_object_id = t.object_id join sys.tables t0 on fk.parent_object_id = t0.object_id where t.name = @table_name;
				EXEC sp_executesql @SQL;
				SET @SQL = 'DROP TABLE dbo.' + @table_name;
				EXEC sp_executesql @SQL;
				SET @SQL = '';
                SELECT @SQL += 'ALTER TABLE dbo.' + t0.name + ' DROP CONSTRAINT ' + fk.name + '; ' from sys.foreign_keys fk join sys.tables t on fk.referenced_object_id = t.object_id join sys.tables t0 on fk.parent_object_id = t0.object_id where t.name = @hist_table_name;
				EXEC sp_executesql @SQL;
				SET @SQL = 'DROP TABLE dbo.' + @hist_table_name;
				EXEC sp_executesql @SQL;
				SET @SQL = '';
                SELECT @SQL += 'ALTER TABLE dbo.' + t0.name + ' DROP CONSTRAINT ' + fk.name + '; ' from sys.foreign_keys fk join sys.tables t on fk.referenced_object_id = t.object_id join sys.tables t0 on fk.parent_object_id = t0.object_id where t.name = @conflicts_table_name;
				EXEC sp_executesql @SQL;
				SET @SQL = 'DROP TABLE dbo.' + @conflicts_table_name;
				EXEC sp_executesql @SQL;

				EXEC sp_rename @temp_table_name, @table_name;
				EXEC sp_rename @temp_hist_table_name, @hist_table_name;
				EXEC sp_rename @temp_conflicts_table_name, @conflicts_table_name;
			 END
		  END

		  FETCH NEXT FROM table_cursor INTO @table_name, @table_action;
	   END
	   CLOSE table_cursor;  
	   DEALLOCATE table_cursor;
    
	   -- Rename constraints
	   SET @SQL = '';
	   SELECT @sql += 'EXEC sp_rename ' + fk.name + ', ' + replace(fk.name, '__new_', '') + '; ' from sys.foreign_keys as fk where name like '%__new_%';
	   EXEC sp_executesql @SQL;

    COMMIT TRANSACTION;
    END TRY 
    BEGIN CATCH 
	   ROLLBACK TRANSACTION;
	   THROW
    END CATCH 
END
GO
    </xsl:template>
</xsl:stylesheet>