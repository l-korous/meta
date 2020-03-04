<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:meta="meta">
    <xsl:import href="../utilities.xsl"/>
	<xsl:output method="text" indent="no" encoding="UTF-8" omit-xml-declaration="yes" />
    <xsl:strip-space elements="*"/>
    <xsl:template match="tables">
    
use <xsl:value-of select="//configuration[@key='DbName']/@value" />
GO
IF OBJECT_ID ('dbo.create_branch') IS NOT NULL 
     DROP PROCEDURE dbo.create_branch
GO
CREATE PROCEDURE dbo.create_branch
(@branch_name NVARCHAR(255))
AS
BEGIN
    SET XACT_ABORT, NOCOUNT ON
    DECLARE @msg nvarchar(255)
    BEGIN TRY
    BEGIN TRANSACTION
	   -- SANITY CHECKS
	   -- Branch does not exist
	   IF EXISTS (select * from dbo.[branch] where branch_name = @branch_name)
		  BEGIN
			 set @msg = 'ERROR: Branch "' + @branch_name + '" already exists';
			 THROW 50000, @msg, 1
		  END
          
	   declare @start_master_version_name NVARCHAR(255) = (select last_closed_version_name from dbo.[branch] where branch_name = 'master')
	   declare @max_version_order_plus_one int = (SELECT MAX(version_order) from dbo.[version]) + 1
		  
	   insert into dbo.[branch] values (@branch_name, @start_master_version_name, NULL, NULL)
	   update branch set last_closed_version_name = @start_master_version_name where branch_name = @branch_name
	   
	   EXEC sp_MSforeachtable "ALTER TABLE ? NOCHECK CONSTRAINT all"
        <xsl:for-each select="//table" >
            insert into dbo.[<xsl:value-of select="@table_name" />]
            select 
            <xsl:for-each select="columns/column" >
                [<xsl:value-of select="@column_name" />],
            </xsl:for-each>
                @branch_name
            from dbo.[<xsl:value-of select="@table_name" />]
            where branch_name = 'master'
        </xsl:for-each>
	   exec sp_MSforeachtable "ALTER TABLE ? WITH CHECK CHECK CONSTRAINT all"

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
