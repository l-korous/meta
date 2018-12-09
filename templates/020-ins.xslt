<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE xsl:stylesheet [<!ENTITY s "&#160;">]>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output method="text" indent="no" encoding="UTF-8" omit-xml-declaration="yes" />
    <xsl:strip-space elements="*"/>
    <xsl:template match="tables">
    
use <xsl:value-of select="$metaDbName" />
GO
<xsl:for-each select="//_table" >
IF OBJECT_ID ('dbo.ins_<xsl:value-of select="@_table" />') IS NOT NULL 
     DROP PROCEDURE dbo.ins_<xsl:value-of select="@_table" />
GO
CREATE PROCEDURE dbo.ins_<xsl:value-of select="@_table" />(@branch_id NVARCHAR(50)
<xsl:for-each select="_column" >
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
      -- Record does not exist
      IF EXISTS (select * from dbo.[<xsl:value-of select="@_table" />] where
       <xsl:for-each select="_column[@_is_primary_key=1]" >
            [<xsl:value-of select="@_column" />] = @_<xsl:value-of select="@_column" /> AND
        </xsl:for-each>
       branch_id = @branch_id) BEGIN
		  set @msg = 'ERROR: <xsl:value-of select="@_table" /> ( '+ 
          <xsl:for-each select="_column[@_is_primary_key=1]" >
            '[<xsl:value-of select="@_column" />]: ' + CAST(@_<xsl:value-of select="@_column" /> AS NVARCHAR(MAX)) + ', ' +
        </xsl:for-each>
            'branch_id: ' + @branch_id + ') already exists';
		  THROW 50000, @msg, 1
	   END
       
	   declare @current_datetime datetime = getdate()
	   declare @current_version nvarchar(50) = (SELECT current_version_id from [branch] where branch_id = @branch_id)

      INSERT INTO dbo.[<xsl:value-of select="@_table" />] VALUES (
        <xsl:for-each select="_column" >
            @_<xsl:value-of select="@_column" />,
        </xsl:for-each>
         @branch_id
      )

      -- This handles the case when the entry used to exist, and was deleted. So we finish the validity of the deletion.
      UPDATE dbo.hist_<xsl:value-of select="@_table" /> SET
            valid_to = @current_datetime
         WHERE
            <xsl:for-each select="_column[@_is_primary_key=1]" >
                [<xsl:value-of select="@_column" />] = @_<xsl:value-of select="@_column" /> AND
            </xsl:for-each>
            branch_id = @branch_id
            AND valid_to IS NULL
         
      INSERT INTO dbo.hist_<xsl:value-of select="@_table" /> VALUES (
         <xsl:for-each select="_column" >
            @_<xsl:value-of select="@_column" />,
        </xsl:for-each>
         @branch_id,
         @current_version,
         @current_datetime,
         NULL,
         0,
         CURRENT_USER
      )
	   COMMIT TRANSACTION;
    END TRY 
    BEGIN CATCH 
	   ROLLBACK TRANSACTION;
	   THROW
    END CATCH
END
</xsl:for-each>
</xsl:template>
</xsl:stylesheet>
