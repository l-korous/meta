<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:meta="meta">
    <xsl:import href="../utilities.xsl"/>
	<xsl:output method="text" indent="no" encoding="UTF-8" omit-xml-declaration="yes" />
    <xsl:strip-space elements="*"/>
    <xsl:template match="tables">
    
use <xsl:value-of select="//configuration[@key='DbName']/@value" />
GO
<xsl:for-each select="//table" >
IF OBJECT_ID ('dbo.identify_conflicts_<xsl:value-of select="@table_name" />') IS NOT NULL 
     DROP PROCEDURE dbo.identify_conflicts_<xsl:value-of select="@table_name" />
GO
CREATE PROCEDURE dbo.identify_conflicts_<xsl:value-of select="@table_name" />
(@branch_name NVARCHAR(255), @merge_version_name NVARCHAR(255), @min_version_order_master int, @number_of_conflicts int output)
AS
BEGIN
    SET XACT_ABORT, NOCOUNT ON
    DECLARE @msg nvarchar(255)
    BEGIN TRY
       BEGIN TRANSACTION
           -- SANITY CHECKS DONE IN THE CALLER (merge_branch)
       
       set @number_of_conflicts = (
          SELECT COUNT(*)
          FROM dbo.hist_<xsl:value-of select="@table_name" /> h_master
             INNER JOIN dbo.hist_<xsl:value-of select="@table_name" /> h_branch ON
                <xsl:for-each select="columns/column[@is_primary_key=1]" >
                    h_master.[<xsl:value-of select="@column_name" />] = h_branch.[<xsl:value-of select="@column_name" />] AND
                </xsl:for-each>
                h_master.branch_name = 'master'
                AND h_branch.branch_name = @branch_name
                AND h_master.version_name in (SELECT version_name from dbo.[version] where version_order &gt; @min_version_order_master)
                AND h_master.valid_to IS NULL
                AND h_branch.valid_to IS NULL
                AND (
                        (0 = 1)
                        <xsl:for-each select="columns/column[@is_primary_key=0]" >
                        OR
                            (
                              (h_master.[<xsl:value-of select="@column_name" />] IS NULL AND h_branch.[<xsl:value-of select="@column_name" />] IS NOT NULL)
                              OR
                              (h_master.[<xsl:value-of select="@column_name" />] IS NOT NULL AND h_branch.[<xsl:value-of select="@column_name" />] IS NULL)
                              OR
                              (h_master.[<xsl:value-of select="@column_name" />] &lt;&gt; h_branch.[<xsl:value-of select="@column_name" />])
                           )
                        </xsl:for-each>
                    )

       )
       IF @number_of_conflicts &gt; 0 BEGIN
          INSERT INTO dbo.conflicts_<xsl:value-of select="@table_name" />
          SELECT @merge_version_name,
          <xsl:for-each select="columns/column[@is_primary_key=1]" >
            h_master.[<xsl:value-of select="@column_name" />],
        </xsl:for-each>
          h_master.is_delete, h_branch.is_delete,
          <xsl:for-each select="columns/column[@is_primary_key=0]" >
            h_master.[<xsl:value-of select="@column_name" />],
        </xsl:for-each>         
          <xsl:for-each select="columns/column[@is_primary_key=0]" >
            h_branch.[<xsl:value-of select="@column_name" />],
        </xsl:for-each>
          h_master.author, h_master.version_name, h_master.valid_from
          FROM
             dbo.hist_<xsl:value-of select="@table_name" /> h_master
             INNER JOIN dbo.hist_<xsl:value-of select="@table_name" /> h_branch
                ON
                    <xsl:for-each select="columns/column[@is_primary_key=1]" >
                        h_master.[<xsl:value-of select="@column_name" />] = h_branch.[<xsl:value-of select="@column_name" />] AND
                    </xsl:for-each>
                    h_master.branch_name = 'master'
                    AND h_branch.branch_name = @branch_name
                    AND h_master.version_name in (SELECT version_name from dbo.[version] where version_order &gt; @min_version_order_master)
                    AND h_master.valid_to IS NULL
                    AND h_branch.valid_to IS NULL
                    AND (
                        0 = 1
                        <xsl:for-each select="columns/column[@is_primary_key=0]" >
                            OR
                            (
                              (h_master.[<xsl:value-of select="@column_name" />] IS NULL AND h_branch.[<xsl:value-of select="@column_name" />] IS NOT NULL)
                              OR
                              (h_master.[<xsl:value-of select="@column_name" />] IS NOT NULL AND h_branch.[<xsl:value-of select="@column_name" />] IS NULL)
                              OR
                              (h_master.[<xsl:value-of select="@column_name" />] &lt;&gt; h_branch.[<xsl:value-of select="@column_name" />])
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
GO
</xsl:for-each>
</xsl:template>
</xsl:stylesheet>
