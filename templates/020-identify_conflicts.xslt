<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output method="text" indent="no" encoding="UTF-8" omit-xml-declaration="yes" />
    <xsl:strip-space elements="*"/>
    <xsl:template match="tables">
    
use <xsl:value-of select="$metaDbName" />
GO
<xsl:for-each select="//_table" >
IF OBJECT_ID ('dbo.identify_conflicts_<xsl:value-of select="@_table" />') IS NOT NULL 
     DROP PROCEDURE dbo.identify_conflicts_<xsl:value-of select="@_table" />
GO
CREATE PROCEDURE dbo.identify_conflicts_<xsl:value-of select="@_table" />
(@branch_id NVARCHAR(50), @merge_version_id NVARCHAR(50), @min_version_order_master int, @number_of_conflicts int output)
AS
BEGIN
    SET XACT_ABORT, NOCOUNT ON
    DECLARE @msg nvarchar(255)
    BEGIN TRY
       BEGIN TRANSACTION
           -- SANITY CHECKS DONE IN THE CALLER (merge_branch)
       
       set @number_of_conflicts = (
          SELECT COUNT(*)
          FROM dbo.hist_<xsl:value-of select="@_table" /> h_master
             INNER JOIN dbo.hist_<xsl:value-of select="@_table" /> h_branch ON
                <xsl:for-each select="_column[@_is_primary_key=1]" >
                    h_master.[<xsl:value-of select="@_column" />] = h_branch.[<xsl:value-of select="@_column" />] AND
                </xsl:for-each>
                h_master.branch_id = 'master'
                AND h_branch.branch_id = @branch_id
                AND h_master.version_id in (SELECT version_id from dbo.[version] where version_order &gt; @min_version_order_master)
                AND h_master.valid_to IS NULL
                AND h_branch.valid_to IS NULL
                AND (
                        (0 = 1)
                        <xsl:for-each select="_column[@_is_primary_key=0]" >
                        OR
                            (
                              (h_master.[<xsl:value-of select="@_column" />] IS NULL AND h_branch.[<xsl:value-of select="@_column" />] IS NOT NULL)
                              OR
                              (h_master.[<xsl:value-of select="@_column" />] IS NOT NULL AND h_branch.[<xsl:value-of select="@_column" />] IS NULL)
                              OR
                              (h_master.[<xsl:value-of select="@_column" />] &lt;&gt; h_branch.[<xsl:value-of select="@_column" />])
                           )
                        </xsl:for-each>
                    )

       )
       IF @number_of_conflicts &gt; 0 BEGIN
          INSERT INTO dbo.conflicts_<xsl:value-of select="@_table" />
          SELECT @merge_version_id,
          <xsl:for-each select="_column[@_is_primary_key=1]" >
            h_master.[<xsl:value-of select="@_column" />],
        </xsl:for-each>
          h_master.is_delete, h_branch.is_delete,
          <xsl:for-each select="_column[@_is_primary_key=0]" >
            h_master.[<xsl:value-of select="@_column" />],
        </xsl:for-each>         
          <xsl:for-each select="_column[@_is_primary_key=0]" >
            h_branch.[<xsl:value-of select="@_column" />],
        </xsl:for-each>
          h_master.author, h_master.version_id, h_master.valid_from
          FROM
             dbo.hist_<xsl:value-of select="@_table" /> h_master
             INNER JOIN dbo.hist_<xsl:value-of select="@_table" /> h_branch
                ON
                    <xsl:for-each select="_column[@_is_primary_key=1]" >
                        h_master.[<xsl:value-of select="@_column" />] = h_branch.[<xsl:value-of select="@_column" />] AND
                    </xsl:for-each>
                    h_master.branch_id = 'master'
                    AND h_branch.branch_id = @branch_id
                    AND h_master.version_id in (SELECT version_id from dbo.[version] where version_order &gt; @min_version_order_master)
                    AND h_master.valid_to IS NULL
                    AND h_branch.valid_to IS NULL
                    AND (
                        0 = 1
                        <xsl:for-each select="_column[@_is_primary_key=0]" >
                            OR
                            (
                              (h_master.[<xsl:value-of select="@_column" />] IS NULL AND h_branch.[<xsl:value-of select="@_column" />] IS NOT NULL)
                              OR
                              (h_master.[<xsl:value-of select="@_column" />] IS NOT NULL AND h_branch.[<xsl:value-of select="@_column" />] IS NULL)
                              OR
                              (h_master.[<xsl:value-of select="@_column" />] &lt;&gt; h_branch.[<xsl:value-of select="@_column" />])
                           )
                        </xsl:for-each>
                    )
       END
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
