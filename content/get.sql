use metaSimple2

IF OBJECT_ID ('dbo.[get]') IS NOT NULL 
     DROP PROCEDURE dbo.[get]
GO

CREATE PROCEDURE dbo.[get]
(@table NVARCHAR(255), @branch_id NVARCHAR(50), @jsonParams nvarchar(max))
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
	  
	   -- Fill tables
	   DECLARE @SortBy TABLE (
		  _id int IDENTITY(1,1) PRIMARY KEY, 
		  col NVARCHAR(255), 
		  dir NVARCHAR(4)
	   )
	   INSERT INTO @SortBy SELECT [key], value FROM OPENJSON(@jsonParams,'$.SortBy')
	  
	   DECLARE @FilterBy TABLE (
		  _id int IDENTITY(1,1) PRIMARY KEY,
		  col NVARCHAR(255), 
		  regex NVARCHAR(MAX)
	   )
	   INSERT INTO @FilterBy SELECT [key], value FROM OPENJSON(@jsonParams,'$.Filter')

	   -- Input check
	   DECLARE @i_s int = 1, @col_name_s nvarchar(255), @dir nvarchar(4)
	   WHILE @i_s <= (select count(*) from @SortBy)
	   BEGIN
		  set @col_name_s = (select col from @SortBy where _id = @i_s)
		  set @dir = (select dir from @SortBy where _id = @i_s)
		  IF ((@dir <> 'asc') AND (@dir <> 'desc')) BEGIN
			 set @msg = 'ERROR: Dir must be either ASC or DESC';
			 THROW 50000, @msg, 1
		  END
		  EXEC('declare @temp nvarchar(1) = (SELECT top 1 left(cast(' + @col_name_s + ' as nvarchar(max)), 1) FROM dbo.' + @table + ')')
		  set @i_s = @i_s + 1
	   END
	   
	   DECLARE @i_f int = 1, @col_name_f nvarchar(255), @regex nvarchar(max)
	   WHILE @i_f <= (select count(*) from @FilterBy)
	   BEGIN
		  set @col_name_f = (select col from @FilterBy where _id = @i_f)
		  set @regex = (select regex from @FilterBy where _id = @i_f)
		  EXEC('declare @temp nvarchar(1) = (SELECT top 1 left(cast(' + @col_name_f + ' as nvarchar(max)), 1) FROM dbo.' + @table + ' WHERE branch_id like ''' + @regex + ''')')
		  set @i_f = @i_f + 1
	   END

	   -- Build query
	   DECLARE @select nvarchar(max) = 'SELECT * FROM dbo.' + @table + ' where ';
	   set @i_f = 1
	   WHILE @i_f <= (select count(*) from @FilterBy)
	   BEGIN
		  set @col_name_f = (select col from @FilterBy where _id = @i_f)
		  set @regex = (select regex from @FilterBy where _id = @i_f)
		  IF @i_f <> 1
			 set @select = @select + ' AND '
		  set @select = @select + @col_name_f + ' LIKE ''' + @regex + ''''
		  set @i_f = @i_f + 1
	   END
	   set @select = @select + ' ORDER BY '
	   set @i_s = 1
	   WHILE @i_s <= (select count(*) from @SortBy)
	   BEGIN
		  set @col_name_s = (select col from @SortBy where _id = @i_s)
		  set @dir = (select dir from @SortBy where _id = @i_s)
		  IF @i_s <> 1
			 set @select = @select + ', '
		  set @select = @select + @col_name_s + ' ' + @dir
		  set @i_s = @i_s + 1
	   END

	   print @select
	   EXEC(@select)

	   COMMIT TRANSACTION;
    END TRY 
    BEGIN CATCH 
	   ROLLBACK TRANSACTION;
	   THROW
    END CATCH 
END