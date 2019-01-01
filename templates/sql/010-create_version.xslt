<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:meta="meta">
    <xsl:import href="../utilities.xsl"/>
	<xsl:output method="text" indent="no" encoding="UTF-8" omit-xml-declaration="yes" />
    <xsl:strip-space elements="*"/>
    <xsl:template match="tables">
    
use <xsl:value-of select="//configuration[@key='DbName']/@value" />
GO
IF OBJECT_ID ('dbo.create_version') IS NOT NULL 
     DROP PROCEDURE dbo.create_version
GO
CREATE PROCEDURE dbo.create_version
(@version_name NVARCHAR(255), @branch_name NVARCHAR(255) = 'master')
AS
BEGIN
    SET XACT_ABORT, NOCOUNT ON
    DECLARE @msg nvarchar(255)
    BEGIN TRY
    BEGIN TRANSACTION
	   -- SANITY CHECKS
	   -- Branch exists
	   IF NOT EXISTS (select * from dbo.branch where branch_name = @branch_name)
		  BEGIN
			 set @msg = 'ERROR: Branch "' + @branch_name + '" does not exist';
			 THROW 50000, @msg, 1
		  END
	   -- Version does not exist
	   IF EXISTS (select * from dbo.version where version_name = @version_name)
		  BEGIN
			 set @msg = 'ERROR: Version "' + @version_name + '" already exists on branch: ' + (select branch_name from dbo.version where version_name = @version_name);
			 THROW 50000, @msg, 1
		  END
	   -- There is no open version
	   IF (SELECT current_version_name from dbo.branch where branch_name = @branch_name) IS NOT NULL
		  BEGIN
			 set @msg = 'ERROR: Branch has an open version "' + (SELECT current_version_name from dbo.branch where branch_name = @branch_name) + '", close that first';
			 THROW 50000, @msg, 1
		  END

	   declare @max_version_order_plus_one int = (SELECT MAX(version_order) from dbo.version) + 1
	   declare @previous_version_name NVARCHAR(255) = (select last_closed_version_name from dbo.branch where branch_name = @branch_name)
	   insert into dbo.version values (@version_name, @branch_name, @previous_version_name, @max_version_order_plus_one, 'OPEN')
	   update branch set current_version_name = @version_name where branch_name = @branch_name

	   COMMIT TRANSACTION;
    END TRY 
    BEGIN CATCH 
	   ROLLBACK TRANSACTION;
	   THROW
    END CATCH 
END
</xsl:template>
</xsl:stylesheet>
