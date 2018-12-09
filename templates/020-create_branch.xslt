<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output method="text" indent="no" encoding="UTF-8" omit-xml-declaration="yes" />
    <xsl:strip-space elements="*"/>
    <xsl:template match="tables">
    
use <xsl:value-of select="$metaDbName" />
GO
IF OBJECT_ID ('dbo.create_branch') IS NOT NULL 
     DROP PROCEDURE dbo.create_branch
GO
CREATE PROCEDURE dbo.create_branch
(@branch_id NVARCHAR(50), @version_id NVARCHAR(50))
AS
BEGIN
    SET XACT_ABORT, NOCOUNT ON
    DECLARE @msg nvarchar(255)
    BEGIN TRY
    BEGIN TRANSACTION
	   -- SANITY CHECKS
	   -- Branch does not exist
	   IF EXISTS (select * from dbo.branch where branch_id = @branch_id)
		  BEGIN
			 set @msg = 'ERROR: Branch ' + @branch_id + ' already exists';
			 THROW 50000, @msg, 1
		  END
	   -- Version does not exist
	   IF EXISTS (select * from dbo.version where version_id = @version_id)
		  BEGIN
			 set @msg = 'ERROR: Version ' + @version_id + ' already exists';
			 THROW 50000, @msg, 1
		  END

	   declare @start_master_version_id NVARCHAR(50) = (select last_closed_version_id from dbo.branch where branch_id = 'master')
	   declare @max_version_order_plus_one int = (SELECT MAX(version_order) from dbo.version) + 1
		  
	   insert into dbo.branch values (@branch_id, @start_master_version_id, NULL, NULL)
	   insert into dbo.version values (@version_id, @branch_id, @start_master_version_id, @max_version_order_plus_one, 'open')
	   update branch set last_closed_version_id = @start_master_version_id where branch_id = @branch_id
	   update branch set current_version_id = @version_id where branch_id = @branch_id

	   EXEC sp_MSforeachtable "ALTER TABLE ? NOCHECK CONSTRAINT all"
        <xsl:for-each select="//_table" >
            insert into dbo.[<xsl:value-of select="@_table" />]
            select 
            <xsl:for-each select="_column" >
                [<xsl:value-of select="@_column" />],
            </xsl:for-each>
                @branch_id
            from dbo.[<xsl:value-of select="@_table" />]
            where branch_id = 'master'
        </xsl:for-each>
	   exec sp_MSforeachtable "ALTER TABLE ? WITH CHECK CHECK CONSTRAINT all"

	   COMMIT TRANSACTION;
    END TRY 
    BEGIN CATCH 
	   ROLLBACK TRANSACTION;
	   THROW
    END CATCH
END
</xsl:template>
</xsl:stylesheet>
