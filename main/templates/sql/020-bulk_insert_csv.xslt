<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE xsl:stylesheet [<!ENTITY s "&#160;">]>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:meta="meta">
    <xsl:import href="../utilities.xsl"/>
	<xsl:output method="text" indent="no" encoding="UTF-8" omit-xml-declaration="yes" />
    <xsl:strip-space elements="*"/>
    <xsl:template match="tables">
    
use <xsl:value-of select="//configuration[@key='DbName']/@value" />
GO
<xsl:for-each select="//table" >
IF OBJECT_ID ('dbo.bulk_insert_csv_<xsl:value-of select="@table_name" />') IS NOT NULL 
     DROP PROCEDURE dbo.bulk_insert_csv_<xsl:value-of select="@table_name" />
GO

create PROCEDURE dbo.bulk_insert_csv_<xsl:value-of select="@table_name" />
(@filepath nvarchar(max), @is_full_import bit = 0, @branch_name NVARCHAR(255) = 'master', @firstrow int = 2, @fieldterminator nvarchar(1) = ',', @rowterminator nvarchar(3) = '\n')
AS
BEGIN
	SET XACT_ABORT, NOCOUNT ON
    DECLARE @msg nvarchar(255)
    BEGIN TRY
    BEGIN TRANSACTION
		-- SANITY CHECKS
		-- TODO: Check that file exists
		-- Branch exists
	   IF NOT EXISTS (select * from dbo.[branch] where branch_name = @branch_name) BEGIN
		  set @msg = 'ERROR: Branch "' + @branch_name + '" does not exist';
		  THROW 50000, @msg, 1
	   END
	   -- Branch has a current version
	   IF NOT EXISTS (select * from dbo.[branch] _b inner join dbo.[version] _v on _b.branch_name = @branch_name and _v.version_name = _b.current_version_name) BEGIN
		  set @msg = 'ERROR: Branch "' + @branch_name + '" does not have a current version';
		  THROW 50000, @msg, 1
	   END
	   -- Branch's current version is open
	   IF (select _v.version_status from dbo.[branch] _b inner join dbo.[version] _v on _b.branch_name = @branch_name and _v.version_name = _b.current_version_name) &lt;&gt; 'OPEN' BEGIN
		  set @msg = 'ERROR: Branch ' + @branch_name + ' has a current version, but it is not open';
		  THROW 50000, @msg, 1
	   END
	   
		CREATE TABLE #loadTable (
		<xsl:for-each select="columns/column" >
			[<xsl:value-of select="@column_name" />] NVARCHAR(MAX) COLLATE <xsl:value-of select="//configuration[@key='DbCollation']/@value" />
			<xsl:if test="position() != last()">,</xsl:if>
		</xsl:for-each>
		);

		-- This may fail (file may not exist)
		declare @sql varchar(max)
		set @sql = 'BULK INSERT #loadTable FROM ''' + @filepath + ''' WITH ( FIRSTROW = ' + cast(@firstrow AS nvarchar(255)) + ', FIELDTERMINATOR = ''' + @fieldterminator + ''', ROWTERMINATOR = ''' + @rowterminator + '''  );'
		exec (@sql);
        	   
		CREATE TABLE #tempTable (
		<xsl:for-each select="columns/column" >
			[<xsl:value-of select="@column_name" />]&s;<xsl:value-of select="meta:datatype_to_sql(@datatype)" /><xsl:if test="matches(@datatype, '.*string')">&s;COLLATE <xsl:value-of select="//configuration[@key='DbCollation']/@value" /></xsl:if>
			<xsl:if test="position() != last()">,</xsl:if>
		</xsl:for-each>
		);
        
        INSERT INTO #tempTable
        SELECT
        <xsl:for-each select="columns/column" >
			CAST(LTRIM(RTRIM([<xsl:value-of select="@column_name" />])) AS <xsl:value-of select="meta:datatype_to_sql(@datatype)" />)
			<xsl:if test="position() != last()">,</xsl:if>
		</xsl:for-each>
        FROM #loadTable;
	   
		CREATE TABLE #mergeResultTable (
			action_type VARCHAR(50),
			is_delete BIT,
			<xsl:for-each select="columns/column" >
				inserted_<xsl:value-of select="@column_name" />&s;<xsl:value-of select="meta:datatype_to_sql(@datatype)" /><xsl:if test="matches(@datatype, '.*string')">&s;COLLATE <xsl:value-of select="//configuration[@key='DbCollation']/@value" /></xsl:if>,
                deleted_<xsl:value-of select="@column_name" />&s;<xsl:value-of select="meta:datatype_to_sql(@datatype)" /><xsl:if test="matches(@datatype, '.*string')">&s;COLLATE <xsl:value-of select="//configuration[@key='DbCollation']/@value" /></xsl:if>
				<xsl:if test="position() != last()">,</xsl:if>
			</xsl:for-each>
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
				<xsl:for-each select="columns/column" >
					[<xsl:value-of select="@column_name" />]
					<xsl:if test="position() != last()">,</xsl:if>
				</xsl:for-each>
			FROM dbo.hist_<xsl:value-of select="@table_name" />
			WHERE branch_name = @branch_name AND valid_to IS NULL )
		MERGE INTO dbo.hist_<xsl:value-of select="@table_name" /> historyTable USING ( 
			SELECT
				historyReaction.[action],
				historyReaction.[reaction],
				<xsl:for-each select="columns/column" >
					i_<xsl:value-of select="@column_name" />,
				</xsl:for-each>
				<xsl:for-each select="columns/column" >
					h_<xsl:value-of select="@column_name" />,
				</xsl:for-each>
				_b.current_version_name
			FROM ( 
				SELECT
					CASE WHEN
						h.[<xsl:value-of select="columns/column[@is_primary_key=1][1]/@column_name" />] IS NULL
					THEN 'I'
						-- If this is not a full import, we do not delete.
						WHEN i.[<xsl:value-of select="columns/column[@is_primary_key=1][1]/@column_name" />] IS NULL AND @is_full_import = 1 THEN 'D'
						<xsl:if test="count(columns/column[@is_primary_key=0]) &gt; 0">
							WHEN 
								h.[<xsl:value-of select="columns/column[@is_primary_key=1][1]/@column_name" />] IS NOT NULL AND
								i.[<xsl:value-of select="columns/column[@is_primary_key=1][1]/@column_name" />] IS NOT NULL AND
							( <xsl:for-each select="columns/column[@is_primary_key=0]" >
								h.[<xsl:value-of select="@column_name" />] &lt;&gt; i.[<xsl:value-of select="@column_name" />]
								OR (h.[<xsl:value-of select="@column_name" />] IS NULL AND i.[<xsl:value-of select="@column_name" />] IS NOT NULL) OR (i.[<xsl:value-of select="@column_name" />] IS NULL AND h.[<xsl:value-of select="@column_name" />] IS NOT NULL)
								<xsl:if test="position() != last()">
									OR
								</xsl:if>
							</xsl:for-each> ) THEN 'U'
						</xsl:if>
						ELSE NULL
					end as [action],
					<xsl:for-each select="columns/column" >
						i.[<xsl:value-of select="@column_name" />] i_<xsl:value-of select="@column_name" />,
					</xsl:for-each>
					<xsl:for-each select="columns/column" >
						h.[<xsl:value-of select="@column_name" />] h_<xsl:value-of select="@column_name" />
						<xsl:if test="position() != last()">,</xsl:if>
					</xsl:for-each>
				FROM #tempTable i 
					FULL OUTER JOIN currentHistory h ON
					<xsl:for-each select="columns/column[@is_primary_key=1]" >
						i.[<xsl:value-of select="@column_name" />] = h.[<xsl:value-of select="@column_name" />]
						<xsl:if test="position() != last()"> AND </xsl:if>
					</xsl:for-each>
			) MyData
			INNER JOIN historyReaction on historyReaction.[action] = MyData.[action]
			INNER JOIN dbo.[branch] _b ON @branch_name = _b.branch_name
		) [input]
		ON
			<xsl:for-each select="columns/column[@is_primary_key=1]" >
				[input].[h_<xsl:value-of select="@column_name" />] = historyTable.[<xsl:value-of select="@column_name" />] AND
			</xsl:for-each>
			historyTable.branch_name = @branch_name AND historyTable.valid_to IS NULL AND [input].[reaction] = 'D'
		WHEN MATCHED THEN UPDATE SET historyTable.valid_to = @current_datetime
		WHEN NOT MATCHED THEN INSERT (
			<xsl:for-each select="columns/column" >
				[<xsl:value-of select="@column_name" />],
			</xsl:for-each>
			branch_name,
			version_name,
			valid_from,
			valid_to,
			is_delete,
			author
		) VALUES (
			<xsl:for-each select="columns/column[@is_primary_key=1]" >
				isnull([input].[i_<xsl:value-of select="@column_name" />],[input].[h_<xsl:value-of select="@column_name" />]),
			</xsl:for-each>
			<xsl:for-each select="columns/column[@is_primary_key=0]" >
				IIF([input].[action] = 'D', NULL, [input].[i_<xsl:value-of select="@column_name" />]),
			</xsl:for-each>
			@branch_name,
			[input].current_version_name,
			@current_datetime, 
			NULL,
			IIF([input].[action] = 'D', 1, 0),
			CURRENT_USER
		)  OUTPUT
		   $action,
           IIF([input].[action] = 'D', 1, 0),
           <xsl:for-each select="columns/column" >
				inserted.[<xsl:value-of select="@column_name" />],
                deleted.[<xsl:value-of select="@column_name" />]
                <xsl:if test="position() != last()">,</xsl:if>
			</xsl:for-each>
		   into #mergeResultTable;
           
        DELETE a
        FROM 
            dbo.[<xsl:value-of select="@table_name" />] a
            INNER JOIN #mergeResultTable m
            ON <xsl:for-each select="columns/column[@is_primary_key=1]" >
				a.[<xsl:value-of select="@column_name" />] = m.inserted_<xsl:value-of select="@column_name" />
                AND
			</xsl:for-each>
            m.is_delete = 1 AND a.branch_name = @branch_name;
           
       <xsl:if test="count(columns/column[@is_primary_key=0]) &gt; 0">
        UPDATE a SET 
            <xsl:for-each select="columns/column[@is_primary_key=0]" >
				a.[<xsl:value-of select="@column_name" />] = m.inserted_<xsl:value-of select="@column_name" />
                <xsl:if test="position() != last()">,</xsl:if>
			</xsl:for-each>
        FROM 
            dbo.[<xsl:value-of select="@table_name" />] a
            INNER JOIN #mergeResultTable m
            ON <xsl:for-each select="columns/column[@is_primary_key=1]" >
				a.[<xsl:value-of select="@column_name" />] = m.inserted_<xsl:value-of select="@column_name" />
                AND
			</xsl:for-each>
            m.is_delete = 0 AND m.action_type = 'INSERT' AND a.branch_name = @branch_name;
        </xsl:if>
        
        INSERT INTO dbo.[<xsl:value-of select="@table_name" />]
        SELECT
        <xsl:for-each select="columns/column" >
				m.inserted_<xsl:value-of select="@column_name" />,
			</xsl:for-each>
            @branch_name
        FROM #mergeResultTable m
            LEFT JOIN dbo.[<xsl:value-of select="@table_name" />] a
            ON <xsl:for-each select="columns/column[@is_primary_key=1]" >
				a.[<xsl:value-of select="@column_name" />] = m.inserted_<xsl:value-of select="@column_name" />
                <xsl:if test="position() != last()"> AND </xsl:if>
			</xsl:for-each>
        WHERE a.[<xsl:value-of select="columns/column[@is_primary_key=1][1]/@column_name" />] IS NULL AND m.is_delete = 0 AND m.action_type = 'INSERT';
        
		COMMIT TRANSACTION;
    END TRY 
    BEGIN CATCH 
	   ROLLBACK TRANSACTION;
	   THROW
    END CATCH 
END
GO
</xsl:for-each>
</xsl:template>
</xsl:stylesheet>
