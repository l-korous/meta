
    
use meta3
GO

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
       
            [name],
        
            [table_name],
        
            [is_primary_key],
        
            [is_unique],
        
            [datatype],
        
            [is_nullable],
        
        'master', @merge_version_id, @current_datetime, NULL, is_delete, CURRENT_USER
	   FROM dbo.hist_Column _hist
	   WHERE
		  branch_id = @branch_id
		  AND valid_to IS NULL
		  AND is_delete = 0
		  AND NOT EXISTS(select * from dbo.[Column] _curr where
          
            _curr.[name] = _hist.[name] AND
        
            _curr.[table_name] = _hist.[table_name] AND
        
          _curr.branch_id = 'master')

       
	   -- Updates (history)
	   INSERT INTO dbo.hist_Column
	   SELECT
       
            [name],
        
            [table_name],
        
            [is_primary_key],
        
            [is_unique],
        
            [datatype],
        
            [is_nullable],
        
       'master', @merge_version_id, @current_datetime, NULL, is_delete, CURRENT_USER
	   FROM dbo.hist_Column _hist
	   WHERE
		  branch_id = @branch_id
		  AND valid_to IS NULL
		  AND is_delete = 0
		  AND EXISTS(select * from dbo.[Column] _curr where
          
            _curr.[name] = _hist.[name] AND
        
            _curr.[table_name] = _hist.[table_name] AND
        
          _curr.branch_id = 'master')
		  AND (
              
                   (_hist.[is_primary_key] <> (select [is_primary_key] from dbo.[Column] _curr where 
                   _curr.branch_id = 'master'))
                    OR 
                   (_hist.[is_unique] <> (select [is_unique] from dbo.[Column] _curr where 
                   _curr.branch_id = 'master'))
                    OR 
                   (_hist.[datatype] <> (select [datatype] from dbo.[Column] _curr where 
                   _curr.branch_id = 'master'))
                    OR 
                   (_hist.[is_nullable] <> (select [is_nullable] from dbo.[Column] _curr where 
                   _curr.branch_id = 'master'))
                   
		  )
      
          
	   -- Inserts (current)
	   INSERT INTO dbo.[Column]
	   SELECT
        
            _branch.[name],
        
            _branch.[table_name],
        
            _branch.[is_primary_key],
        
            _branch.[is_unique],
        
            _branch.[datatype],
        
            _branch.[is_nullable],
        
        'master'
	   FROM dbo.[Column] _branch
	   INNER JOIN dbo.hist_Column _branch_hist
		  ON
            
                _branch_hist.[name] = _branch.[name] AND
            
                _branch_hist.[table_name] = _branch.[table_name] AND
            
			 _branch_hist.branch_id = @branch_id
			 AND valid_to IS NULL
	   WHERE _branch.branch_id = @branch_id
		  AND NOT EXISTS(select * from dbo.[Column] _curr where
          
                _curr.[name] = _branch.[name] AND
            
                _curr.[table_name] = _branch.[table_name] AND
            
          _curr.branch_id = 'master')
		  
       
	   -- Updates (current)
	   UPDATE _curr
		  SET
            
                _curr.[is_primary_key] = _branch.[is_primary_key]
                ,
                _curr.[is_unique] = _branch.[is_unique]
                ,
                _curr.[datatype] = _branch.[datatype]
                ,
                _curr.[is_nullable] = _branch.[is_nullable]
                
	   FROM dbo.[Column] _curr
	   INNER JOIN dbo.[Column] _branch
		  ON
          
                _curr.[name] = _branch.[name] AND
            
                _curr.[table_name] = _branch.[table_name] AND
            
            _curr.branch_id = 'master'
			 AND _branch.branch_id = @branch_id
	   INNER JOIN dbo.hist_Column _branch_hist
		  ON
            
                _branch_hist.[name] = _branch.[name] AND
            
                _branch_hist.[table_name] = _branch.[table_name] AND
            
            _branch_hist.branch_id = @branch_id
			 AND valid_to IS NULL
			 AND (
                
                    _branch_hist.[is_primary_key] <> _curr.[is_primary_key]
                     OR 
                    _branch_hist.[is_unique] <> _curr.[is_unique]
                     OR 
                    _branch_hist.[datatype] <> _curr.[datatype]
                     OR 
                    _branch_hist.[is_nullable] <> _curr.[is_nullable]
                    
			 )
         
			 
	   -- Deletes (current)
	   DELETE _d
       FROM dbo.[Column] _d
       INNER JOIN 
        dbo.hist_Column _h on 
	    
            _d.[name] = _h.[name] AND
        
            _d.[table_name] = _h.[table_name] AND
        
        _h.branch_id = @branch_id and _h.is_delete = 1 and _h.valid_to is null and _d.branch_id = 'master'

	   -- Fix previous master history
	   UPDATE h_master
		  SET valid_to = @current_datetime
	   FROM dbo.hist_Column h_master
	   INNER JOIN dbo.hist_Column h_branch ON
        
            h_master.[name] = h_branch.[name] AND
        
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
       
            [name],
        
            [src_table],
        
            [src_column],
        
            [dest_table],
        
            [dest_column],
        
            [on_delete],
        
        'master', @merge_version_id, @current_datetime, NULL, is_delete, CURRENT_USER
	   FROM dbo.hist_Reference _hist
	   WHERE
		  branch_id = @branch_id
		  AND valid_to IS NULL
		  AND is_delete = 0
		  AND NOT EXISTS(select * from dbo.[Reference] _curr where
          
            _curr.[name] = _hist.[name] AND
        
          _curr.branch_id = 'master')

       
	   -- Updates (history)
	   INSERT INTO dbo.hist_Reference
	   SELECT
       
            [name],
        
            [src_table],
        
            [src_column],
        
            [dest_table],
        
            [dest_column],
        
            [on_delete],
        
       'master', @merge_version_id, @current_datetime, NULL, is_delete, CURRENT_USER
	   FROM dbo.hist_Reference _hist
	   WHERE
		  branch_id = @branch_id
		  AND valid_to IS NULL
		  AND is_delete = 0
		  AND EXISTS(select * from dbo.[Reference] _curr where
          
            _curr.[name] = _hist.[name] AND
        
          _curr.branch_id = 'master')
		  AND (
              
                   (_hist.[src_table] <> (select [src_table] from dbo.[Reference] _curr where 
                   _curr.branch_id = 'master'))
                    OR 
                   (_hist.[src_column] <> (select [src_column] from dbo.[Reference] _curr where 
                   _curr.branch_id = 'master'))
                    OR 
                   (_hist.[dest_table] <> (select [dest_table] from dbo.[Reference] _curr where 
                   _curr.branch_id = 'master'))
                    OR 
                   (_hist.[dest_column] <> (select [dest_column] from dbo.[Reference] _curr where 
                   _curr.branch_id = 'master'))
                    OR 
                   (_hist.[on_delete] <> (select [on_delete] from dbo.[Reference] _curr where 
                   _curr.branch_id = 'master'))
                   
		  )
      
          
	   -- Inserts (current)
	   INSERT INTO dbo.[Reference]
	   SELECT
        
            _branch.[name],
        
            _branch.[src_table],
        
            _branch.[src_column],
        
            _branch.[dest_table],
        
            _branch.[dest_column],
        
            _branch.[on_delete],
        
        'master'
	   FROM dbo.[Reference] _branch
	   INNER JOIN dbo.hist_Reference _branch_hist
		  ON
            
                _branch_hist.[name] = _branch.[name] AND
            
			 _branch_hist.branch_id = @branch_id
			 AND valid_to IS NULL
	   WHERE _branch.branch_id = @branch_id
		  AND NOT EXISTS(select * from dbo.[Reference] _curr where
          
                _curr.[name] = _branch.[name] AND
            
          _curr.branch_id = 'master')
		  
       
	   -- Updates (current)
	   UPDATE _curr
		  SET
            
                _curr.[src_table] = _branch.[src_table]
                ,
                _curr.[src_column] = _branch.[src_column]
                ,
                _curr.[dest_table] = _branch.[dest_table]
                ,
                _curr.[dest_column] = _branch.[dest_column]
                ,
                _curr.[on_delete] = _branch.[on_delete]
                
	   FROM dbo.[Reference] _curr
	   INNER JOIN dbo.[Reference] _branch
		  ON
          
                _curr.[name] = _branch.[name] AND
            
            _curr.branch_id = 'master'
			 AND _branch.branch_id = @branch_id
	   INNER JOIN dbo.hist_Reference _branch_hist
		  ON
            
                _branch_hist.[name] = _branch.[name] AND
            
            _branch_hist.branch_id = @branch_id
			 AND valid_to IS NULL
			 AND (
                
                    _branch_hist.[src_table] <> _curr.[src_table]
                     OR 
                    _branch_hist.[src_column] <> _curr.[src_column]
                     OR 
                    _branch_hist.[dest_table] <> _curr.[dest_table]
                     OR 
                    _branch_hist.[dest_column] <> _curr.[dest_column]
                     OR 
                    _branch_hist.[on_delete] <> _curr.[on_delete]
                    
			 )
         
			 
	   -- Deletes (current)
	   DELETE _d
       FROM dbo.[Reference] _d
       INNER JOIN 
        dbo.hist_Reference _h on 
	    
            _d.[name] = _h.[name] AND
        
        _h.branch_id = @branch_id and _h.is_delete = 1 and _h.valid_to is null and _d.branch_id = 'master'

	   -- Fix previous master history
	   UPDATE h_master
		  SET valid_to = @current_datetime
	   FROM dbo.hist_Reference h_master
	   INNER JOIN dbo.hist_Reference h_branch ON
        
            h_master.[name] = h_branch.[name] AND
        
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
       
            [name],
        
        'master', @merge_version_id, @current_datetime, NULL, is_delete, CURRENT_USER
	   FROM dbo.hist_Table _hist
	   WHERE
		  branch_id = @branch_id
		  AND valid_to IS NULL
		  AND is_delete = 0
		  AND NOT EXISTS(select * from dbo.[Table] _curr where
          
            _curr.[name] = _hist.[name] AND
        
          _curr.branch_id = 'master')

       
          
	   -- Inserts (current)
	   INSERT INTO dbo.[Table]
	   SELECT
        
            _branch.[name],
        
        'master'
	   FROM dbo.[Table] _branch
	   INNER JOIN dbo.hist_Table _branch_hist
		  ON
            
                _branch_hist.[name] = _branch.[name] AND
            
			 _branch_hist.branch_id = @branch_id
			 AND valid_to IS NULL
	   WHERE _branch.branch_id = @branch_id
		  AND NOT EXISTS(select * from dbo.[Table] _curr where
          
                _curr.[name] = _branch.[name] AND
            
          _curr.branch_id = 'master')
		  
       
			 
	   -- Deletes (current)
	   DELETE _d
       FROM dbo.[Table] _d
       INNER JOIN 
        dbo.hist_Table _h on 
	    
            _d.[name] = _h.[name] AND
        
        _h.branch_id = @branch_id and _h.is_delete = 1 and _h.valid_to is null and _d.branch_id = 'master'

	   -- Fix previous master history
	   UPDATE h_master
		  SET valid_to = @current_datetime
	   FROM dbo.hist_Table h_master
	   INNER JOIN dbo.hist_Table h_branch ON
        
            h_master.[name] = h_branch.[name] AND
        
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
