use metaSimple2

IF OBJECT_ID ('dbo.perform_merge_B') IS NOT NULL 
     DROP PROCEDURE dbo.perform_merge_B
GO

CREATE PROCEDURE dbo.perform_merge_B
(@branch_id NVARCHAR(50), @merge_version_id NVARCHAR(50), @current_datetime datetime)
AS
BEGIN
    SET XACT_ABORT, NOCOUNT ON
    DECLARE @msg nvarchar(255)
    BEGIN TRY
	   BEGIN TRANSACTION
    	   -- SANITY CHECKS DONE IN THE CALLER (merge_branch)

	   -- Inserts (history)
	   INSERT INTO dbo.hist_B
	   SELECT id, [select], 'master', @merge_version_id, @current_datetime, NULL, is_delete, CURRENT_USER
	   FROM dbo.hist_B _h_B
	   WHERE
		  branch_id = @branch_id
		  AND valid_to IS NULL
		  AND is_delete = 0
		  AND NOT EXISTS(select * from dbo.B _B where _B.id = _h_B.id and _B.branch_id = 'master')

	   -- Updates (history)
	   INSERT INTO dbo.hist_B
	   SELECT id, [select], 'master', @merge_version_id, @current_datetime, NULL, is_delete, CURRENT_USER
	   FROM dbo.hist_B _h_B
	   WHERE
		  branch_id = @branch_id
		  AND valid_to IS NULL
		  AND is_delete = 0
		  AND EXISTS(select * from dbo.B _B where _B.id = _h_B.id and _B.branch_id = 'master')
		  AND (
			 (_h_B.[select] <> (select [select] from dbo.B _B where _B.id = _h_B.id and _B.branch_id = 'master'))
		  )

	   -- Deletes (history)
	   INSERT INTO dbo.hist_B
	   SELECT id, [select], 'master', @merge_version_id, @current_datetime, NULL, is_delete, CURRENT_USER
	   FROM dbo.hist_B _h_B
	   WHERE
		  branch_id = @branch_id
		  AND valid_to IS NULL
		  AND is_delete = 1
		  AND EXISTS(select * from dbo.B _B where _B.id = _h_B.id and _B.branch_id = 'master')
		  
	   -- Inserts (current)
	   INSERT INTO dbo.B
	   SELECT _branch_B.id, _branch_B.[select], 'master'
	   FROM dbo.B _branch_B
	   INNER JOIN dbo.hist_B _branch_hist_B
		  ON _branch_hist_B.id = _branch_B.id
			 AND _branch_hist_B.branch_id = @branch_id
			 AND valid_to IS NULL
	   WHERE _branch_B.branch_id = @branch_id
		  AND NOT EXISTS(select * from dbo.B _B where _B.id = _branch_B.id and _B.branch_id = 'master')
		  
	   -- Updates (current)
	   UPDATE _B
		  SET
			 _B.[select] = _branch_B.[select]
	   FROM dbo.B _B
	   INNER JOIN dbo.B _branch_B
		  ON _B.id = _branch_B.id
			 AND _B.branch_id = 'master'
			 AND _branch_B.branch_id = @branch_id
	   INNER JOIN dbo.hist_B _branch_hist_B
		  ON _branch_hist_B.id = _branch_B.id
			 AND _branch_hist_B.branch_id = @branch_id
			 AND valid_to IS NULL
			 AND (
				_branch_hist_B.[select] <> _B.[select]
			 )
			 
	   -- Deletes (current)
	   DELETE FROM dbo.B
	   WHERE branch_id = 'master' and id in (
		  SELECT id from dbo.hist_B where branch_id = 'master' and version_id = @merge_version_id and is_delete = 1 and valid_to is null
	   )

	   -- Fix previous master history
	   UPDATE h_master
		  SET valid_to = @current_datetime
	   FROM dbo.hist_B h_master
	   INNER JOIN dbo.hist_B h_branch
		  on h_master.id = h_branch.id
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