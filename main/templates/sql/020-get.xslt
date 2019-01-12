<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:meta="meta">
    <xsl:import href="../utilities.xsl"/>
	<xsl:output method="text" indent="no" encoding="UTF-8" omit-xml-declaration="yes" />
    <xsl:strip-space elements="*"/>
    <xsl:template match="tables">
    
use <xsl:value-of select="//configuration[@key='DbName']/@value" />
GO
<xsl:for-each select="//table" >
IF OBJECT_ID ('dbo.get_<xsl:value-of select="@table_name" />') IS NOT NULL 
     DROP PROCEDURE dbo.get_<xsl:value-of select="@table_name" />
GO
CREATE PROCEDURE dbo.get_<xsl:value-of select="@table_name" />
(@branch_name NVARCHAR(255) = 'master', @jsonParams nvarchar(max) = '{}')
AS
BEGIN
    SET XACT_ABORT, NOCOUNT ON
    DECLARE @msg nvarchar(255)
    BEGIN TRY
    BEGIN TRANSACTION
	   -- SANITY CHECKS
	   -- Branch exists
	   IF NOT EXISTS (select * from meta.branch where branch_name = @branch_name) BEGIN
		  set @msg = 'ERROR: Branch "' + @branch_name + '" does not exist';
		  THROW 50000, @msg, 1
	   END
	  
	   -- Fill tables
	   DECLARE @SortBy TABLE (
		  _id int IDENTITY(1,1) PRIMARY KEY, 
		  col NVARCHAR(255), 
		  dir NVARCHAR(4)
	   )
	   --INSERT INTO @SortBy SELECT [key], value FROM OPENJSON(@jsonParams,'$.SortBy')
	  
	   DECLARE @FilterBy TABLE (
		  _id int IDENTITY(1,1) PRIMARY KEY,
		  col NVARCHAR(255), 
		  regex NVARCHAR(MAX)
	   )
	   --INSERT INTO @FilterBy SELECT [key], value FROM OPENJSON(@jsonParams,'$.Filter')

	   -- Input check
	   DECLARE @i_s int = 1, @col_name_s nvarchar(255), @dir nvarchar(4)
	   WHILE @i_s &lt;= (select count(*) from @SortBy)
	   BEGIN
		  set @col_name_s = (select col from @SortBy where _id = @i_s)
		  set @dir = (select dir from @SortBy where _id = @i_s)
		  IF ((@dir &lt;&gt; 'asc') AND (@dir &lt;&gt; 'desc')) BEGIN
			 set @msg = 'ERROR: Dir must be either ASC or DESC';
			 THROW 50000, @msg, 1
		  END
		  EXEC('declare @temp nvarchar(1) = (SELECT top 1 left(cast(' + @col_name_s + ' as nvarchar(max)), 1) FROM dbo.[<xsl:value-of select="@table_name" />])')
		  set @i_s = @i_s + 1
	   END
	   
	   DECLARE @i_f int = 1, @col_name_f nvarchar(255), @regex nvarchar(max)
	   WHILE @i_f &lt;= (select count(*) from @FilterBy)
	   BEGIN
		  set @col_name_f = (select col from @FilterBy where _id = @i_f)
		  set @regex = (select regex from @FilterBy where _id = @i_f)
		  EXEC('declare @temp nvarchar(1) = (SELECT top 1 left(cast(' + @col_name_f + ' as nvarchar(max)), 1) FROM dbo.[<xsl:value-of select="@table_name" />] WHERE branch_name like ''' + @regex + ''')')
		  set @i_f = @i_f + 1
	   END

	   -- Build query
	   DECLARE @select nvarchar(max) = 'SELECT <xsl:for-each select="columns/column" >[<xsl:value-of select="@column_name" />]<xsl:if test="position() != last()">, </xsl:if></xsl:for-each> FROM dbo.[<xsl:value-of select="@table_name" />]';
       IF (select count(*) from @FilterBy) > 0 BEGIN
           set @select = @select + ' where ';
           set @i_f = 1
           WHILE @i_f &lt;= (select count(*) from @FilterBy)
           BEGIN
              set @col_name_f = (select col from @FilterBy where _id = @i_f)
              set @regex = (select regex from @FilterBy where _id = @i_f)
              IF @i_f &lt;&gt; 1
                 set @select = @select + ' AND '
              set @select = @select + @col_name_f + ' LIKE ''' + @regex + ''''
              set @i_f = @i_f + 1
           END
       END
       IF (select count(*) from @SortBy) > 0 BEGIN
           set @select = @select + ' ORDER BY '
           set @i_s = 1
           WHILE @i_s &lt;= (select count(*) from @SortBy)
           BEGIN
              set @col_name_s = (select col from @SortBy where _id = @i_s)
              set @dir = (select dir from @SortBy where _id = @i_s)
              IF @i_s &lt;&gt; 1
                 set @select = @select + ', '
              set @select = @select + @col_name_s + ' ' + @dir
              set @i_s = @i_s + 1
           END
       END

	   EXEC(@select)

	   COMMIT TRANSACTION;
    END TRY 
    BEGIN CATCH 
	   ROLLBACK TRANSACTION;
	   THROW
    END CATCH 
END
GO
</xsl:for-each>
</xsl:template>
</xsl:stylesheet>
