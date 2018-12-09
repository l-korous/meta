<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output method="text" indent="no" encoding="UTF-8" omit-xml-declaration="yes" />
    <xsl:strip-space elements="*"/>
    <xsl:template match="tables">
    
use <xsl:value-of select="$metaDbName" />
GO
IF OBJECT_ID ('dbo.delete_branch') IS NOT NULL 
     DROP PROCEDURE dbo.delete_branch
GO
CREATE PROCEDURE dbo.delete_branch
(@branch_id NVARCHAR(50))
AS
BEGIN
    SET XACT_ABORT, NOCOUNT ON
    DECLARE @msg nvarchar(255)
    BEGIN TRY
    BEGIN TRANSACTION
	   EXEC sp_MSforeachtable "ALTER TABLE ? NOCHECK CONSTRAINT all"

	   -- SANITY CHECKS
	   -- Branch exists
	   IF NOT EXISTS (select * from dbo.branch where branch_id = @branch_id)
		  BEGIN
			 set @msg = 'ERROR: Branch ' + @branch_id + ' does not exist';
			 THROW 50000, @msg, 1
		  END

	   <xsl:for-each select="//_table" >
            DELETE FROM dbo.[<xsl:value-of select="@_table" />]
                WHERE branch_id = @branch_id

            DELETE FROM dbo.hist_<xsl:value-of select="@_table" />
       </xsl:for-each>

	   DELETE FROM dbo.[version]
	   WHERE branch_id = @branch_id

	   DELETE FROM dbo.[branch]
	   WHERE branch_id = @branch_id

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
