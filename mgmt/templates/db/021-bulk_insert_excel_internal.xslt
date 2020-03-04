<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE xsl:stylesheet [<!ENTITY s "&#160;">]>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:meta="meta">
    <xsl:import href="../utilities.xsl"/>
	<xsl:output method="text" indent="no" encoding="UTF-8" omit-xml-declaration="yes" />
    <xsl:strip-space elements="*"/>
    <xsl:template match="tables">
     
use <xsl:value-of select="//configuration[@key='DbName']/@value" />
GO

IF OBJECT_ID ('meta.bulk_insert_excel_internal') IS NOT NULL 
     DROP PROCEDURE meta.bulk_insert_excel_internal
GO

create PROCEDURE meta.bulk_insert_excel_internal
(@file_root nvarchar(max), @branch_name NVARCHAR(255) = 'master')
AS
BEGIN
	SET XACT_ABORT, NOCOUNT ON
    DECLARE @msg nvarchar(255)
    BEGIN TRY
    BEGIN TRANSACTION
		-- disable all constraints
        EXEC sp_MSforeachtable "ALTER TABLE ? NOCHECK CONSTRAINT all"
        DECLARE @filepath nvarchar(max)
        
    <xsl:for-each select="//table" >
        SET @filepath = @file_root + '<xsl:value-of select="@table_name" />' + '.csv'
        EXEC dbo.bulk_insert_csv_<xsl:value-of select="@table_name" /> @filepath, 1, @branch_name, 8, ',', '\n', 'FORMAT=''CSV'', FIELDQUOTE = ''"'', TABLOCK, CODEPAGE=65001'
    </xsl:for-each>
        
        -- enable all constraints
        EXEC sp_MSforeachtable "ALTER TABLE ? WITH CHECK CHECK CONSTRAINT all"
		COMMIT TRANSACTION;
    END TRY 
    BEGIN CATCH
       IF @@TRANCOUNT > 0 BEGIN
            ROLLBACK TRANSACTION;
       END;
	   THROW
    END CATCH 
END
GO
</xsl:template>
</xsl:stylesheet>
