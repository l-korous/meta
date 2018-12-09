
    
use meta3
GO

IF OBJECT_ID ('dbo.ins_Column') IS NOT NULL 
     DROP PROCEDURE dbo.ins_Column
GO
CREATE PROCEDURE dbo.ins_Column(@branch_id NVARCHAR(50)

    , @_name NVARCHAR(255)
    , @_table_name nvarchar(255)
    , @_is_primary_key BIT
    , @_is_unique BIT
    , @_datatype nvarchar(50)
    , @_is_nullable BIT
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
       
            [name] = @_name AND
        
            [table_name] = @_table_name AND
        
       branch_id = @branch_id) BEGIN
		  set @msg = 'ERROR: Column ( '+ 
          
            '[name]: ' + CAST(@_name AS NVARCHAR(MAX)) + ', ' +
        
            '[table_name]: ' + CAST(@_table_name AS NVARCHAR(MAX)) + ', ' +
        
            'branch_id: ' + @branch_id + ') already exists';
		  THROW 50000, @msg, 1
	   END
       
	   declare @current_datetime datetime = getdate()
	   declare @current_version nvarchar(50) = (SELECT current_version_id from [branch] where branch_id = @branch_id)

      INSERT INTO dbo.[Column] VALUES (
        
            @_name,
        
            @_table_name,
        
            @_is_primary_key,
        
            @_is_unique,
        
            @_datatype,
        
            @_is_nullable,
        
         @branch_id
      )

      -- This handles the case when the entry used to exist, and was deleted. So we finish the validity of the deletion.
      UPDATE dbo.hist_Column SET
            valid_to = @current_datetime
         WHERE
            
                [name] = @_name AND
            
                [table_name] = @_table_name AND
            
            branch_id = @branch_id
            AND valid_to IS NULL
         
      INSERT INTO dbo.hist_Column VALUES (
         
            @_name,
        
            @_table_name,
        
            @_is_primary_key,
        
            @_is_unique,
        
            @_datatype,
        
            @_is_nullable,
        
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

    , @_name nvarchar(255)
    , @_src_table nvarchar(255)
    , @_src_column nvarchar(255)
    , @_dest_table nvarchar(255)
    , @_dest_column nvarchar(255)
    , @_on_delete nvarchar(50)
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
       
            [name] = @_name AND
        
       branch_id = @branch_id) BEGIN
		  set @msg = 'ERROR: Reference ( '+ 
          
            '[name]: ' + CAST(@_name AS NVARCHAR(MAX)) + ', ' +
        
            'branch_id: ' + @branch_id + ') already exists';
		  THROW 50000, @msg, 1
	   END
       
	   declare @current_datetime datetime = getdate()
	   declare @current_version nvarchar(50) = (SELECT current_version_id from [branch] where branch_id = @branch_id)

      INSERT INTO dbo.[Reference] VALUES (
        
            @_name,
        
            @_src_table,
        
            @_src_column,
        
            @_dest_table,
        
            @_dest_column,
        
            @_on_delete,
        
         @branch_id
      )

      -- This handles the case when the entry used to exist, and was deleted. So we finish the validity of the deletion.
      UPDATE dbo.hist_Reference SET
            valid_to = @current_datetime
         WHERE
            
                [name] = @_name AND
            
            branch_id = @branch_id
            AND valid_to IS NULL
         
      INSERT INTO dbo.hist_Reference VALUES (
         
            @_name,
        
            @_src_table,
        
            @_src_column,
        
            @_dest_table,
        
            @_dest_column,
        
            @_on_delete,
        
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

IF OBJECT_ID ('dbo.ins_Table') IS NOT NULL 
     DROP PROCEDURE dbo.ins_Table
GO
CREATE PROCEDURE dbo.ins_Table(@branch_id NVARCHAR(50)

    , @_name nvarchar(255)
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
       
            [name] = @_name AND
        
       branch_id = @branch_id) BEGIN
		  set @msg = 'ERROR: Table ( '+ 
          
            '[name]: ' + CAST(@_name AS NVARCHAR(MAX)) + ', ' +
        
            'branch_id: ' + @branch_id + ') already exists';
		  THROW 50000, @msg, 1
	   END
       
	   declare @current_datetime datetime = getdate()
	   declare @current_version nvarchar(50) = (SELECT current_version_id from [branch] where branch_id = @branch_id)

      INSERT INTO dbo.[Table] VALUES (
        
            @_name,
        
         @branch_id
      )

      -- This handles the case when the entry used to exist, and was deleted. So we finish the validity of the deletion.
      UPDATE dbo.hist_Table SET
            valid_to = @current_datetime
         WHERE
            
                [name] = @_name AND
            
            branch_id = @branch_id
            AND valid_to IS NULL
         
      INSERT INTO dbo.hist_Table VALUES (
         
            @_name,
        
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
