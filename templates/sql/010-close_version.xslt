<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:meta="meta">
    <xsl:import href="../utilities.xsl"/>
	<xsl:output method="text" indent="no" encoding="UTF-8" omit-xml-declaration="yes" />
    <xsl:strip-space elements="*"/>
    <xsl:template match="tables">
    
use <xsl:value-of select="//configuration[@key='DbName']/@value" />
GO
IF OBJECT_ID ('dbo.close_version') IS NOT NULL 
     DROP PROCEDURE dbo.close_version
GO
CREATE PROCEDURE dbo.close_version
(@version_name NVARCHAR(255))
AS
BEGIN
    SET XACT_ABORT, NOCOUNT ON
    DECLARE @msg nvarchar(255)
    BEGIN TRY
    BEGIN TRANSACTION
	   -- SANITY CHECKS
	   -- Version exists
	   IF NOT EXISTS (select * from dbo.version where version_name = @version_name)
		  BEGIN
			 set @msg = 'ERROR: Version ' + @version_name + ' does not exist';
			 THROW 50000, @msg, 1
		  END
	   -- Version is not closed
	   IF (select version_status from dbo.version where version_name = @version_name) = 'CLOSED'
		  BEGIN
			 set @msg = 'ERROR: Version ' + @version_name + ' already closed';
			 THROW 50000, @msg, 1
		  END

       -- Close the version of the branch
	   UPDATE dbo.version
	   SET version_status = 'CLOSED'
	   WHERE version_name = @version_name
	   
	   UPDATE dbo.branch
	   SET last_closed_version_name = @version_name
	   WHERE branch_name = (select branch_name from dbo.version where version_name = @version_name)
	   
	   UPDATE dbo.branch
	   SET current_version_name = NULL
	   WHERE branch_name = (select branch_name from dbo.version where version_name = @version_name)

	   COMMIT TRANSACTION;
    END TRY 
    BEGIN CATCH 
	   ROLLBACK TRANSACTION;
	   THROW
    END CATCH 
END
</xsl:template>
</xsl:stylesheet>
