
    
use meta3
GO

IF OBJECT_ID ('dbo.upd_Column') IS NOT NULL 
     DROP PROCEDURE dbo.upd_Column
GO
CREATE PROCEDURE dbo.upd_Column(

    @column_name nvarchar(255),

    @table_name nvarchar(255),

    @datatype nvarchar(255),

    @is_primary_key BIT,

    @is_unique BIT,

    @is_nullable BIT,

@branch_id NVARCHAR(50) ='master'
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
       
            [column_name] = @column_name AND
        
            [table_name] = @table_name AND
        
       branch_id = @branch_id) BEGIN
		  set @msg = 'ERROR: Column ( '+ 
          
            '[column_name]: ' + CAST(@column_name AS NVARCHAR(MAX)) + ', ' +
        
            '[table_name]: ' + CAST(@table_name AS NVARCHAR(MAX)) + ', ' +
        
            'branch_id: ' + @branch_id + ') does not exist';
		  THROW 50000, @msg, 1
	   END
       
	   declare @current_datetime datetime = getdate()
	   declare @current_version nvarchar(50) = (SELECT current_version_id from [branch] where branch_id = @branch_id)
       
         -- EQUALITY CHECK
         
            declare @datatype_same bit = (select IIF([datatype] = @datatype,1,0) FROM dbo.[Column] WHERE
            
            branch_id = @branch_id)
        
            declare @is_primary_key_same bit = (select IIF([is_primary_key] = @is_primary_key,1,0) FROM dbo.[Column] WHERE
            
            branch_id = @branch_id)
        
            declare @is_unique_same bit = (select IIF([is_unique] = @is_unique,1,0) FROM dbo.[Column] WHERE
            
            branch_id = @branch_id)
        
            declare @is_nullable_same bit = (select IIF([is_nullable] = @is_nullable,1,0) FROM dbo.[Column] WHERE
            
            branch_id = @branch_id)
        
         IF
            
                @datatype_same = 1
                
                    AND
                
                @is_primary_key_same = 1
                
                    AND
                
                @is_unique_same = 1
                
                    AND
                
                @is_nullable_same = 1
                
            BEGIN
                COMMIT TRANSACTION;
                RETURN
            END

         UPDATE dbo.[Column] SET
         
                [datatype] = @datatype
                    ,
                
                [is_primary_key] = @is_primary_key
                    ,
                
                [is_unique] = @is_unique
                    ,
                
                [is_nullable] = @is_nullable
         WHERE
            
                [column_name] = @column_name AND
            
                [table_name] = @table_name AND
            
            branch_id = @branch_id

         -- EXISTENCE of history record for this branch (always true for master)
         IF @branch_id <> 'master' AND NOT EXISTS (SELECT 1 FROM dbo.hist_Column WHERE
         
            [column_name] = @column_name AND
        
            [table_name] = @table_name AND
        
         branch_id = @branch_id)
            BEGIN
                INSERT INTO dbo.hist_Column
                SELECT
                
                    [column_name],
                
                    [table_name],
                
                    [datatype],
                
                    [is_primary_key],
                
                    [is_unique],
                
                    [is_nullable],
                
                @branch_id, @current_version, valid_from, @current_datetime, is_delete, author
                FROM dbo.hist_Column WHERE
                
                    [column_name] = @column_name AND
                
                    [table_name] = @table_name AND
                
                branch_id = 'master' and valid_to is null
            END
         ELSE
            BEGIN
                UPDATE dbo.hist_Column SET
                   valid_to = @current_datetime
                WHERE
                   
                        [column_name] = @column_name AND
                    
                        [table_name] = @table_name AND
                    
                   branch_id = @branch_id
                   AND valid_to IS NULL
            END

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

IF OBJECT_ID ('dbo.upd_Reference') IS NOT NULL 
     DROP PROCEDURE dbo.upd_Reference
GO
CREATE PROCEDURE dbo.upd_Reference(

    @reference_name nvarchar(255),

    @src_table_name nvarchar(255),

    @dest_table_name nvarchar(255),

    @on_delete nvarchar(255),

@branch_id NVARCHAR(50) ='master'
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
       
            [reference_name] = @reference_name AND
        
       branch_id = @branch_id) BEGIN
		  set @msg = 'ERROR: Reference ( '+ 
          
            '[reference_name]: ' + CAST(@reference_name AS NVARCHAR(MAX)) + ', ' +
        
            'branch_id: ' + @branch_id + ') does not exist';
		  THROW 50000, @msg, 1
	   END
       
	   declare @current_datetime datetime = getdate()
	   declare @current_version nvarchar(50) = (SELECT current_version_id from [branch] where branch_id = @branch_id)
       
         -- EQUALITY CHECK
         
            declare @src_table_name_same bit = (select IIF([src_table_name] = @src_table_name,1,0) FROM dbo.[Reference] WHERE
            
            branch_id = @branch_id)
        
            declare @dest_table_name_same bit = (select IIF([dest_table_name] = @dest_table_name,1,0) FROM dbo.[Reference] WHERE
            
            branch_id = @branch_id)
        
            declare @on_delete_same bit = (select IIF([on_delete] = @on_delete,1,0) FROM dbo.[Reference] WHERE
            
            branch_id = @branch_id)
        
         IF
            
                @src_table_name_same = 1
                
                    AND
                
                @dest_table_name_same = 1
                
                    AND
                
                @on_delete_same = 1
                
            BEGIN
                COMMIT TRANSACTION;
                RETURN
            END

         UPDATE dbo.[Reference] SET
         
                [src_table_name] = @src_table_name
                    ,
                
                [dest_table_name] = @dest_table_name
                    ,
                
                [on_delete] = @on_delete
         WHERE
            
                [reference_name] = @reference_name AND
            
            branch_id = @branch_id

         -- EXISTENCE of history record for this branch (always true for master)
         IF @branch_id <> 'master' AND NOT EXISTS (SELECT 1 FROM dbo.hist_Reference WHERE
         
            [reference_name] = @reference_name AND
        
         branch_id = @branch_id)
            BEGIN
                INSERT INTO dbo.hist_Reference
                SELECT
                
                    [reference_name],
                
                    [src_table_name],
                
                    [dest_table_name],
                
                    [on_delete],
                
                @branch_id, @current_version, valid_from, @current_datetime, is_delete, author
                FROM dbo.hist_Reference WHERE
                
                    [reference_name] = @reference_name AND
                
                branch_id = 'master' and valid_to is null
            END
         ELSE
            BEGIN
                UPDATE dbo.hist_Reference SET
                   valid_to = @current_datetime
                WHERE
                   
                        [reference_name] = @reference_name AND
                    
                   branch_id = @branch_id
                   AND valid_to IS NULL
            END

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

IF OBJECT_ID ('dbo.upd_ReferenceDetail') IS NOT NULL 
     DROP PROCEDURE dbo.upd_ReferenceDetail
GO
CREATE PROCEDURE dbo.upd_ReferenceDetail(

    @reference_name nvarchar(255),

    @src_table_name nvarchar(255),

    @src_column_name nvarchar(255),

    @dest_table_name nvarchar(255),

    @dest_column_name nvarchar(255),

@branch_id NVARCHAR(50) ='master'
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
	   IF NOT EXISTS (select * from dbo.[ReferenceDetail] where
       
            [reference_name] = @reference_name AND
        
            [src_column_name] = @src_column_name AND
        
       branch_id = @branch_id) BEGIN
		  set @msg = 'ERROR: ReferenceDetail ( '+ 
          
            '[reference_name]: ' + CAST(@reference_name AS NVARCHAR(MAX)) + ', ' +
        
            '[src_column_name]: ' + CAST(@src_column_name AS NVARCHAR(MAX)) + ', ' +
        
            'branch_id: ' + @branch_id + ') does not exist';
		  THROW 50000, @msg, 1
	   END
       
	   declare @current_datetime datetime = getdate()
	   declare @current_version nvarchar(50) = (SELECT current_version_id from [branch] where branch_id = @branch_id)
       
         -- EQUALITY CHECK
         
            declare @src_table_name_same bit = (select IIF([src_table_name] = @src_table_name,1,0) FROM dbo.[ReferenceDetail] WHERE
            
            branch_id = @branch_id)
        
            declare @dest_table_name_same bit = (select IIF([dest_table_name] = @dest_table_name,1,0) FROM dbo.[ReferenceDetail] WHERE
            
            branch_id = @branch_id)
        
            declare @dest_column_name_same bit = (select IIF([dest_column_name] = @dest_column_name,1,0) FROM dbo.[ReferenceDetail] WHERE
            
            branch_id = @branch_id)
        
         IF
            
                @src_table_name_same = 1
                
                    AND
                
                @dest_table_name_same = 1
                
                    AND
                
                @dest_column_name_same = 1
                
            BEGIN
                COMMIT TRANSACTION;
                RETURN
            END

         UPDATE dbo.[ReferenceDetail] SET
         
                [src_table_name] = @src_table_name
                    ,
                
                [dest_table_name] = @dest_table_name
                    ,
                
                [dest_column_name] = @dest_column_name
         WHERE
            
                [reference_name] = @reference_name AND
            
                [src_column_name] = @src_column_name AND
            
            branch_id = @branch_id

         -- EXISTENCE of history record for this branch (always true for master)
         IF @branch_id <> 'master' AND NOT EXISTS (SELECT 1 FROM dbo.hist_ReferenceDetail WHERE
         
            [reference_name] = @reference_name AND
        
            [src_column_name] = @src_column_name AND
        
         branch_id = @branch_id)
            BEGIN
                INSERT INTO dbo.hist_ReferenceDetail
                SELECT
                
                    [reference_name],
                
                    [src_table_name],
                
                    [src_column_name],
                
                    [dest_table_name],
                
                    [dest_column_name],
                
                @branch_id, @current_version, valid_from, @current_datetime, is_delete, author
                FROM dbo.hist_ReferenceDetail WHERE
                
                    [reference_name] = @reference_name AND
                
                    [src_column_name] = @src_column_name AND
                
                branch_id = 'master' and valid_to is null
            END
         ELSE
            BEGIN
                UPDATE dbo.hist_ReferenceDetail SET
                   valid_to = @current_datetime
                WHERE
                   
                        [reference_name] = @reference_name AND
                    
                        [src_column_name] = @src_column_name AND
                    
                   branch_id = @branch_id
                   AND valid_to IS NULL
            END

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
