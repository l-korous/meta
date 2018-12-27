<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE xsl:stylesheet [<!ENTITY s "&#160;">]>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output method="text" indent="no" encoding="UTF-8" omit-xml-declaration="yes" />
    <xsl:strip-space elements="*"/>
    <xsl:template match="tables">
    
use <xsl:value-of select="//configuration[@key='DbName']/@value" />
GO
<xsl:for-each select="//table" >
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
			table_name nvarchar(max)
		);

		-- This may fail (file may not exist)
		declare @sql varchar(max)
		set @sql = 'BULK INSERT #tempTable FROM ''' + @filepath + ''' WITH ( FIRSTROW = ' + cast(@firstrow AS nvarchar(255)) + ', FIELDTERMINATOR = ''' + @fieldterminator + ''', ROWTERMINATOR = ''' + @rowterminator + '''  );'
		exec (@sql);
	   
		CREATE TABLE #mergeResultTable (
			action_type VARCHAR(50),
			inserted_table_name nvarchar(max),
			deleted_table_name nvarchar(max)
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
					CASE WHEN h.table_name is null THEN 'I'
						-- If this is not a full import, we do not delete.
						WHEN i.table_name is null AND @is_full_import = 1 THEN 'D'
						WHEN i.table_name is not null AND h.table_name is not null AND (
							0=1
							-- ((T.FkDocumentParentId!=H.FkDocumentParentId) OR (T.FkDocumentParentId IS NULL AND H.FkDocumentParentId IS NOT NULL) OR (T.FkDocumentParentId IS NOT NULL AND H.FkDocumentParentId IS  NULL)) OR
							) THEN 'U'
						ELSE NULL
					end as [action],
					i.table_name as i_table_name,
					h.table_name as h_table_name
					--T.FkDocumentParentId as T_FkDocumentParentId,
					--H.FkDocumentParentId as H_FkDocumentParentId,
				FROM #tempTable i 
					FULL OUTER JOIN currentHistory h
						ON (i.table_name = h.table_name)
			) MyData
			INNER JOIN historyReaction on historyReaction.[action] = MyData.[action]
			INNER JOIN [branch] _b ON @branch_id = _b.branch_id
		) [input]
		ON [input].h_table_name = historyTable.table_name
			AND historyTable.branch_id = @branch_id AND historyTable.valid_to IS NULL AND [input].[reaction] = 'D'
		WHEN MATCHED THEN UPDATE SET historyTable.valid_to = @current_datetime
		WHEN NOT MATCHED THEN INSERT (
			table_name,
			branch_id,
			version_id,
			valid_from,
			valid_to,
			is_delete,
			author
		) VALUES ( 
			isnull([input].i_table_name,[input].h_table_name),
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
