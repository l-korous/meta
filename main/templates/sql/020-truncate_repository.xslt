<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:meta="meta">
    <xsl:import href="../utilities.xsl"/>
	<xsl:output method="text" indent="no" encoding="UTF-8" omit-xml-declaration="yes" />
	<xsl:strip-space elements="*"/>
    <xsl:template match="tables">
USE <xsl:value-of select="//configuration[@key='DbName']/@value" />
GO

IF OBJECT_ID ('dbo.truncate_repository') IS NOT NULL 
     DROP PROCEDURE dbo.truncate_repository
GO
CREATE PROCEDURE dbo.truncate_repository
AS
BEGIN
    SET XACT_ABORT, NOCOUNT ON
    BEGIN TRY
    BEGIN TRANSACTION
        EXEC sp_MSforeachtable "ALTER TABLE ? NOCHECK CONSTRAINT all"
        delete from dbo.[version];
        delete from dbo.[branch];
        <xsl:for-each select="//table" >
            delete from dbo.[<xsl:value-of select="@table_name" />];
            delete from dbo.conflicts_<xsl:value-of select="@table_name" />;
        </xsl:for-each>
        <xsl:for-each select="//table" >
            delete from dbo.hist_<xsl:value-of select="@table_name" />;
        </xsl:for-each>
        
        exec sp_MSforeachtable "ALTER TABLE ? WITH CHECK CHECK CONSTRAINT all"
        INSERT INTO dbo.[branch] VALUES ('master', NULL, NULL, NULL)
        INSERT INTO dbo.[version] VALUES ('initial_version', 'master', NULL, 0, 'OPEN')
        UPDATE dbo.[branch] SET current_version_name = (select top 1 version_name from dbo.[version] where version_name = 'initial_version')
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
