<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:meta="meta">
    <xsl:import href="../utilities.xsl"/>
	<xsl:output method="text" indent="no" encoding="UTF-8" omit-xml-declaration="yes" />
    <xsl:strip-space elements="*"/>
    <xsl:template match="tables">
    
use <xsl:value-of select="//configuration[@key='DbName']/@value" />
GO
IF OBJECT_ID ('dbo.delete_branch') IS NOT NULL 
     DROP PROCEDURE dbo.delete_branch
GO
CREATE PROCEDURE dbo.delete_branch
(@branch_name NVARCHAR(255))
AS
BEGIN
    SET XACT_ABORT, NOCOUNT ON
    DECLARE @msg nvarchar(255)
    BEGIN TRY
    BEGIN TRANSACTION
	   EXEC sp_MSforeachtable "ALTER TABLE ? NOCHECK CONSTRAINT all"

	   -- SANITY CHECKS
	   -- Branch exists
	   IF NOT EXISTS (select * from dbo.[branch] where branch_name = @branch_name)
		  BEGIN
			 set @msg = 'ERROR: Branch "' + @branch_name + '" does not exist';
			 THROW 50000, @msg, 1
		  END

	   <xsl:for-each select="//table" >
            DELETE FROM dbo.[<xsl:value-of select="@table_name" />]
                WHERE branch_name = @branch_name

            DELETE FROM dbo.hist_<xsl:value-of select="@table_name" />
       </xsl:for-each>

	   DELETE FROM dbo.[version]
	   WHERE branch_name = @branch_name

	   DELETE FROM dbo.[branch]
	   WHERE branch_name = @branch_name

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
