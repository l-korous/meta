
    
use meta3
GO

IF OBJECT_ID ('dbo.upd_Column') IS NOT NULL 
     DROP PROCEDURE dbo.upd_Column
GO
CREATE PROCEDURE dbo.upd_Column(@branch_id NVARCHAR(50)

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
      -- Record exists
	   IF NOT EXISTS (select * from dbo.[Column] where
       
            [name] = @_name AND
        
            [table_name] = @_table_name AND
        
       branch_id = @branch_id) BEGIN
		  set @msg = 'ERROR: Column ( '+ 
          
            '[name]: ' + CAST(@_name AS NVARCHAR(MAX)) + ', ' +
        
            '[table_name]: ' + CAST(@_table_name AS NVARCHAR(MAX)) + ', ' +
        
            'branch_id: ' + @branch_id + ') does not exist';
		  THROW 50000, @msg, 1
	   END
       
	   declare @current_datetime datetime = getdate()
	   declare @current_version nvarchar(50) = (SELECT current_version_id from [branch] where branch_id = @branch_id)
       
         -- EQUALITY CHECK
         
            declare @_is_primary_key_same bit = (select IIF([is_primary_key] = @_is_primary_key,1,0) FROM dbo.[Column] WHERE
            
            branch_id = @branch_id)
        
            declare @_is_unique_same bit = (select IIF([is_unique] = @_is_unique,1,0) FROM dbo.[Column] WHERE
            
            branch_id = @branch_id)
        
            declare @_datatype_same bit = (select IIF([datatype] = @_datatype,1,0) FROM dbo.[Column] WHERE
            
            branch_id = @branch_id)
        
            declare @_is_nullable_same bit = (select IIF([is_nullable] = @_is_nullable,1,0) FROM dbo.[Column] WHERE
            
            branch_id = @branch_id)
        
         IF
            
                @_is_primary_key_same = 1
                
                    AND
                
                @_is_unique_same = 1
                
                    AND
                
                @_datatype_same = 1
                
                    AND
                
                @_is_nullable_same = 1
                
            BEGIN
                COMMIT TRANSACTION;
                RETURN
            END

         UPDATE dbo.[Column] SET
         
                [is_primary_key] = @_is_primary_key
                    ,
                
                [is_unique] = @_is_unique
                    ,
                
                [datatype] = @_datatype
                    ,
                
                [is_nullable] = @_is_nullable
         WHERE
            
                [name] = @_name AND
            
                [table_name] = @_table_name AND
            
            branch_id = @branch_id

         -- EXISTENCE of history record for this branch (always true for master)
         IF @branch_id <> 'master' AND NOT EXISTS (SELECT 1 FROM dbo.hist_Column WHERE
         
            [name] = @_name AND
        
            [table_name] = @_table_name AND
        
         branch_id = @branch_id)
            BEGIN
                INSERT INTO dbo.hist_Column
                SELECT
                
                    [name],
                
                    [table_name],
                
                    [is_primary_key],
                
                    [is_unique],
                
                    [datatype],
                
                    [is_nullable],
                
                @branch_id, @current_version, valid_from, @current_datetime, is_delete, author
                FROM dbo.hist_Column WHERE
                
                    [name] = @_name AND
                
                    [table_name] = @_table_name AND
                
                branch_id = 'master' and valid_to is null
            END
         ELSE
            BEGIN
                UPDATE dbo.hist_Column SET
                   valid_to = @current_datetime
                WHERE
                   
                        [name] = @_name AND
                    
                        [table_name] = @_table_name AND
                    
                   branch_id = @branch_id
                   AND valid_to IS NULL
            END

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

IF OBJECT_ID ('dbo.upd_Reference') IS NOT NULL 
     DROP PROCEDURE dbo.upd_Reference
GO
CREATE PROCEDURE dbo.upd_Reference(@branch_id NVARCHAR(50)

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
      -- Record exists
	   IF NOT EXISTS (select * from dbo.[Reference] where
       
            [name] = @_name AND
        
       branch_id = @branch_id) BEGIN
		  set @msg = 'ERROR: Reference ( '+ 
          
            '[name]: ' + CAST(@_name AS NVARCHAR(MAX)) + ', ' +
        
            'branch_id: ' + @branch_id + ') does not exist';
		  THROW 50000, @msg, 1
	   END
       
	   declare @current_datetime datetime = getdate()
	   declare @current_version nvarchar(50) = (SELECT current_version_id from [branch] where branch_id = @branch_id)
       
         -- EQUALITY CHECK
         
            declare @_src_table_same bit = (select IIF([src_table] = @_src_table,1,0) FROM dbo.[Reference] WHERE
            
            branch_id = @branch_id)
        
            declare @_src_column_same bit = (select IIF([src_column] = @_src_column,1,0) FROM dbo.[Reference] WHERE
            
            branch_id = @branch_id)
        
            declare @_dest_table_same bit = (select IIF([dest_table] = @_dest_table,1,0) FROM dbo.[Reference] WHERE
            
            branch_id = @branch_id)
        
            declare @_dest_column_same bit = (select IIF([dest_column] = @_dest_column,1,0) FROM dbo.[Reference] WHERE
            
            branch_id = @branch_id)
        
            declare @_on_delete_same bit = (select IIF([on_delete] = @_on_delete,1,0) FROM dbo.[Reference] WHERE
            
            branch_id = @branch_id)
        
         IF
            
                @_src_table_same = 1
                
                    AND
                
                @_src_column_same = 1
                
                    AND
                
                @_dest_table_same = 1
                
                    AND
                
                @_dest_column_same = 1
                
                    AND
                
                @_on_delete_same = 1
                
            BEGIN
                COMMIT TRANSACTION;
                RETURN
            END

         UPDATE dbo.[Reference] SET
         
                [src_table] = @_src_table
                    ,
                
                [src_column] = @_src_column
                    ,
                
                [dest_table] = @_dest_table
                    ,
                
                [dest_column] = @_dest_column
                    ,
                
                [on_delete] = @_on_delete
         WHERE
            
                [name] = @_name AND
            
            branch_id = @branch_id

         -- EXISTENCE of history record for this branch (always true for master)
         IF @branch_id <> 'master' AND NOT EXISTS (SELECT 1 FROM dbo.hist_Reference WHERE
         
            [name] = @_name AND
        
         branch_id = @branch_id)
            BEGIN
                INSERT INTO dbo.hist_Reference
                SELECT
                
                    [name],
                
                    [src_table],
                
                    [src_column],
                
                    [dest_table],
                
                    [dest_column],
                
                    [on_delete],
                
                @branch_id, @current_version, valid_from, @current_datetime, is_delete, author
                FROM dbo.hist_Reference WHERE
                
                    [name] = @_name AND
                
                branch_id = 'master' and valid_to is null
            END
         ELSE
            BEGIN
                UPDATE dbo.hist_Reference SET
                   valid_to = @current_datetime
                WHERE
                   
                        [name] = @_name AND
                    
                   branch_id = @branch_id
                   AND valid_to IS NULL
            END

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
