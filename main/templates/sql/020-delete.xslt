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
IF OBJECT_ID ('dbo.delete_<xsl:value-of select="@table_name" />') IS NOT NULL 
     DROP PROCEDURE dbo.delete_<xsl:value-of select="@table_name" />
GO
CREATE PROCEDURE dbo.delete_<xsl:value-of select="@table_name" />
(
<xsl:for-each select="columns/column[@is_primary_key=1]" >
    @<xsl:value-of select="@column_name" />&s;<xsl:value-of select="meta:datatype_to_sql(@datatype)" />,
</xsl:for-each>
    @branch_name NVARCHAR(255) = 'master'
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
       <xsl:for-each select="columns/column[@is_primary_key=1]" >
            [<xsl:value-of select="@column_name" />] = @<xsl:value-of select="@column_name" /> AND
        </xsl:for-each>
       branch_name = @branch_name) BEGIN
            set @msg = 'ERROR: <xsl:value-of select="@table_name" /> ( '+
            <xsl:for-each select="columns/column[@is_primary_key=1]" >
            '[<xsl:value-of select="@column_name" />]: ' + CAST(@<xsl:value-of select="@column_name" /> AS NVARCHAR(MAX)) + ', ' +
            </xsl:for-each>
            'branch_name: ' + @branch_name + ') does not exist';
		  THROW 50000, @msg, 1
	   END

	   DELETE FROM dbo.[<xsl:value-of select="@table_name" />]
	   WHERE
        <xsl:for-each select="columns/column[@is_primary_key=1]" >
            [<xsl:value-of select="@column_name" />] = @<xsl:value-of select="@column_name" /> AND
        </xsl:for-each>
		  branch_name = @branch_name

	   COMMIT TRANSACTION;
    END TRY 
    BEGIN CATCH 
	   ROLLBACK TRANSACTION;
	   THROW
    END CATCH
END
GO
IF OBJECT_ID('TRG_delete_<xsl:value-of select="@table_name" />') IS NOT NULL
DROP TRIGGER TRG_delete_<xsl:value-of select="@table_name" />
GO
CREATE TRIGGER TRG_delete_<xsl:value-of select="@table_name" />
ON dbo.[<xsl:value-of select="@table_name" />]
AFTER DELETE AS
BEGIN
    declare @current_datetime datetime = getdate()

    -- EXISTENCE of history record for this branch (always true for master)
    INSERT INTO dbo.hist_<xsl:value-of select="@table_name" />
    SELECT
        <xsl:for-each select="columns/column" >
            _h.[<xsl:value-of select="@column_name" />],
        </xsl:for-each>
        _d.branch_name, _h.version_name, _h.valid_from, @current_datetime, _h.is_delete, _h.author
    FROM dbo.hist_<xsl:value-of select="@table_name" /> _h
    INNER JOIN DELETED _d
	   ON
        <xsl:for-each select="columns/column[@is_primary_key=1]" >
            _h.[<xsl:value-of select="@column_name" />] = _d.[<xsl:value-of select="@column_name" />] AND
        </xsl:for-each>
        _h.branch_name = 'master' and _h.valid_to is null
    LEFT JOIN dbo.hist_<xsl:value-of select="@table_name" /> _h_branch
	   ON
        <xsl:for-each select="columns/column[@is_primary_key=1]" >
            _h_branch.[<xsl:value-of select="@column_name" />] = _d.[<xsl:value-of select="@column_name" />] AND
        </xsl:for-each>
        _h_branch.branch_name = _d.branch_name
    WHERE
	   _h_branch.branch_name IS NULL
	
    BEGIN
	   UPDATE _h SET
		  valid_to = @current_datetime
	   FROM
		  dbo.hist_<xsl:value-of select="@table_name" /> _h
		  INNER JOIN DELETED _d
		  ON
          <xsl:for-each select="columns/column[@is_primary_key=1]" >
            _h.[<xsl:value-of select="@column_name" />] = _d.[<xsl:value-of select="@column_name" />] AND
        </xsl:for-each>
			 _h.branch_name = _d.branch_name
			 AND valid_to IS NULL
    END

    INSERT INTO dbo.hist_<xsl:value-of select="@table_name" /> SELECT
    <xsl:for-each select="columns/column[@is_primary_key=1]" >
        DELETED.[<xsl:value-of select="@column_name" />],
    </xsl:for-each>
    <xsl:for-each select="columns/column[@is_primary_key=0]" >
        NULL,
    </xsl:for-each>
DELETED.branch_name,
	   _b.current_version_name,
	   @current_datetime,
	   NULL,
	   1,
	   CURRENT_USER
    FROM DELETED
    INNER JOIN dbo.[branch] _b
	   ON DELETED.branch_name = _b.branch_name
END
GO
</xsl:for-each>
</xsl:template>
</xsl:stylesheet>
