
    
use meta3
GO

IF OBJECT_ID ('dbo.ins_Table') IS NOT NULL 
     DROP PROCEDURE dbo.ins_Table
GO
CREATE PROCEDURE dbo.ins_Table(@branch_id NVARCHAR(50)

    , @table_name nvarchar(255)
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
	   IF (select _v.version_status from dbo.branch _b inner join dbo.version _v on _b.branch_id = @branch_id and _v.version_id = _b.current_version_id) <> 'open' BEGIN
		  set @msg = 'ERROR: Branch ' + @branch_id + ' has a current version, but it is not open';
		  THROW 50000, @msg, 1
	   END
      -- Record does not exist
      IF EXISTS (select * from dbo.[Table] where
       
            [table_name] = @table_name AND
        
       branch_id = @branch_id) BEGIN
		  set @msg = 'ERROR: Table ( '+ 
          
            '[table_name]: ' + CAST(@table_name AS NVARCHAR(MAX)) + ', ' +
        
            'branch_id: ' + @branch_id + ') already exists';
		  THROW 50000, @msg, 1
	   END
       
	   declare @current_datetime datetime = getdate()
	   declare @current_version nvarchar(50) = (SELECT current_version_id from [branch] where branch_id = @branch_id)

      INSERT INTO dbo.[Table] VALUES (
        
            @table_name,
        
         @branch_id
      )

      -- This handles the case when the entry used to exist, and was deleted. So we finish the validity of the deletion.
      UPDATE dbo.hist_Table SET
            valid_to = @current_datetime
         WHERE
            
                [table_name] = @table_name AND
            
            branch_id = @branch_id
            AND valid_to IS NULL
         
      INSERT INTO dbo.hist_Table VALUES (
         
            @table_name,
        
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

IF OBJECT_ID ('dbo.ins_Column') IS NOT NULL 
     DROP PROCEDURE dbo.ins_Column
GO
CREATE PROCEDURE dbo.ins_Column(@branch_id NVARCHAR(50)

    , @column_name nvarchar(255)
    , @table_name nvarchar(255)
    , @datatype nvarchar(255)
    , @is_primary_key BIT
    , @is_unique BIT
    , @is_nullable BIT
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
	   IF (select _v.version_status from dbo.branch _b inner join dbo.version _v on _b.branch_id = @branch_id and _v.version_id = _b.current_version_id) <> 'open' BEGIN
		  set @msg = 'ERROR: Branch ' + @branch_id + ' has a current version, but it is not open';
		  THROW 50000, @msg, 1
	   END
      -- Record does not exist
      IF EXISTS (select * from dbo.[Column] where
       
            [column_name] = @column_name AND
        
            [table_name] = @table_name AND
        
       branch_id = @branch_id) BEGIN
		  set @msg = 'ERROR: Column ( '+ 
          
            '[column_name]: ' + CAST(@column_name AS NVARCHAR(MAX)) + ', ' +
        
            '[table_name]: ' + CAST(@table_name AS NVARCHAR(MAX)) + ', ' +
        
            'branch_id: ' + @branch_id + ') already exists';
		  THROW 50000, @msg, 1
	   END
       
	   declare @current_datetime datetime = getdate()
	   declare @current_version nvarchar(50) = (SELECT current_version_id from [branch] where branch_id = @branch_id)

      INSERT INTO dbo.[Column] VALUES (
        
            @column_name,
        
            @table_name,
        
            @datatype,
        
            @is_primary_key,
        
            @is_unique,
        
            @is_nullable,
        
         @branch_id
      )

      -- This handles the case when the entry used to exist, and was deleted. So we finish the validity of the deletion.
      UPDATE dbo.hist_Column SET
            valid_to = @current_datetime
         WHERE
            
                [column_name] = @column_name AND
            
                [table_name] = @table_name AND
            
            branch_id = @branch_id
            AND valid_to IS NULL
         
      INSERT INTO dbo.hist_Column VALUES (
         
            @column_name,
        
            @table_name,
        
            @datatype,
        
            @is_primary_key,
        
            @is_unique,
        
            @is_nullable,
        
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

IF OBJECT_ID ('dbo.ins_Reference') IS NOT NULL 
     DROP PROCEDURE dbo.ins_Reference
GO
CREATE PROCEDURE dbo.ins_Reference(@branch_id NVARCHAR(50)

    , @reference_name nvarchar(255)
    , @src_table_name nvarchar(255)
    , @dest_table_name nvarchar(255)
    , @on_delete nvarchar(255)
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
	   IF (select _v.version_status from dbo.branch _b inner join dbo.version _v on _b.branch_id = @branch_id and _v.version_id = _b.current_version_id) <> 'open' BEGIN
		  set @msg = 'ERROR: Branch ' + @branch_id + ' has a current version, but it is not open';
		  THROW 50000, @msg, 1
	   END
      -- Record does not exist
      IF EXISTS (select * from dbo.[Reference] where
       
            [reference_name] = @reference_name AND
        
       branch_id = @branch_id) BEGIN
		  set @msg = 'ERROR: Reference ( '+ 
          
            '[reference_name]: ' + CAST(@reference_name AS NVARCHAR(MAX)) + ', ' +
        
            'branch_id: ' + @branch_id + ') already exists';
		  THROW 50000, @msg, 1
	   END
       
	   declare @current_datetime datetime = getdate()
	   declare @current_version nvarchar(50) = (SELECT current_version_id from [branch] where branch_id = @branch_id)

      INSERT INTO dbo.[Reference] VALUES (
        
            @reference_name,
        
            @src_table_name,
        
            @dest_table_name,
        
            @on_delete,
        
         @branch_id
      )

      -- This handles the case when the entry used to exist, and was deleted. So we finish the validity of the deletion.
      UPDATE dbo.hist_Reference SET
            valid_to = @current_datetime
         WHERE
            
                [reference_name] = @reference_name AND
            
            branch_id = @branch_id
            AND valid_to IS NULL
         
      INSERT INTO dbo.hist_Reference VALUES (
         
            @reference_name,
        
            @src_table_name,
        
            @dest_table_name,
        
            @on_delete,
        
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

IF OBJECT_ID ('dbo.ins_ReferenceDetail') IS NOT NULL 
     DROP PROCEDURE dbo.ins_ReferenceDetail
GO
CREATE PROCEDURE dbo.ins_ReferenceDetail(@branch_id NVARCHAR(50)

    , @reference_name nvarchar(255)
    , @src_table_name nvarchar(255)
    , @src_column_name nvarchar(255)
    , @dest_table_name nvarchar(255)
    , @dest_column_name nvarchar(255)
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
	   IF (select _v.version_status from dbo.branch _b inner join dbo.version _v on _b.branch_id = @branch_id and _v.version_id = _b.current_version_id) <> 'open' BEGIN
		  set @msg = 'ERROR: Branch ' + @branch_id + ' has a current version, but it is not open';
		  THROW 50000, @msg, 1
	   END
      -- Record does not exist
      IF EXISTS (select * from dbo.[ReferenceDetail] where
       
            [reference_name] = @reference_name AND
        
            [src_column_name] = @src_column_name AND
        
       branch_id = @branch_id) BEGIN
		  set @msg = 'ERROR: ReferenceDetail ( '+ 
          
            '[reference_name]: ' + CAST(@reference_name AS NVARCHAR(MAX)) + ', ' +
        
            '[src_column_name]: ' + CAST(@src_column_name AS NVARCHAR(MAX)) + ', ' +
        
            'branch_id: ' + @branch_id + ') already exists';
		  THROW 50000, @msg, 1
	   END
       
	   declare @current_datetime datetime = getdate()
	   declare @current_version nvarchar(50) = (SELECT current_version_id from [branch] where branch_id = @branch_id)

      INSERT INTO dbo.[ReferenceDetail] VALUES (
        
            @reference_name,
        
            @src_table_name,
        
            @src_column_name,
        
            @dest_table_name,
        
            @dest_column_name,
        
         @branch_id
      )

      -- This handles the case when the entry used to exist, and was deleted. So we finish the validity of the deletion.
      UPDATE dbo.hist_ReferenceDetail SET
            valid_to = @current_datetime
         WHERE
            
                [reference_name] = @reference_name AND
            
                [src_column_name] = @src_column_name AND
            
            branch_id = @branch_id
            AND valid_to IS NULL
         
      INSERT INTO dbo.hist_ReferenceDetail VALUES (
         
            @reference_name,
        
            @src_table_name,
        
            @src_column_name,
        
            @dest_table_name,
        
            @dest_column_name,
        
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
