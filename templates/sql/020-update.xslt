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
<xsl:if test="count(columns/column[@is_primary_key=0]) &gt; 0">
IF OBJECT_ID ('dbo.update_<xsl:value-of select="@table_name" />') IS NOT NULL 
     DROP PROCEDURE dbo.update_<xsl:value-of select="@table_name" />
GO
CREATE PROCEDURE dbo.update_<xsl:value-of select="@table_name" />(
<xsl:for-each select="columns/column" >
    @<xsl:value-of select="@column_name" />&s;<xsl:value-of select="meta:datatype_to_sql(@datatype)" />,
</xsl:for-each>
@branch_name NVARCHAR(255) ='master'
)
AS
BEGIN
    SET XACT_ABORT, NOCOUNT ON
    DECLARE @msg nvarchar(255)
    BEGIN TRY
    BEGIN TRANSACTION
	   -- SANITY CHECKS
	   -- Branch exists
	   IF NOT EXISTS (select * from dbo.branch where branch_name = @branch_name) BEGIN
         set @msg = 'ERROR: Branch "' + @branch_name + '" does not exist';
         THROW 50000, @msg, 1
      END
	   -- Branch has a current version
	   IF NOT EXISTS (select * from dbo.branch _b inner join dbo.version _v on _b.branch_name = @branch_name and _v.version_name = _b.current_version_name) BEGIN
         set @msg = 'ERROR: Branch "' + @branch_name + '" does not have a current version';
         THROW 50000, @msg, 1
      END
	   -- Branch's current version is open
	   IF (select _v.version_status from dbo.branch _b inner join dbo.version _v on _b.branch_name = @branch_name and _v.version_name = _b.current_version_name) &lt;&gt; 'OPEN' BEGIN
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
       
	   declare @current_datetime datetime = getdate()
	   declare @current_version NVARCHAR(255) = (SELECT current_version_name from [branch] where branch_name = @branch_name)
       
         -- EQUALITY CHECK
         <xsl:for-each select="columns/column[@is_primary_key=0]" >
            declare @<xsl:value-of select="@column_name" />_same bit = (select IIF([<xsl:value-of select="@column_name" />] = @<xsl:value-of select="@column_name" />,1,0) FROM dbo.[<xsl:value-of select="../../@table_name" />] WHERE
            <xsl:for-each select="columns/column[@is_primary_key=1]" >
                [<xsl:value-of select="@column_name" />] = @<xsl:value-of select="@column_name" /> AND
            </xsl:for-each>
            branch_name = @branch_name)
        </xsl:for-each>
         IF
            <xsl:for-each select="columns/column[@is_primary_key=0]" >
                @<xsl:value-of select="@column_name" />_same = 1
                <xsl:if test="position() != last()">AND</xsl:if>
            </xsl:for-each>
            BEGIN
                COMMIT TRANSACTION;
                RETURN
            END

         UPDATE dbo.[<xsl:value-of select="@table_name" />] SET
         <xsl:for-each select="columns/column[@is_primary_key=0]" >
                [<xsl:value-of select="@column_name" />] = @<xsl:value-of select="@column_name" />
                <xsl:if test="position() != last()">,</xsl:if>
            </xsl:for-each>
         WHERE
            <xsl:for-each select="columns/column[@is_primary_key=1]" >
                [<xsl:value-of select="@column_name" />] = @<xsl:value-of select="@column_name" /> AND
            </xsl:for-each>
            branch_name = @branch_name

         -- EXISTENCE of history record for this branch (always true for master)
         IF @branch_name &lt;&gt; 'master' AND NOT EXISTS (SELECT 1 FROM dbo.hist_<xsl:value-of select="@table_name" /> WHERE
         <xsl:for-each select="columns/column[@is_primary_key=1]" >
            [<xsl:value-of select="@column_name" />] = @<xsl:value-of select="@column_name" /> AND
        </xsl:for-each>
         branch_name = @branch_name)
            BEGIN
                INSERT INTO dbo.hist_<xsl:value-of select="@table_name" />
                SELECT
                <xsl:for-each select="columns/column" >
                    [<xsl:value-of select="@column_name" />],
                </xsl:for-each>
                @branch_name, @current_version, valid_from, @current_datetime, is_delete, author
                FROM dbo.hist_<xsl:value-of select="@table_name" /> WHERE
                <xsl:for-each select="columns/column[@is_primary_key=1]" >
                    [<xsl:value-of select="@column_name" />] = @<xsl:value-of select="@column_name" /> AND
                </xsl:for-each>
                branch_name = 'master' and valid_to is null
            END
         ELSE
            BEGIN
                UPDATE dbo.hist_<xsl:value-of select="@table_name" /> SET
                   valid_to = @current_datetime
                WHERE
                   <xsl:for-each select="columns/column[@is_primary_key=1]" >
                        [<xsl:value-of select="@column_name" />] = @<xsl:value-of select="@column_name" /> AND
                    </xsl:for-each>
                   branch_name = @branch_name
                   AND valid_to IS NULL
            END

         INSERT INTO dbo.hist_<xsl:value-of select="@table_name" /> VALUES (
         <xsl:for-each select="columns/column" >
            @<xsl:value-of select="@column_name" />,
        </xsl:for-each>
            @branch_name,
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
</xsl:if>
</xsl:for-each>
</xsl:template>
</xsl:stylesheet>
