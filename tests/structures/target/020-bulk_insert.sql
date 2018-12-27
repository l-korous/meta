
    
use meta3
GO

IF OBJECT_ID ('dbo.bulk_insert_Table') IS NOT NULL 
     DROP PROCEDURE dbo.bulk_insert_Table
GO

create PROCEDURE dbo.bulk_insert_Table
(@filepath nvarchar(max), @is_full_import bit = 0, @branch_id NVARCHAR(50) = 'master', @firstrow int = 2, @fieldterminator nvarchar(1) = ',', @rowterminator nvarchar(3) = '\n')
AS
BEGIN
	SET XACT_ABORT, NOCOUNT ON
    DECLARE @msg nvarchar(255)
    BEGIN TRY
    BEGIN TRANSACTION
		-- SANITY CHECKS
		-- TODO: Check that file exists
		-- Branch exists
	   IF NOT EXISTS (select * from dbo.branch where branch_id = @branch_id) BEGIN
		  set @msg = 'ERROR: Branch ' + @branch_id + ' does not exist';
		  THROW 50000, @msg, 1
	   END
	   -- Branch has a current version
	   IF NOT EXISTS (select * from dbo.branch _b inner join dbo.version _v on _b.branch_id = @branch_id and _v.version_id = _b.current_version_id) BEGIN
		  set @msg = 'ERROR: Branch ' + @branch_id + ' does not have a current version';
		  THROW 50000, @msg, 1
	   END
	   -- Branch's current version is open
	   IF (select _v.version_status from dbo.branch _b inner join dbo.[version] _v on _b.branch_id = @branch_id and _v.version_id = _b.current_version_id) <> 'open' BEGIN
		  set @msg = 'ERROR: Branch ' + @branch_id + ' has a current version, but it is not open';
		  THROW 50000, @msg, 1
	   END
	   
		CREATE TABLE #tempTable (
		table_name nvarchar(255)
		);

		-- This may fail (file may not exist)
		declare @sql varchar(max)
		set @sql = 'BULK INSERT #tempTable FROM ''' + @filepath + ''' WITH ( FIRSTROW = ' + cast(@firstrow AS nvarchar(255)) + ', FIELDTERMINATOR = ''' + @fieldterminator + ''', ROWTERMINATOR = ''' + @rowterminator + '''  );'
		exec (@sql);
	   
		CREATE TABLE #mergeResultTable (
			action_type VARCHAR(50),
			
				inserted_table_name nvarchar(255),
			
				deleted_table_name nvarchar(255)
		);

		declare @current_datetime datetime = getdate();
		
		WITH historyReaction AS (
			SELECT 'I' AS [action], 'I' AS [reaction]  UNION
			SELECT 'D' AS [action], 'I' AS [reaction]  UNION
			SELECT 'D' AS [action], 'D' AS [reaction]  UNION
			SELECT 'U' AS [action], 'I' AS [reaction]  UNION
			SELECT 'U' AS [action], 'D' AS [reaction] ),
		currentHistory AS (
			SELECT
				table_name
			FROM dbo.hist_Table
			WHERE branch_id = @branch_id AND valid_to IS NULL )
		MERGE INTO dbo.hist_Table historyTable USING ( 
			SELECT
				historyReaction.[action],
				historyReaction.[reaction],
				
					i_table_name,
				
					h_table_name,
				
				_b.current_version_id
			FROM ( 
				SELECT
					CASE WHEN
						h.[table_name] IS NULL
					THEN 'I'
						-- If this is not a full import, we do not delete.
						WHEN i.[table_name] IS NULL AND @is_full_import = 1 THEN 'D'
						
						ELSE NULL
					end as [action],
					
						i.table_name i_table_name,
					
						h.table_name h_table_name
				FROM #tempTable i 
					FULL OUTER JOIN currentHistory h ON
					
						i.[table_name] = h.[table_name]
						
			) MyData
			INNER JOIN historyReaction on historyReaction.[action] = MyData.[action]
			INNER JOIN [branch] _b ON @branch_id = _b.branch_id
		) [input]
		ON
			
				[input].[h_table_name] = historyTable.[table_name] AND
			
			historyTable.branch_id = @branch_id AND historyTable.valid_to IS NULL AND [input].[reaction] = 'D'
		WHEN MATCHED THEN UPDATE SET historyTable.valid_to = @current_datetime
		WHEN NOT MATCHED THEN INSERT (
			
				[table_name],
			
			branch_id,
			version_id,
			valid_from,
			valid_to,
			is_delete,
			author
		) VALUES (
			
				isnull([input].[i_table_name],[input].[h_table_name]),
			
			@branch_id,
			[input].current_version_id,
			@current_datetime, 
			NULL,
			IIF([input].[action] = 'D', 1, 0),
			CURRENT_USER
		)  OUTPUT
		   $action,
		   inserted.table_name,
		   deleted.table_name
		   into #mergeResultTable;
		COMMIT TRANSACTION;
    END TRY 
    BEGIN CATCH 
	   ROLLBACK TRANSACTION;
	   THROW
    END CATCH 
END

IF OBJECT_ID ('dbo.bulk_insert_Column') IS NOT NULL 
     DROP PROCEDURE dbo.bulk_insert_Column
GO

create PROCEDURE dbo.bulk_insert_Column
(@filepath nvarchar(max), @is_full_import bit = 0, @branch_id NVARCHAR(50) = 'master', @firstrow int = 2, @fieldterminator nvarchar(1) = ',', @rowterminator nvarchar(3) = '\n')
AS
BEGIN
	SET XACT_ABORT, NOCOUNT ON
    DECLARE @msg nvarchar(255)
    BEGIN TRY
    BEGIN TRANSACTION
		-- SANITY CHECKS
		-- TODO: Check that file exists
		-- Branch exists
	   IF NOT EXISTS (select * from dbo.branch where branch_id = @branch_id) BEGIN
		  set @msg = 'ERROR: Branch ' + @branch_id + ' does not exist';
		  THROW 50000, @msg, 1
	   END
	   -- Branch has a current version
	   IF NOT EXISTS (select * from dbo.branch _b inner join dbo.version _v on _b.branch_id = @branch_id and _v.version_id = _b.current_version_id) BEGIN
		  set @msg = 'ERROR: Branch ' + @branch_id + ' does not have a current version';
		  THROW 50000, @msg, 1
	   END
	   -- Branch's current version is open
	   IF (select _v.version_status from dbo.branch _b inner join dbo.[version] _v on _b.branch_id = @branch_id and _v.version_id = _b.current_version_id) <> 'open' BEGIN
		  set @msg = 'ERROR: Branch ' + @branch_id + ' has a current version, but it is not open';
		  THROW 50000, @msg, 1
	   END
	   
		CREATE TABLE #tempTable (
		column_name nvarchar(255)
				,
			table_name nvarchar(255)
				,
			datatype nvarchar(255)
				,
			is_primary_key BIT
				,
			is_unique BIT
				,
			is_nullable BIT
		);

		-- This may fail (file may not exist)
		declare @sql varchar(max)
		set @sql = 'BULK INSERT #tempTable FROM ''' + @filepath + ''' WITH ( FIRSTROW = ' + cast(@firstrow AS nvarchar(255)) + ', FIELDTERMINATOR = ''' + @fieldterminator + ''', ROWTERMINATOR = ''' + @rowterminator + '''  );'
		exec (@sql);
	   
		CREATE TABLE #mergeResultTable (
			action_type VARCHAR(50),
			
				inserted_column_name nvarchar(255),
			
				inserted_table_name nvarchar(255),
			
				inserted_datatype nvarchar(255),
			
				inserted_is_primary_key BIT,
			
				inserted_is_unique BIT,
			
				inserted_is_nullable BIT,
			
				deleted_column_name nvarchar(255)
					,
				
				deleted_table_name nvarchar(255)
					,
				
				deleted_datatype nvarchar(255)
					,
				
				deleted_is_primary_key BIT
					,
				
				deleted_is_unique BIT
					,
				
				deleted_is_nullable BIT
		);

		declare @current_datetime datetime = getdate();
		
		WITH historyReaction AS (
			SELECT 'I' AS [action], 'I' AS [reaction]  UNION
			SELECT 'D' AS [action], 'I' AS [reaction]  UNION
			SELECT 'D' AS [action], 'D' AS [reaction]  UNION
			SELECT 'U' AS [action], 'I' AS [reaction]  UNION
			SELECT 'U' AS [action], 'D' AS [reaction] ),
		currentHistory AS (
			SELECT
				column_name
						,
					table_name
						,
					datatype
						,
					is_primary_key
						,
					is_unique
						,
					is_nullable
			FROM dbo.hist_Column
			WHERE branch_id = @branch_id AND valid_to IS NULL )
		MERGE INTO dbo.hist_Column historyTable USING ( 
			SELECT
				historyReaction.[action],
				historyReaction.[reaction],
				
					i_column_name,
				
					i_table_name,
				
					i_datatype,
				
					i_is_primary_key,
				
					i_is_unique,
				
					i_is_nullable,
				
					h_column_name,
				
					h_table_name,
				
					h_datatype,
				
					h_is_primary_key,
				
					h_is_unique,
				
					h_is_nullable,
				
				_b.current_version_id
			FROM ( 
				SELECT
					CASE WHEN
						h.[column_name] IS NULL
					THEN 'I'
						-- If this is not a full import, we do not delete.
						WHEN i.[column_name] IS NULL AND @is_full_import = 1 THEN 'D'
						
							WHEN 
								h.[column_name] IS NOT NULL AND
								i.[column_name] IS NOT NULL AND
							( 
								h.[datatype] <> i.[datatype]
								OR (h.[datatype] IS NULL AND i.[datatype] IS NOT NULL) OR (i.[datatype] IS NULL AND h.[datatype] IS NOT NULL)
								
									OR
								
								h.[is_primary_key] <> i.[is_primary_key]
								OR (h.[is_primary_key] IS NULL AND i.[is_primary_key] IS NOT NULL) OR (i.[is_primary_key] IS NULL AND h.[is_primary_key] IS NOT NULL)
								
									OR
								
								h.[is_unique] <> i.[is_unique]
								OR (h.[is_unique] IS NULL AND i.[is_unique] IS NOT NULL) OR (i.[is_unique] IS NULL AND h.[is_unique] IS NOT NULL)
								
									OR
								
								h.[is_nullable] <> i.[is_nullable]
								OR (h.[is_nullable] IS NULL AND i.[is_nullable] IS NOT NULL) OR (i.[is_nullable] IS NULL AND h.[is_nullable] IS NOT NULL)
								 ) THEN 'U'
						
						ELSE NULL
					end as [action],
					
						i.column_name i_column_name,
					
						i.table_name i_table_name,
					
						i.datatype i_datatype,
					
						i.is_primary_key i_is_primary_key,
					
						i.is_unique i_is_unique,
					
						i.is_nullable i_is_nullable,
					
						h.column_name h_column_name
							,
						
						h.table_name h_table_name
							,
						
						h.datatype h_datatype
							,
						
						h.is_primary_key h_is_primary_key
							,
						
						h.is_unique h_is_unique
							,
						
						h.is_nullable h_is_nullable
				FROM #tempTable i 
					FULL OUTER JOIN currentHistory h ON
					
						i.[column_name] = h.[column_name]
						
							AND
						
						i.[table_name] = h.[table_name]
						
			) MyData
			INNER JOIN historyReaction on historyReaction.[action] = MyData.[action]
			INNER JOIN [branch] _b ON @branch_id = _b.branch_id
		) [input]
		ON
			
				[input].[h_column_name] = historyTable.[column_name] AND
			
				[input].[h_table_name] = historyTable.[table_name] AND
			
			historyTable.branch_id = @branch_id AND historyTable.valid_to IS NULL AND [input].[reaction] = 'D'
		WHEN MATCHED THEN UPDATE SET historyTable.valid_to = @current_datetime
		WHEN NOT MATCHED THEN INSERT (
			
				[column_name],
			
				[table_name],
			
				[datatype],
			
				[is_primary_key],
			
				[is_unique],
			
				[is_nullable],
			
			branch_id,
			version_id,
			valid_from,
			valid_to,
			is_delete,
			author
		) VALUES (
			
				isnull([input].[i_column_name],[input].[h_column_name]),
			
				isnull([input].[i_table_name],[input].[h_table_name]),
			
				IIF([input].[action] = 'D', NULL, [input].[i_datatype]),
			
				IIF([input].[action] = 'D', NULL, [input].[i_is_primary_key]),
			
				IIF([input].[action] = 'D', NULL, [input].[i_is_unique]),
			
				IIF([input].[action] = 'D', NULL, [input].[i_is_nullable]),
			
			@branch_id,
			[input].current_version_id,
			@current_datetime, 
			NULL,
			IIF([input].[action] = 'D', 1, 0),
			CURRENT_USER
		)  OUTPUT
		   $action,
		   inserted.table_name,
		   deleted.table_name
		   into #mergeResultTable;
		COMMIT TRANSACTION;
    END TRY 
    BEGIN CATCH 
	   ROLLBACK TRANSACTION;
	   THROW
    END CATCH 
END

IF OBJECT_ID ('dbo.bulk_insert_Reference') IS NOT NULL 
     DROP PROCEDURE dbo.bulk_insert_Reference
GO

create PROCEDURE dbo.bulk_insert_Reference
(@filepath nvarchar(max), @is_full_import bit = 0, @branch_id NVARCHAR(50) = 'master', @firstrow int = 2, @fieldterminator nvarchar(1) = ',', @rowterminator nvarchar(3) = '\n')
AS
BEGIN
	SET XACT_ABORT, NOCOUNT ON
    DECLARE @msg nvarchar(255)
    BEGIN TRY
    BEGIN TRANSACTION
		-- SANITY CHECKS
		-- TODO: Check that file exists
		-- Branch exists
	   IF NOT EXISTS (select * from dbo.branch where branch_id = @branch_id) BEGIN
		  set @msg = 'ERROR: Branch ' + @branch_id + ' does not exist';
		  THROW 50000, @msg, 1
	   END
	   -- Branch has a current version
	   IF NOT EXISTS (select * from dbo.branch _b inner join dbo.version _v on _b.branch_id = @branch_id and _v.version_id = _b.current_version_id) BEGIN
		  set @msg = 'ERROR: Branch ' + @branch_id + ' does not have a current version';
		  THROW 50000, @msg, 1
	   END
	   -- Branch's current version is open
	   IF (select _v.version_status from dbo.branch _b inner join dbo.[version] _v on _b.branch_id = @branch_id and _v.version_id = _b.current_version_id) <> 'open' BEGIN
		  set @msg = 'ERROR: Branch ' + @branch_id + ' has a current version, but it is not open';
		  THROW 50000, @msg, 1
	   END
	   
		CREATE TABLE #tempTable (
		reference_name nvarchar(255)
				,
			src_table_name nvarchar(255)
				,
			dest_table_name nvarchar(255)
				,
			on_delete nvarchar(255)
		);

		-- This may fail (file may not exist)
		declare @sql varchar(max)
		set @sql = 'BULK INSERT #tempTable FROM ''' + @filepath + ''' WITH ( FIRSTROW = ' + cast(@firstrow AS nvarchar(255)) + ', FIELDTERMINATOR = ''' + @fieldterminator + ''', ROWTERMINATOR = ''' + @rowterminator + '''  );'
		exec (@sql);
	   
		CREATE TABLE #mergeResultTable (
			action_type VARCHAR(50),
			
				inserted_reference_name nvarchar(255),
			
				inserted_src_table_name nvarchar(255),
			
				inserted_dest_table_name nvarchar(255),
			
				inserted_on_delete nvarchar(255),
			
				deleted_reference_name nvarchar(255)
					,
				
				deleted_src_table_name nvarchar(255)
					,
				
				deleted_dest_table_name nvarchar(255)
					,
				
				deleted_on_delete nvarchar(255)
		);

		declare @current_datetime datetime = getdate();
		
		WITH historyReaction AS (
			SELECT 'I' AS [action], 'I' AS [reaction]  UNION
			SELECT 'D' AS [action], 'I' AS [reaction]  UNION
			SELECT 'D' AS [action], 'D' AS [reaction]  UNION
			SELECT 'U' AS [action], 'I' AS [reaction]  UNION
			SELECT 'U' AS [action], 'D' AS [reaction] ),
		currentHistory AS (
			SELECT
				reference_name
						,
					src_table_name
						,
					dest_table_name
						,
					on_delete
			FROM dbo.hist_Reference
			WHERE branch_id = @branch_id AND valid_to IS NULL )
		MERGE INTO dbo.hist_Reference historyTable USING ( 
			SELECT
				historyReaction.[action],
				historyReaction.[reaction],
				
					i_reference_name,
				
					i_src_table_name,
				
					i_dest_table_name,
				
					i_on_delete,
				
					h_reference_name,
				
					h_src_table_name,
				
					h_dest_table_name,
				
					h_on_delete,
				
				_b.current_version_id
			FROM ( 
				SELECT
					CASE WHEN
						h.[reference_name] IS NULL
					THEN 'I'
						-- If this is not a full import, we do not delete.
						WHEN i.[reference_name] IS NULL AND @is_full_import = 1 THEN 'D'
						
							WHEN 
								h.[reference_name] IS NOT NULL AND
								i.[reference_name] IS NOT NULL AND
							( 
								h.[src_table_name] <> i.[src_table_name]
								OR (h.[src_table_name] IS NULL AND i.[src_table_name] IS NOT NULL) OR (i.[src_table_name] IS NULL AND h.[src_table_name] IS NOT NULL)
								
									OR
								
								h.[dest_table_name] <> i.[dest_table_name]
								OR (h.[dest_table_name] IS NULL AND i.[dest_table_name] IS NOT NULL) OR (i.[dest_table_name] IS NULL AND h.[dest_table_name] IS NOT NULL)
								
									OR
								
								h.[on_delete] <> i.[on_delete]
								OR (h.[on_delete] IS NULL AND i.[on_delete] IS NOT NULL) OR (i.[on_delete] IS NULL AND h.[on_delete] IS NOT NULL)
								 ) THEN 'U'
						
						ELSE NULL
					end as [action],
					
						i.reference_name i_reference_name,
					
						i.src_table_name i_src_table_name,
					
						i.dest_table_name i_dest_table_name,
					
						i.on_delete i_on_delete,
					
						h.reference_name h_reference_name
							,
						
						h.src_table_name h_src_table_name
							,
						
						h.dest_table_name h_dest_table_name
							,
						
						h.on_delete h_on_delete
				FROM #tempTable i 
					FULL OUTER JOIN currentHistory h ON
					
						i.[reference_name] = h.[reference_name]
						
			) MyData
			INNER JOIN historyReaction on historyReaction.[action] = MyData.[action]
			INNER JOIN [branch] _b ON @branch_id = _b.branch_id
		) [input]
		ON
			
				[input].[h_reference_name] = historyTable.[reference_name] AND
			
			historyTable.branch_id = @branch_id AND historyTable.valid_to IS NULL AND [input].[reaction] = 'D'
		WHEN MATCHED THEN UPDATE SET historyTable.valid_to = @current_datetime
		WHEN NOT MATCHED THEN INSERT (
			
				[reference_name],
			
				[src_table_name],
			
				[dest_table_name],
			
				[on_delete],
			
			branch_id,
			version_id,
			valid_from,
			valid_to,
			is_delete,
			author
		) VALUES (
			
				isnull([input].[i_reference_name],[input].[h_reference_name]),
			
				IIF([input].[action] = 'D', NULL, [input].[i_src_table_name]),
			
				IIF([input].[action] = 'D', NULL, [input].[i_dest_table_name]),
			
				IIF([input].[action] = 'D', NULL, [input].[i_on_delete]),
			
			@branch_id,
			[input].current_version_id,
			@current_datetime, 
			NULL,
			IIF([input].[action] = 'D', 1, 0),
			CURRENT_USER
		)  OUTPUT
		   $action,
		   inserted.table_name,
		   deleted.table_name
		   into #mergeResultTable;
		COMMIT TRANSACTION;
    END TRY 
    BEGIN CATCH 
	   ROLLBACK TRANSACTION;
	   THROW
    END CATCH 
END

IF OBJECT_ID ('dbo.bulk_insert_ReferenceDetail') IS NOT NULL 
     DROP PROCEDURE dbo.bulk_insert_ReferenceDetail
GO

create PROCEDURE dbo.bulk_insert_ReferenceDetail
(@filepath nvarchar(max), @is_full_import bit = 0, @branch_id NVARCHAR(50) = 'master', @firstrow int = 2, @fieldterminator nvarchar(1) = ',', @rowterminator nvarchar(3) = '\n')
AS
BEGIN
	SET XACT_ABORT, NOCOUNT ON
    DECLARE @msg nvarchar(255)
    BEGIN TRY
    BEGIN TRANSACTION
		-- SANITY CHECKS
		-- TODO: Check that file exists
		-- Branch exists
	   IF NOT EXISTS (select * from dbo.branch where branch_id = @branch_id) BEGIN
		  set @msg = 'ERROR: Branch ' + @branch_id + ' does not exist';
		  THROW 50000, @msg, 1
	   END
	   -- Branch has a current version
	   IF NOT EXISTS (select * from dbo.branch _b inner join dbo.version _v on _b.branch_id = @branch_id and _v.version_id = _b.current_version_id) BEGIN
		  set @msg = 'ERROR: Branch ' + @branch_id + ' does not have a current version';
		  THROW 50000, @msg, 1
	   END
	   -- Branch's current version is open
	   IF (select _v.version_status from dbo.branch _b inner join dbo.[version] _v on _b.branch_id = @branch_id and _v.version_id = _b.current_version_id) <> 'open' BEGIN
		  set @msg = 'ERROR: Branch ' + @branch_id + ' has a current version, but it is not open';
		  THROW 50000, @msg, 1
	   END
	   
		CREATE TABLE #tempTable (
		reference_name nvarchar(255)
				,
			src_table_name nvarchar(255)
				,
			src_column_name nvarchar(255)
				,
			dest_table_name nvarchar(255)
				,
			dest_column_name nvarchar(255)
		);

		-- This may fail (file may not exist)
		declare @sql varchar(max)
		set @sql = 'BULK INSERT #tempTable FROM ''' + @filepath + ''' WITH ( FIRSTROW = ' + cast(@firstrow AS nvarchar(255)) + ', FIELDTERMINATOR = ''' + @fieldterminator + ''', ROWTERMINATOR = ''' + @rowterminator + '''  );'
		exec (@sql);
	   
		CREATE TABLE #mergeResultTable (
			action_type VARCHAR(50),
			
				inserted_reference_name nvarchar(255),
			
				inserted_src_table_name nvarchar(255),
			
				inserted_src_column_name nvarchar(255),
			
				inserted_dest_table_name nvarchar(255),
			
				inserted_dest_column_name nvarchar(255),
			
				deleted_reference_name nvarchar(255)
					,
				
				deleted_src_table_name nvarchar(255)
					,
				
				deleted_src_column_name nvarchar(255)
					,
				
				deleted_dest_table_name nvarchar(255)
					,
				
				deleted_dest_column_name nvarchar(255)
		);

		declare @current_datetime datetime = getdate();
		
		WITH historyReaction AS (
			SELECT 'I' AS [action], 'I' AS [reaction]  UNION
			SELECT 'D' AS [action], 'I' AS [reaction]  UNION
			SELECT 'D' AS [action], 'D' AS [reaction]  UNION
			SELECT 'U' AS [action], 'I' AS [reaction]  UNION
			SELECT 'U' AS [action], 'D' AS [reaction] ),
		currentHistory AS (
			SELECT
				reference_name
						,
					src_table_name
						,
					src_column_name
						,
					dest_table_name
						,
					dest_column_name
			FROM dbo.hist_ReferenceDetail
			WHERE branch_id = @branch_id AND valid_to IS NULL )
		MERGE INTO dbo.hist_ReferenceDetail historyTable USING ( 
			SELECT
				historyReaction.[action],
				historyReaction.[reaction],
				
					i_reference_name,
				
					i_src_table_name,
				
					i_src_column_name,
				
					i_dest_table_name,
				
					i_dest_column_name,
				
					h_reference_name,
				
					h_src_table_name,
				
					h_src_column_name,
				
					h_dest_table_name,
				
					h_dest_column_name,
				
				_b.current_version_id
			FROM ( 
				SELECT
					CASE WHEN
						h.[reference_name] IS NULL
					THEN 'I'
						-- If this is not a full import, we do not delete.
						WHEN i.[reference_name] IS NULL AND @is_full_import = 1 THEN 'D'
						
							WHEN 
								h.[reference_name] IS NOT NULL AND
								i.[reference_name] IS NOT NULL AND
							( 
								h.[src_table_name] <> i.[src_table_name]
								OR (h.[src_table_name] IS NULL AND i.[src_table_name] IS NOT NULL) OR (i.[src_table_name] IS NULL AND h.[src_table_name] IS NOT NULL)
								
									OR
								
								h.[dest_table_name] <> i.[dest_table_name]
								OR (h.[dest_table_name] IS NULL AND i.[dest_table_name] IS NOT NULL) OR (i.[dest_table_name] IS NULL AND h.[dest_table_name] IS NOT NULL)
								
									OR
								
								h.[dest_column_name] <> i.[dest_column_name]
								OR (h.[dest_column_name] IS NULL AND i.[dest_column_name] IS NOT NULL) OR (i.[dest_column_name] IS NULL AND h.[dest_column_name] IS NOT NULL)
								 ) THEN 'U'
						
						ELSE NULL
					end as [action],
					
						i.reference_name i_reference_name,
					
						i.src_table_name i_src_table_name,
					
						i.src_column_name i_src_column_name,
					
						i.dest_table_name i_dest_table_name,
					
						i.dest_column_name i_dest_column_name,
					
						h.reference_name h_reference_name
							,
						
						h.src_table_name h_src_table_name
							,
						
						h.src_column_name h_src_column_name
							,
						
						h.dest_table_name h_dest_table_name
							,
						
						h.dest_column_name h_dest_column_name
				FROM #tempTable i 
					FULL OUTER JOIN currentHistory h ON
					
						i.[reference_name] = h.[reference_name]
						
							AND
						
						i.[src_column_name] = h.[src_column_name]
						
			) MyData
			INNER JOIN historyReaction on historyReaction.[action] = MyData.[action]
			INNER JOIN [branch] _b ON @branch_id = _b.branch_id
		) [input]
		ON
			
				[input].[h_reference_name] = historyTable.[reference_name] AND
			
				[input].[h_src_column_name] = historyTable.[src_column_name] AND
			
			historyTable.branch_id = @branch_id AND historyTable.valid_to IS NULL AND [input].[reaction] = 'D'
		WHEN MATCHED THEN UPDATE SET historyTable.valid_to = @current_datetime
		WHEN NOT MATCHED THEN INSERT (
			
				[reference_name],
			
				[src_table_name],
			
				[src_column_name],
			
				[dest_table_name],
			
				[dest_column_name],
			
			branch_id,
			version_id,
			valid_from,
			valid_to,
			is_delete,
			author
		) VALUES (
			
				isnull([input].[i_reference_name],[input].[h_reference_name]),
			
				isnull([input].[i_src_column_name],[input].[h_src_column_name]),
			
				IIF([input].[action] = 'D', NULL, [input].[i_src_table_name]),
			
				IIF([input].[action] = 'D', NULL, [input].[i_dest_table_name]),
			
				IIF([input].[action] = 'D', NULL, [input].[i_dest_column_name]),
			
			@branch_id,
			[input].current_version_id,
			@current_datetime, 
			NULL,
			IIF([input].[action] = 'D', 1, 0),
			CURRENT_USER
		)  OUTPUT
		   $action,
		   inserted.table_name,
		   deleted.table_name
		   into #mergeResultTable;
		COMMIT TRANSACTION;
    END TRY 
    BEGIN CATCH 
	   ROLLBACK TRANSACTION;
	   THROW
    END CATCH 
END
