<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output method="text" indent="no" encoding="UTF-8" omit-xml-declaration="yes" />
    <xsl:strip-space elements="*"/>
    <xsl:template match="tables">
    
use <xsl:value-of select="$metaDbName" />
GO
<xsl:for-each select="//_table" >
IF OBJECT_ID ('dbo.perform_merge_<xsl:value-of select="@_table" />') IS NOT NULL 
     DROP PROCEDURE dbo.perform_merge_<xsl:value-of select="@_table" />
GO
CREATE PROCEDURE dbo.perform_merge_<xsl:value-of select="@_table" />
(@branch_id NVARCHAR(50), @merge_version_id NVARCHAR(50), @current_datetime datetime)
AS
BEGIN
    SET XACT_ABORT, NOCOUNT ON
    DECLARE @msg nvarchar(255)
    BEGIN TRY
	   BEGIN TRANSACTION
       -- SANITY CHECKS DONE IN THE CALLER (merge_branch)
        -- Inserts (history)
	   INSERT INTO dbo.hist_<xsl:value-of select="@_table" />
       SELECT
       <xsl:for-each select="_column" >
            [<xsl:value-of select="@_column" />],
        </xsl:for-each>
        'master', @merge_version_id, @current_datetime, NULL, is_delete, CURRENT_USER
	   FROM dbo.hist_<xsl:value-of select="@_table" /> _hist
	   WHERE
		  branch_id = @branch_id
		  AND valid_to IS NULL
		  AND is_delete = 0
		  AND NOT EXISTS(select * from dbo.[<xsl:value-of select="@_table" />] _curr where
          <xsl:for-each select="_column[@_is_primary_key=1]" >
            _curr.[<xsl:value-of select="@_column" />] = _hist.[<xsl:value-of select="@_column" />] AND
        </xsl:for-each>
          _curr.branch_id = 'master')

       <xsl:if test="count(_column[@_is_primary_key=0]) &gt; 0">
	   -- Updates (history)
	   INSERT INTO dbo.hist_<xsl:value-of select="@_table" />
	   SELECT
       <xsl:for-each select="_column" >
            [<xsl:value-of select="@_column" />],
        </xsl:for-each>
       'master', @merge_version_id, @current_datetime, NULL, is_delete, CURRENT_USER
	   FROM dbo.hist_<xsl:value-of select="@_table" /> _hist
	   WHERE
		  branch_id = @branch_id
		  AND valid_to IS NULL
		  AND is_delete = 0
		  AND EXISTS(select * from dbo.[<xsl:value-of select="@_table" />] _curr where
          <xsl:for-each select="_column[@_is_primary_key=1]" >
            _curr.[<xsl:value-of select="@_column" />] = _hist.[<xsl:value-of select="@_column" />] AND
        </xsl:for-each>
          _curr.branch_id = 'master')
		  AND (
              <xsl:for-each select="_column[@_is_primary_key=0]" >
                   (_hist.[<xsl:value-of select="@_column" />] &lt;&gt; (select [<xsl:value-of select="@_column" />] from dbo.[<xsl:value-of select="../@_table" />] _curr where <xsl:for-each select="_column[@_is_primary_key=1]" >
                        _curr.[<xsl:value-of select="@_column" />] = _hist.[<xsl:value-of select="@_column" />] AND
                    </xsl:for-each>
                   _curr.branch_id = 'master'))
                   <xsl:if test="position() != last()"> OR </xsl:if>
                </xsl:for-each>
		  )
      </xsl:if>
          
	   -- Inserts (current)
	   INSERT INTO dbo.[<xsl:value-of select="@_table" />]
	   SELECT
        <xsl:for-each select="_column" >
            _branch.[<xsl:value-of select="@_column" />],
        </xsl:for-each>
        'master'
	   FROM dbo.[<xsl:value-of select="@_table" />] _branch
	   INNER JOIN dbo.hist_<xsl:value-of select="@_table" /> _branch_hist
		  ON
            <xsl:for-each select="_column[@_is_primary_key=1]" >
                _branch_hist.[<xsl:value-of select="@_column" />] = _branch.[<xsl:value-of select="@_column" />] AND
            </xsl:for-each>
			 _branch_hist.branch_id = @branch_id
			 AND valid_to IS NULL
	   WHERE _branch.branch_id = @branch_id
		  AND NOT EXISTS(select * from dbo.[<xsl:value-of select="@_table" />] _curr where
          <xsl:for-each select="_column[@_is_primary_key=1]" >
                _curr.[<xsl:value-of select="@_column" />] = _branch.[<xsl:value-of select="@_column" />] AND
            </xsl:for-each>
          _curr.branch_id = 'master')
		  
       <xsl:if test="count(_column[@_is_primary_key=0]) &gt; 0">
	   -- Updates (current)
	   UPDATE _curr
		  SET
            <xsl:for-each select="_column[@_is_primary_key=0]" >
                _curr.[<xsl:value-of select="@_column" />] = _branch.[<xsl:value-of select="@_column" />]
                <xsl:if test="position() != last()">,</xsl:if>
            </xsl:for-each>
	   FROM dbo.[<xsl:value-of select="@_table" />] _curr
	   INNER JOIN dbo.[<xsl:value-of select="@_table" />] _branch
		  ON
          <xsl:for-each select="_column[@_is_primary_key=1]" >
                _curr.[<xsl:value-of select="@_column" />] = _branch.[<xsl:value-of select="@_column" />] AND
            </xsl:for-each>
            _curr.branch_id = 'master'
			 AND _branch.branch_id = @branch_id
	   INNER JOIN dbo.hist_<xsl:value-of select="@_table" /> _branch_hist
		  ON
            <xsl:for-each select="_column[@_is_primary_key=1]" >
                _branch_hist.[<xsl:value-of select="@_column" />] = _branch.[<xsl:value-of select="@_column" />] AND
            </xsl:for-each>
            _branch_hist.branch_id = @branch_id
			 AND valid_to IS NULL
			 AND (
                <xsl:for-each select="_column[@_is_primary_key=0]" >
                    _branch_hist.[<xsl:value-of select="@_column" />] &lt;&gt; _curr.[<xsl:value-of select="@_column" />]
                    <xsl:if test="position() != last()"> OR </xsl:if>
                </xsl:for-each>
			 )
         </xsl:if>
			 
	   -- Deletes (current)
	   DELETE _d
       FROM dbo.[<xsl:value-of select="@_table" />] _d
       INNER JOIN 
        dbo.hist_<xsl:value-of select="@_table" /> _h on 
	    <xsl:for-each select="_column[@_is_primary_key=1]" >
            _d.[<xsl:value-of select="@_column" />] = _h.[<xsl:value-of select="@_column" />] AND
        </xsl:for-each>
        _h.branch_id = @branch_id and _h.is_delete = 1 and _h.valid_to is null and _d.branch_id = 'master'

	   -- Fix previous master history
	   UPDATE h_master
		  SET valid_to = @current_datetime
	   FROM dbo.hist_<xsl:value-of select="@_table" /> h_master
	   INNER JOIN dbo.hist_<xsl:value-of select="@_table" /> h_branch ON
        <xsl:for-each select="_column[@_is_primary_key=1]" >
            h_master.[<xsl:value-of select="@_column" />] = h_branch.[<xsl:value-of select="@_column" />] AND
        </xsl:for-each>
            h_master.branch_id = 'master'
            AND h_branch.branch_id = 'master'
            AND (h_master.version_id &lt;&gt; @merge_version_id OR h_master.version_id IS NULL)
            AND h_branch.version_id = @merge_version_id
            AND h_master.valid_to IS NULL

	   COMMIT TRANSACTION;
    END TRY 
    BEGIN CATCH
	   IF ERROR_NUMBER() &lt;&gt; 60000
		  ROLLBACK TRANSACTION;
	   THROW
    END CATCH
END
</xsl:for-each>
</xsl:template>
</xsl:stylesheet>
