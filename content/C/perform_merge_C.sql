use metaSimple2

IF OBJECT_ID ('dbo.perform_merge_C') IS NOT NULL 
     DROP PROCEDURE dbo.perform_merge_C
GO

CREATE PROCEDURE dbo.perform_merge_C
(@branch_id NVARCHAR(50), @merge_version_id NVARCHAR(50), @current_datetime datetime)
AS
BEGIN
    SET XACT_ABORT, NOCOUNT ON
    DECLARE @msg nvarchar(255)
    BEGIN TRY
	   BEGIN TRANSACTION
    	   -- SANITY CHECKS DONE IN THE CALLER (merge_branch)

	   -- Inserts (history)
	   INSERT INTO dbo.hist_C
	   SELECT [_123], [_4], 'master', @merge_version_id, @current_datetime, NULL, is_delete, CURRENT_USER
	   FROM dbo.hist_C _h_C
	   WHERE
		  branch_id = @branch_id
		  AND valid_to IS NULL
		  AND is_delete = 0
		  AND NOT EXISTS(select * from dbo.C _C where _C.[_123] = _h_C.[_123] and _C.branch_id = 'master')

	   -- Updates (history)
	   INSERT INTO dbo.hist_C
	   SELECT [_123], [_4], 'master', @merge_version_id, @current_datetime, NULL, is_delete, CURRENT_USER
	   FROM dbo.hist_C _h_C
	   WHERE
		  branch_id = @branch_id
		  AND valid_to IS NULL
		  AND is_delete = 0
		  AND EXISTS(select * from dbo.C _C where _C.[_123] = _h_C.[_123] and _C.branch_id = 'master')
		  AND (
			 (_h_C.[_4] <> (select [_4] from dbo.C _C where _C.[_123] = _h_C.[_123] and _C.branch_id = 'master'))
		  )

	   -- Deletes (history)
	   INSERT INTO dbo.hist_C
	   SELECT [_123], [_4], 'master', @merge_version_id, @current_datetime, NULL, is_delete, CURRENT_USER
	   FROM dbo.hist_C _h_C
	   WHERE
		  branch_id = @branch_id
		  AND valid_to IS NULL
		  AND is_delete = 1
		  AND EXISTS(select * from dbo.C _C where _C.[_123] = _h_C.[_123] and _C.branch_id = 'master')
		  
	   -- Inserts (current)
	   INSERT INTO dbo.C
	   SELECT _branch_C.[_123], _branch_C.[_4], 'master'
	   FROM dbo.C _branch_C
	   INNER JOIN dbo.hist_C _branch_hist_C
		  ON _branch_hist_C.[_123] = _branch_C.[_123]
			 AND _branch_hist_C.branch_id = @branch_id
			 AND valid_to IS NULL
	   WHERE _branch_C.branch_id = @branch_id
		  AND NOT EXISTS(select * from dbo.C _C where _C.[_123] = _branch_C.[_123] and _C.branch_id = 'master')
		  
	   -- Updates (current)
	   UPDATE _C
		  SET
			 _C.[_4] = _branch_C.[_4]
	   FROM dbo.C _C
	   INNER JOIN dbo.C _branch_C
		  ON _C.[_123] = _branch_C.[_123]
			 AND _C.branch_id = 'master'
			 AND _branch_C.branch_id = @branch_id
	   INNER JOIN dbo.hist_C _branch_hist_C
		  ON _branch_hist_C.[_123] = _branch_C.[_123]
			 AND _branch_hist_C.branch_id = @branch_id
			 AND valid_to IS NULL
			 AND (
				_branch_hist_C.[_4] <> _C.[_4]
			 )
			 
	   -- Deletes (current)
	   DELETE FROM dbo.C
	   WHERE branch_id = 'master' and [_123] in (
		  SELECT [_123] from dbo.hist_C where branch_id = 'master' and version_id = @merge_version_id and is_delete = 1 and valid_to is null
	   )

	   -- Fix previous master history
	   UPDATE h_master
		  SET valid_to = @current_datetime
	   FROM dbo.hist_C h_master
	   INNER JOIN dbo.hist_C h_branch
		  on h_master.[_123] = h_branch.[_123]
				    AND h_master.branch_id = 'master'
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