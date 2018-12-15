
    
use meta3
GO
IF OBJECT_ID ('dbo.create_branch') IS NOT NULL 
     DROP PROCEDURE dbo.create_branch
GO
CREATE PROCEDURE dbo.create_branch
(@branch_id NVARCHAR(50), @version_id NVARCHAR(50))
AS
BEGIN
    SET XACT_ABORT, NOCOUNT ON
    DECLARE @msg nvarchar(255)
    BEGIN TRY
    BEGIN TRANSACTION
	   -- SANITY CHECKS
	   -- Branch does not exist
	   IF EXISTS (select * from dbo.branch where branch_id = @branch_id)
		  BEGIN
			 set @msg = 'ERROR: Branch ' + @branch_id + ' already exists';
			 THROW 50000, @msg, 1
		  END
	   -- Version does not exist
	   IF EXISTS (select * from dbo.version where version_id = @version_id)
		  BEGIN
			 set @msg = 'ERROR: Version ' + @version_id + ' already exists';
			 THROW 50000, @msg, 1
		  END

	   declare @start_master_version_id NVARCHAR(50) = (select last_closed_version_id from dbo.branch where branch_id = 'master')
	   declare @max_version_order_plus_one int = (SELECT MAX(version_order) from dbo.version) + 1
		  
	   insert into dbo.branch values (@branch_id, @start_master_version_id, NULL, NULL)
	   insert into dbo.version values (@version_id, @branch_id, @start_master_version_id, @max_version_order_plus_one, 'open')
	   update branch set last_closed_version_id = @start_master_version_id where branch_id = @branch_id
	   update branch set current_version_id = @version_id where branch_id = @branch_id

	   EXEC sp_MSforeachtable "ALTER TABLE ? NOCHECK CONSTRAINT all"
        
            insert into dbo.[Table]
            select 
            
                [table_name],
            
                @branch_id
            from dbo.[Table]
            where branch_id = 'master'
        
            insert into dbo.[Column]
            select 
            
                [column_name],
            
                [table_name],
            
                [datatype],
            
                [is_primary_key],
            
                [is_unique],
            
                [is_nullable],
            
                @branch_id
            from dbo.[Column]
            where branch_id = 'master'
        
            insert into dbo.[Reference]
            select 
            
                [reference_name],
            
                [src_table_name],
            
                [dest_table_name],
            
                [on_delete],
            
                @branch_id
            from dbo.[Reference]
            where branch_id = 'master'
        
            insert into dbo.[ReferenceDetail]
            select 
            
                [reference_name],
            
                [src_table_name],
            
                [src_column_name],
            
                [dest_table_name],
            
                [dest_column_name],
            
                @branch_id
            from dbo.[ReferenceDetail]
            where branch_id = 'master'
        
	   exec sp_MSforeachtable "ALTER TABLE ? WITH CHECK CHECK CONSTRAINT all"

	   COMMIT TRANSACTION;
    END TRY 
    BEGIN CATCH 
	   ROLLBACK TRANSACTION;
	   THROW
    END CATCH
END
