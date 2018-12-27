
    
use meta3
GO

IF OBJECT_ID ('dbo.get_Table') IS NOT NULL 
     DROP PROCEDURE dbo.get_Table
GO
CREATE PROCEDURE dbo.get_Table
(@branch_id NVARCHAR(50) = 'master', @jsonParams nvarchar(max) = '{}')
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
	   --INSERT INTO @SortBy SELECT [key], value FROM OPENJSON(@jsonParams,'$.SortBy')
	  
	   DECLARE @FilterBy TABLE (
		  _id int IDENTITY(1,1) PRIMARY KEY,
		  col NVARCHAR(255), 
		  regex NVARCHAR(MAX)
	   )
	   --INSERT INTO @FilterBy SELECT [key], value FROM OPENJSON(@jsonParams,'$.Filter')

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
		  EXEC('declare @temp nvarchar(1) = (SELECT top 1 left(cast(' + @col_name_s + ' as nvarchar(max)), 1) FROM dbo.[Table])')
		  set @i_s = @i_s + 1
	   END
	   
	   DECLARE @i_f int = 1, @col_name_f nvarchar(255), @regex nvarchar(max)
	   WHILE @i_f <= (select count(*) from @FilterBy)
	   BEGIN
		  set @col_name_f = (select col from @FilterBy where _id = @i_f)
		  set @regex = (select regex from @FilterBy where _id = @i_f)
		  EXEC('declare @temp nvarchar(1) = (SELECT top 1 left(cast(' + @col_name_f + ' as nvarchar(max)), 1) FROM dbo.[Table] WHERE branch_id like ''' + @regex + ''')')
		  set @i_f = @i_f + 1
	   END

	   -- Build query
	   DECLARE @select nvarchar(max) = 'SELECT * FROM dbo.[Table]';
       IF (select count(*) from @FilterBy) > 0 BEGIN
           set @select = @select + ' where ';
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
       END
       IF (select count(*) from @SortBy) > 0 BEGIN
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
       END

	   EXEC(@select)

	   COMMIT TRANSACTION;
    END TRY 
    BEGIN CATCH 
	   ROLLBACK TRANSACTION;
	   THROW
    END CATCH 
END

IF OBJECT_ID ('dbo.get_Column') IS NOT NULL 
     DROP PROCEDURE dbo.get_Column
GO
CREATE PROCEDURE dbo.get_Column
(@branch_id NVARCHAR(50) = 'master', @jsonParams nvarchar(max) = '{}')
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
	   --INSERT INTO @SortBy SELECT [key], value FROM OPENJSON(@jsonParams,'$.SortBy')
	  
	   DECLARE @FilterBy TABLE (
		  _id int IDENTITY(1,1) PRIMARY KEY,
		  col NVARCHAR(255), 
		  regex NVARCHAR(MAX)
	   )
	   --INSERT INTO @FilterBy SELECT [key], value FROM OPENJSON(@jsonParams,'$.Filter')

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
		  EXEC('declare @temp nvarchar(1) = (SELECT top 1 left(cast(' + @col_name_s + ' as nvarchar(max)), 1) FROM dbo.[Column])')
		  set @i_s = @i_s + 1
	   END
	   
	   DECLARE @i_f int = 1, @col_name_f nvarchar(255), @regex nvarchar(max)
	   WHILE @i_f <= (select count(*) from @FilterBy)
	   BEGIN
		  set @col_name_f = (select col from @FilterBy where _id = @i_f)
		  set @regex = (select regex from @FilterBy where _id = @i_f)
		  EXEC('declare @temp nvarchar(1) = (SELECT top 1 left(cast(' + @col_name_f + ' as nvarchar(max)), 1) FROM dbo.[Column] WHERE branch_id like ''' + @regex + ''')')
		  set @i_f = @i_f + 1
	   END

	   -- Build query
	   DECLARE @select nvarchar(max) = 'SELECT * FROM dbo.[Column]';
       IF (select count(*) from @FilterBy) > 0 BEGIN
           set @select = @select + ' where ';
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
       END
       IF (select count(*) from @SortBy) > 0 BEGIN
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
       END

	   EXEC(@select)

	   COMMIT TRANSACTION;
    END TRY 
    BEGIN CATCH 
	   ROLLBACK TRANSACTION;
	   THROW
    END CATCH 
END

IF OBJECT_ID ('dbo.get_Reference') IS NOT NULL 
     DROP PROCEDURE dbo.get_Reference
GO
CREATE PROCEDURE dbo.get_Reference
(@branch_id NVARCHAR(50) = 'master', @jsonParams nvarchar(max) = '{}')
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
	   --INSERT INTO @SortBy SELECT [key], value FROM OPENJSON(@jsonParams,'$.SortBy')
	  
	   DECLARE @FilterBy TABLE (
		  _id int IDENTITY(1,1) PRIMARY KEY,
		  col NVARCHAR(255), 
		  regex NVARCHAR(MAX)
	   )
	   --INSERT INTO @FilterBy SELECT [key], value FROM OPENJSON(@jsonParams,'$.Filter')

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
		  EXEC('declare @temp nvarchar(1) = (SELECT top 1 left(cast(' + @col_name_s + ' as nvarchar(max)), 1) FROM dbo.[Reference])')
		  set @i_s = @i_s + 1
	   END
	   
	   DECLARE @i_f int = 1, @col_name_f nvarchar(255), @regex nvarchar(max)
	   WHILE @i_f <= (select count(*) from @FilterBy)
	   BEGIN
		  set @col_name_f = (select col from @FilterBy where _id = @i_f)
		  set @regex = (select regex from @FilterBy where _id = @i_f)
		  EXEC('declare @temp nvarchar(1) = (SELECT top 1 left(cast(' + @col_name_f + ' as nvarchar(max)), 1) FROM dbo.[Reference] WHERE branch_id like ''' + @regex + ''')')
		  set @i_f = @i_f + 1
	   END

	   -- Build query
	   DECLARE @select nvarchar(max) = 'SELECT * FROM dbo.[Reference]';
       IF (select count(*) from @FilterBy) > 0 BEGIN
           set @select = @select + ' where ';
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
       END
       IF (select count(*) from @SortBy) > 0 BEGIN
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
       END

	   EXEC(@select)

	   COMMIT TRANSACTION;
    END TRY 
    BEGIN CATCH 
	   ROLLBACK TRANSACTION;
	   THROW
    END CATCH 
END

IF OBJECT_ID ('dbo.get_ReferenceDetail') IS NOT NULL 
     DROP PROCEDURE dbo.get_ReferenceDetail
GO
CREATE PROCEDURE dbo.get_ReferenceDetail
(@branch_id NVARCHAR(50) = 'master', @jsonParams nvarchar(max) = '{}')
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
	   --INSERT INTO @SortBy SELECT [key], value FROM OPENJSON(@jsonParams,'$.SortBy')
	  
	   DECLARE @FilterBy TABLE (
		  _id int IDENTITY(1,1) PRIMARY KEY,
		  col NVARCHAR(255), 
		  regex NVARCHAR(MAX)
	   )
	   --INSERT INTO @FilterBy SELECT [key], value FROM OPENJSON(@jsonParams,'$.Filter')

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
		  EXEC('declare @temp nvarchar(1) = (SELECT top 1 left(cast(' + @col_name_s + ' as nvarchar(max)), 1) FROM dbo.[ReferenceDetail])')
		  set @i_s = @i_s + 1
	   END
	   
	   DECLARE @i_f int = 1, @col_name_f nvarchar(255), @regex nvarchar(max)
	   WHILE @i_f <= (select count(*) from @FilterBy)
	   BEGIN
		  set @col_name_f = (select col from @FilterBy where _id = @i_f)
		  set @regex = (select regex from @FilterBy where _id = @i_f)
		  EXEC('declare @temp nvarchar(1) = (SELECT top 1 left(cast(' + @col_name_f + ' as nvarchar(max)), 1) FROM dbo.[ReferenceDetail] WHERE branch_id like ''' + @regex + ''')')
		  set @i_f = @i_f + 1
	   END

	   -- Build query
	   DECLARE @select nvarchar(max) = 'SELECT * FROM dbo.[ReferenceDetail]';
       IF (select count(*) from @FilterBy) > 0 BEGIN
           set @select = @select + ' where ';
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
       END
       IF (select count(*) from @SortBy) > 0 BEGIN
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
       END

	   EXEC(@select)

	   COMMIT TRANSACTION;
    END TRY 
    BEGIN CATCH 
	   ROLLBACK TRANSACTION;
	   THROW
    END CATCH 
END
