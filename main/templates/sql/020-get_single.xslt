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
IF OBJECT_ID ('dbo.get_single_<xsl:value-of select="@table_name" />') IS NOT NULL 
     DROP PROCEDURE dbo.get_single_<xsl:value-of select="@table_name" />
GO
CREATE PROCEDURE dbo.get_single_<xsl:value-of select="@table_name" />
(
<xsl:for-each select="columns/column[@is_part_of_primary_key=1]" >
    @<xsl:value-of select="@column_name" />&s;<xsl:value-of select="meta:datatype_to_sql(@datatype)" />,
</xsl:for-each>
    @branch_name NVARCHAR(255)
)
AS
BEGIN
    SET XACT_ABORT, NOCOUNT ON
    DECLARE @msg nvarchar(255)
    BEGIN TRY
    BEGIN TRANSACTION
       -- SANITY CHECKS
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
	   -- Record exists
	   IF NOT EXISTS (select * from dbo.[<xsl:value-of select="@table_name" />] where
       <xsl:for-each select="columns/column[@is_part_of_primary_key=1]" >
            [<xsl:value-of select="@column_name" />] = @<xsl:value-of select="@column_name" /> AND
        </xsl:for-each>
       branch_name = @branch_name) BEGIN
            set @msg = 'ERROR: <xsl:value-of select="@table_name" /> ( '+
            <xsl:for-each select="columns/column[@is_part_of_primary_key=1]" >
            '[<xsl:value-of select="@column_name" />]: ' + CAST(@<xsl:value-of select="@column_name" /> AS NVARCHAR(MAX)) + ', ' +
            </xsl:for-each>
            'branch_name: ' + @branch_name + ') does not exist';
		  THROW 50000, @msg, 1
	   END
       
       DECLARE @return TABLE (
         <xsl:for-each select="columns/column" >
            [<xsl:value-of select="@column_name" />]&s;<xsl:value-of select="meta:datatype_to_sql(@datatype)" />
            <xsl:if test="position() != last()">, </xsl:if></xsl:for-each>
        )

	   INSERT INTO @return
       SELECT
           <xsl:for-each select="columns/column" >
                [<xsl:value-of select="@column_name" />]<xsl:if test="position() != last()">, </xsl:if></xsl:for-each>
       FROM dbo.[<xsl:value-of select="@table_name" />]
	   WHERE
        <xsl:for-each select="columns/column[@is_part_of_primary_key=1]" >
            [<xsl:value-of select="@column_name" />] = @<xsl:value-of select="@column_name" /> AND
        </xsl:for-each>
		  branch_name = @branch_name;
          
        SELECT * FROM @return;

	   COMMIT TRANSACTION;
    END TRY 
    BEGIN CATCH 
	   ROLLBACK TRANSACTION;
	   THROW
    END CATCH
END
GO</xsl:for-each>
</xsl:template>
</xsl:stylesheet>
