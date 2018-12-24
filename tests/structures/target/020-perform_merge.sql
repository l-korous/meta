
    
use meta3
GO

IF OBJECT_ID ('dbo.perform_merge_Table') IS NOT NULL 
     DROP PROCEDURE dbo.perform_merge_Table
GO
CREATE PROCEDURE dbo.perform_merge_Table
(@branch_id NVARCHAR(50), @merge_version_id NVARCHAR(50), @current_datetime datetime)
AS
BEGIN
    SET XACT_ABORT, NOCOUNT ON
    DECLARE @msg nvarchar(255)
    BEGIN TRY
	   BEGIN TRANSACTION
       -- SANITY CHECKS DONE IN THE CALLER (merge_branch)
        -- Inserts (history)
	   INSERT INTO dbo.hist_Table
       SELECT
       
            [table_name],
        
        'master', @merge_version_id, @current_datetime, NULL, is_delete, CURRENT_USER
	   FROM dbo.hist_Table _hist
	   WHERE
		  branch_id = @branch_id
		  AND valid_to IS NULL
		  AND is_delete = 0
		  AND NOT EXISTS(select * from dbo.[Table] _curr where
          
            _curr.[table_name] = _hist.[table_name] AND
        
          _curr.branch_id = 'master')

       
          
	   -- Inserts (current)
	   INSERT INTO dbo.[Table]
	   SELECT
        
            _branch.[table_name],
        
        'master'
	   FROM dbo.[Table] _branch
	   INNER JOIN dbo.hist_Table _branch_hist
		  ON
            
                _branch_hist.[table_name] = _branch.[table_name] AND
            
			 _branch_hist.branch_id = @branch_id
			 AND valid_to IS NULL
	   WHERE _branch.branch_id = @branch_id
		  AND NOT EXISTS(select * from dbo.[Table] _curr where
          
                _curr.[table_name] = _branch.[table_name] AND
            
          _curr.branch_id = 'master')
		  
       
			 
	   -- Deletes (current)
	   DELETE _d
       FROM dbo.[Table] _d
       INNER JOIN 
        dbo.hist_Table _h on 
	    
            _d.[table_name] = _h.[table_name] AND
        
        _h.branch_id = @branch_id and _h.is_delete = 1 and _h.valid_to is null and _d.branch_id = 'master'

	   -- Fix previous master history
	   UPDATE h_master
		  SET valid_to = @current_datetime
	   FROM dbo.hist_Table h_master
	   INNER JOIN dbo.hist_Table h_branch ON
        
            h_master.[table_name] = h_branch.[table_name] AND
        
            h_master.branch_id = 'master'
            AND h_branch.branch_id = 'master'
            AND (h_master.version_id <> @merge_version_id OR h_master.version_id IS NULL)
            AND h_branch.version_id = @merge_version_id
            AND h_master.valid_to IS NULL

	   COMMIT TRANSACTION;
    END TRY 
    BEGIN CATCH
	   IF ERROR_NUMBER() <> 60000
		  ROLLBACK TRANSACTION;
	   THROW
    END CATCH
END

IF OBJECT_ID ('dbo.perform_merge_Column') IS NOT NULL 
     DROP PROCEDURE dbo.perform_merge_Column
GO
CREATE PROCEDURE dbo.perform_merge_Column
(@branch_id NVARCHAR(50), @merge_version_id NVARCHAR(50), @current_datetime datetime)
AS
BEGIN
    SET XACT_ABORT, NOCOUNT ON
    DECLARE @msg nvarchar(255)
    BEGIN TRY
	   BEGIN TRANSACTION
       -- SANITY CHECKS DONE IN THE CALLER (merge_branch)
        -- Inserts (history)
	   INSERT INTO dbo.hist_Column
       SELECT
       
            [column_name],
        
            [table_name],
        
            [datatype],
        
            [is_primary_key],
        
            [is_unique],
        
            [is_nullable],
        
        'master', @merge_version_id, @current_datetime, NULL, is_delete, CURRENT_USER
	   FROM dbo.hist_Column _hist
	   WHERE
		  branch_id = @branch_id
		  AND valid_to IS NULL
		  AND is_delete = 0
		  AND NOT EXISTS(select * from dbo.[Column] _curr where
          
            _curr.[column_name] = _hist.[column_name] AND
        
            _curr.[table_name] = _hist.[table_name] AND
        
          _curr.branch_id = 'master')

       
          
	   -- Inserts (current)
	   INSERT INTO dbo.[Column]
	   SELECT
        
            _branch.[column_name],
        
            _branch.[table_name],
        
            _branch.[datatype],
        
            _branch.[is_primary_key],
        
            _branch.[is_unique],
        
            _branch.[is_nullable],
        
        'master'
	   FROM dbo.[Column] _branch
	   INNER JOIN dbo.hist_Column _branch_hist
		  ON
            
                _branch_hist.[column_name] = _branch.[column_name] AND
            
                _branch_hist.[table_name] = _branch.[table_name] AND
            
			 _branch_hist.branch_id = @branch_id
			 AND valid_to IS NULL
	   WHERE _branch.branch_id = @branch_id
		  AND NOT EXISTS(select * from dbo.[Column] _curr where
          
                _curr.[column_name] = _branch.[column_name] AND
            
                _curr.[table_name] = _branch.[table_name] AND
            
          _curr.branch_id = 'master')
		  
       
			 
	   -- Deletes (current)
	   DELETE _d
       FROM dbo.[Column] _d
       INNER JOIN 
        dbo.hist_Column _h on 
	    
            _d.[column_name] = _h.[column_name] AND
        
            _d.[table_name] = _h.[table_name] AND
        
        _h.branch_id = @branch_id and _h.is_delete = 1 and _h.valid_to is null and _d.branch_id = 'master'

	   -- Fix previous master history
	   UPDATE h_master
		  SET valid_to = @current_datetime
	   FROM dbo.hist_Column h_master
	   INNER JOIN dbo.hist_Column h_branch ON
        
            h_master.[column_name] = h_branch.[column_name] AND
        
            h_master.[table_name] = h_branch.[table_name] AND
        
            h_master.branch_id = 'master'
            AND h_branch.branch_id = 'master'
            AND (h_master.version_id <> @merge_version_id OR h_master.version_id IS NULL)
            AND h_branch.version_id = @merge_version_id
            AND h_master.valid_to IS NULL

	   COMMIT TRANSACTION;
    END TRY 
    BEGIN CATCH
	   IF ERROR_NUMBER() <> 60000
		  ROLLBACK TRANSACTION;
	   THROW
    END CATCH
END

IF OBJECT_ID ('dbo.perform_merge_Reference') IS NOT NULL 
     DROP PROCEDURE dbo.perform_merge_Reference
GO
CREATE PROCEDURE dbo.perform_merge_Reference
(@branch_id NVARCHAR(50), @merge_version_id NVARCHAR(50), @current_datetime datetime)
AS
BEGIN
    SET XACT_ABORT, NOCOUNT ON
    DECLARE @msg nvarchar(255)
    BEGIN TRY
	   BEGIN TRANSACTION
       -- SANITY CHECKS DONE IN THE CALLER (merge_branch)
        -- Inserts (history)
	   INSERT INTO dbo.hist_Reference
       SELECT
       
            [reference_name],
        
            [src_table_name],
        
            [dest_table_name],
        
            [on_delete],
        
        'master', @merge_version_id, @current_datetime, NULL, is_delete, CURRENT_USER
	   FROM dbo.hist_Reference _hist
	   WHERE
		  branch_id = @branch_id
		  AND valid_to IS NULL
		  AND is_delete = 0
		  AND NOT EXISTS(select * from dbo.[Reference] _curr where
          
            _curr.[reference_name] = _hist.[reference_name] AND
        
          _curr.branch_id = 'master')

       
          
	   -- Inserts (current)
	   INSERT INTO dbo.[Reference]
	   SELECT
        
            _branch.[reference_name],
        
            _branch.[src_table_name],
        
            _branch.[dest_table_name],
        
            _branch.[on_delete],
        
        'master'
	   FROM dbo.[Reference] _branch
	   INNER JOIN dbo.hist_Reference _branch_hist
		  ON
            
                _branch_hist.[reference_name] = _branch.[reference_name] AND
            
			 _branch_hist.branch_id = @branch_id
			 AND valid_to IS NULL
	   WHERE _branch.branch_id = @branch_id
		  AND NOT EXISTS(select * from dbo.[Reference] _curr where
          
                _curr.[reference_name] = _branch.[reference_name] AND
            
          _curr.branch_id = 'master')
		  
       
			 
	   -- Deletes (current)
	   DELETE _d
       FROM dbo.[Reference] _d
       INNER JOIN 
        dbo.hist_Reference _h on 
	    
            _d.[reference_name] = _h.[reference_name] AND
        
        _h.branch_id = @branch_id and _h.is_delete = 1 and _h.valid_to is null and _d.branch_id = 'master'

	   -- Fix previous master history
	   UPDATE h_master
		  SET valid_to = @current_datetime
	   FROM dbo.hist_Reference h_master
	   INNER JOIN dbo.hist_Reference h_branch ON
        
            h_master.[reference_name] = h_branch.[reference_name] AND
        
            h_master.branch_id = 'master'
            AND h_branch.branch_id = 'master'
            AND (h_master.version_id <> @merge_version_id OR h_master.version_id IS NULL)
            AND h_branch.version_id = @merge_version_id
            AND h_master.valid_to IS NULL

	   COMMIT TRANSACTION;
    END TRY 
    BEGIN CATCH
	   IF ERROR_NUMBER() <> 60000
		  ROLLBACK TRANSACTION;
	   THROW
    END CATCH
END

IF OBJECT_ID ('dbo.perform_merge_ReferenceDetail') IS NOT NULL 
     DROP PROCEDURE dbo.perform_merge_ReferenceDetail
GO
CREATE PROCEDURE dbo.perform_merge_ReferenceDetail
(@branch_id NVARCHAR(50), @merge_version_id NVARCHAR(50), @current_datetime datetime)
AS
BEGIN
    SET XACT_ABORT, NOCOUNT ON
    DECLARE @msg nvarchar(255)
    BEGIN TRY
	   BEGIN TRANSACTION
       -- SANITY CHECKS DONE IN THE CALLER (merge_branch)
        -- Inserts (history)
	   INSERT INTO dbo.hist_ReferenceDetail
       SELECT
       
            [reference_name],
        
            [src_table_name],
        
            [src_column_name],
        
            [dest_table_name],
        
            [dest_column_name],
        
        'master', @merge_version_id, @current_datetime, NULL, is_delete, CURRENT_USER
	   FROM dbo.hist_ReferenceDetail _hist
	   WHERE
		  branch_id = @branch_id
		  AND valid_to IS NULL
		  AND is_delete = 0
		  AND NOT EXISTS(select * from dbo.[ReferenceDetail] _curr where
          
            _curr.[reference_name] = _hist.[reference_name] AND
        
            _curr.[src_column_name] = _hist.[src_column_name] AND
        
          _curr.branch_id = 'master')

       
          
	   -- Inserts (current)
	   INSERT INTO dbo.[ReferenceDetail]
	   SELECT
        
            _branch.[reference_name],
        
            _branch.[src_table_name],
        
            _branch.[src_column_name],
        
            _branch.[dest_table_name],
        
            _branch.[dest_column_name],
        
        'master'
	   FROM dbo.[ReferenceDetail] _branch
	   INNER JOIN dbo.hist_ReferenceDetail _branch_hist
		  ON
            
                _branch_hist.[reference_name] = _branch.[reference_name] AND
            
                _branch_hist.[src_column_name] = _branch.[src_column_name] AND
            
			 _branch_hist.branch_id = @branch_id
			 AND valid_to IS NULL
	   WHERE _branch.branch_id = @branch_id
		  AND NOT EXISTS(select * from dbo.[ReferenceDetail] _curr where
          
                _curr.[reference_name] = _branch.[reference_name] AND
            
                _curr.[src_column_name] = _branch.[src_column_name] AND
            
          _curr.branch_id = 'master')
		  
       
			 
	   -- Deletes (current)
	   DELETE _d
       FROM dbo.[ReferenceDetail] _d
       INNER JOIN 
        dbo.hist_ReferenceDetail _h on 
	    
            _d.[reference_name] = _h.[reference_name] AND
        
            _d.[src_column_name] = _h.[src_column_name] AND
        
        _h.branch_id = @branch_id and _h.is_delete = 1 and _h.valid_to is null and _d.branch_id = 'master'

	   -- Fix previous master history
	   UPDATE h_master
		  SET valid_to = @current_datetime
	   FROM dbo.hist_ReferenceDetail h_master
	   INNER JOIN dbo.hist_ReferenceDetail h_branch ON
        
            h_master.[reference_name] = h_branch.[reference_name] AND
        
            h_master.[src_column_name] = h_branch.[src_column_name] AND
        
            h_master.branch_id = 'master'
            AND h_branch.branch_id = 'master'
            AND (h_master.version_id <> @merge_version_id OR h_master.version_id IS NULL)
            AND h_branch.version_id = @merge_version_id
            AND h_master.valid_to IS NULL

	   COMMIT TRANSACTION;
    END TRY 
    BEGIN CATCH
	   IF ERROR_NUMBER() <> 60000
		  ROLLBACK TRANSACTION;
	   THROW
    END CATCH
END
