<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE xsl:stylesheet [<!ENTITY s "&#160;">]>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output method="text" indent="no" encoding="UTF-8" omit-xml-declaration="yes" />
    <xsl:strip-space elements="*"/>
    <xsl:template match="tables">
    
use <xsl:value-of select="$metaDbName" />
GO
<xsl:for-each select="//_table" >
IF OBJECT_ID ('dbo.del_<xsl:value-of select="@_table" />') IS NOT NULL 
     DROP PROCEDURE dbo.del_<xsl:value-of select="@_table" />
GO
CREATE PROCEDURE dbo.del_<xsl:value-of select="@_table" />
(
    @branch_id NVARCHAR(50)
<xsl:for-each select="_column[@_is_primary_key=1]" >
    , @_<xsl:value-of select="@_column" />&s;<xsl:value-of select="@_datatype" />
</xsl:for-each>

)
AS
BEGIN
    SET XACT_ABORT, NOCOUNT ON
    DECLARE @msg nvarchar(255)
    BEGIN TRY
    BEGIN TRANSACTION
       -- SANITY CHECKS
	   -- Branch exists
	   IF NOT EXISTS (select * from dbo.branch where branch_id = @branch_id) BEGIN
		  set @msg = 'ERROR: Branch ' + @branch_id + ' does not exist';
		  THROW 50000, @msg, 1
	   END
	   -- Branch has a current version
	   IF NOT EXISTS (select * from dbo.branch _b inner join dbo.version _v on _b.branch_id = @branch_id and _v.version_id = _b.current_version_id) BEGIN
		  set @msg = 'ERROR: Branch ' + @branch_id + ' does not have a current version';
		  THROW 50000, @msg, 1
	   END
	   -- Branch's current version is open
	   IF (select _v.version_status from dbo.branch _b inner join dbo.version _v on _b.branch_id = @branch_id and _v.version_id = _b.current_version_id) &lt;&gt; 'open' BEGIN
		  set @msg = 'ERROR: Branch ' + @branch_id + ' has a current version, but it is not open';
		  THROW 50000, @msg, 1
	   END
	   -- Record exists
	   IF NOT EXISTS (select * from dbo.[<xsl:value-of select="@_table" />] where
       <xsl:for-each select="_column[@_is_primary_key=1]" >
            [<xsl:value-of select="@_column" />] = @_<xsl:value-of select="@_column" /> AND
        </xsl:for-each>
       branch_id = @branch_id) BEGIN
            set @msg = 'ERROR: <xsl:value-of select="@_table" /> ( '+
            <xsl:for-each select="_column[@_is_primary_key=1]" >
            '[<xsl:value-of select="@_column" />]: ' + CAST(@_<xsl:value-of select="@_column" /> AS NVARCHAR(MAX)) + ', ' +
            </xsl:for-each>
            'branch_id: ' + @branch_id + ') does not exist';
		  THROW 50000, @msg, 1
	   END

	   DELETE FROM dbo.[<xsl:value-of select="@_table" />]
	   WHERE
        <xsl:for-each select="_column[@_is_primary_key=1]" >
            [<xsl:value-of select="@_column" />] = @_<xsl:value-of select="@_column" /> AND
        </xsl:for-each>
		  branch_id = @branch_id

	   COMMIT TRANSACTION;
    END TRY 
    BEGIN CATCH 
	   ROLLBACK TRANSACTION;
	   THROW
    END CATCH
END
GO
IF OBJECT_ID('TRG_del_<xsl:value-of select="@_table" />') IS NOT NULL
DROP TRIGGER TRG_del_<xsl:value-of select="@_table" />
GO
CREATE TRIGGER TRG_del_<xsl:value-of select="@_table" />
ON dbo.[<xsl:value-of select="@_table" />]
AFTER DELETE AS
BEGIN
    declare @current_datetime datetime = getdate()

    -- EXISTENCE of history record for this branch (always true for master)
    INSERT INTO dbo.hist_<xsl:value-of select="@_table" />
    SELECT
        <xsl:for-each select="_column" >
            _h.[<xsl:value-of select="@_column" />],
        </xsl:for-each>
        _d.branch_id, _h.version_id, _h.valid_from, @current_datetime, _h.is_delete, _h.author
    FROM dbo.hist_<xsl:value-of select="@_table" /> _h
    INNER JOIN DELETED _d
	   ON
        <xsl:for-each select="_column[@_is_primary_key=1]" >
            _h.[<xsl:value-of select="@_column" />] = _d.[<xsl:value-of select="@_column" />] AND
        </xsl:for-each>
        _h.branch_id = 'master' and _h.valid_to is null
    LEFT JOIN dbo.hist_<xsl:value-of select="@_table" /> _h_branch
	   ON
        <xsl:for-each select="_column[@_is_primary_key=1]" >
            _h_branch.[<xsl:value-of select="@_column" />] = _d.[<xsl:value-of select="@_column" />] AND
        </xsl:for-each>
        _h_branch.branch_id = _d.branch_id
    WHERE
	   _h_branch.branch_id IS NULL
	
    BEGIN
	   UPDATE _h SET
		  valid_to = @current_datetime
	   FROM
		  dbo.hist_<xsl:value-of select="@_table" /> _h
		  INNER JOIN DELETED _d
		  ON
          <xsl:for-each select="_column[@_is_primary_key=1]" >
            _h.[<xsl:value-of select="@_column" />] = _d.[<xsl:value-of select="@_column" />] AND
        </xsl:for-each>
			 _h.branch_id = _d.branch_id
			 AND valid_to IS NULL
    END

    INSERT INTO dbo.hist_<xsl:value-of select="@_table" /> SELECT
    <xsl:for-each select="_column[@_is_primary_key=1]" >
        DELETED.[<xsl:value-of select="@_column" />],
    </xsl:for-each>
    <xsl:for-each select="_column[@_is_primary_key=0]" >
        NULL,
    </xsl:for-each>
DELETED.branch_id,
	   _b.current_version_id,
	   @current_datetime,
	   NULL,
	   1,
	   CURRENT_USER
    FROM DELETED
    INNER JOIN [branch] _b
	   ON DELETED.branch_id = _b.branch_id
END
GO
</xsl:for-each>
</xsl:template>
</xsl:stylesheet>
