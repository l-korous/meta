use metaSimple2

IF OBJECT_ID ('dbo.perform_merge_A') IS NOT NULL 
     DROP PROCEDURE dbo.perform_merge_A
GO

CREATE PROCEDURE dbo.perform_merge_A
(@branch_id NVARCHAR(50), @merge_version_id NVARCHAR(50), @current_datetime datetime)
AS
BEGIN
    SET XACT_ABORT, NOCOUNT ON
    DECLARE @msg nvarchar(255)
    BEGIN TRY
	   BEGIN TRANSACTION
    	   -- SANITY CHECKS DONE IN THE CALLER (merge_branch)

	   -- Inserts (history)
	   INSERT INTO dbo.hist_A
	   SELECT id, cA, B_id, this_is_my_column_name, 'master', @merge_version_id, @current_datetime, NULL, is_delete, CURRENT_USER
	   FROM dbo.hist_A _h_A
	   WHERE
		  branch_id = @branch_id
		  AND valid_to IS NULL
		  AND is_delete = 0
		  AND NOT EXISTS(select * from dbo.A _A where _A.id = _h_A.id and _A.branch_id = 'master')

	   -- Updates (history)
	   INSERT INTO dbo.hist_A
	   SELECT id, cA, B_id, this_is_my_column_name, 'master', @merge_version_id, @current_datetime, NULL, is_delete, CURRENT_USER
	   FROM dbo.hist_A _h_A
	   WHERE
		  branch_id = @branch_id
		  AND valid_to IS NULL
		  AND is_delete = 0
		  AND EXISTS(select * from dbo.A _A where _A.id = _h_A.id and _A.branch_id = 'master')
		  AND (
			 (_h_A.cA <> (select cA from dbo.A _A where _A.id = _h_A.id and _A.branch_id = 'master'))
			 OR
			 (_h_A.B_id <> (select B_id from dbo.A _A where _A.id = _h_A.id and _A.branch_id = 'master'))
			 OR
			 (_h_A.this_is_my_column_name <> (select this_is_my_column_name from dbo.A _A where _A.id = _h_A.id and _A.branch_id = 'master'))
		  )

	   -- Deletes (history)
	   --INSERT INTO dbo.hist_A
	   --SELECT id, cA, B_id, this_is_my_column_name, 'master', @merge_version_id, @current_datetime, NULL, is_delete, CURRENT_USER
	   --FROM dbo.hist_A _h_A
	   --WHERE
		  --branch_id = @branch_id
		  --AND valid_to IS NULL
		  --AND is_delete = 1
		  --AND EXISTS(select * from dbo.A _A where _A.id = _h_A.id and _A.branch_id = 'master')
		  
	   -- Inserts (current)
	   INSERT INTO dbo.A
	   SELECT _branch_A.id, _branch_A.cA, _branch_A.B_id, _branch_A.this_is_my_column_name, 'master'
	   FROM dbo.A _branch_A
	   INNER JOIN dbo.hist_A _branch_hist_A
		  ON _branch_hist_A.id = _branch_A.id
			 AND _branch_hist_A.branch_id = @branch_id
			 AND valid_to IS NULL
	   WHERE _branch_A.branch_id = @branch_id
		  AND NOT EXISTS(select * from dbo.A _A where _A.id = _branch_A.id and _A.branch_id = 'master')
		  
	   -- Updates (current)
	   UPDATE _A
		  SET
			 _A.cA = _branch_A.cA,
			 _A.B_id = _branch_A.B_id,
			 _A.this_is_my_column_name = _branch_A.this_is_my_column_name
	   FROM dbo.A _A
	   INNER JOIN dbo.A _branch_A
		  ON _A.id = _branch_A.id
			 AND _A.branch_id = 'master'
			 AND _branch_A.branch_id = @branch_id
	   INNER JOIN dbo.hist_A _branch_hist_A
		  ON _branch_hist_A.id = _branch_A.id
			 AND _branch_hist_A.branch_id = @branch_id
			 AND valid_to IS NULL
			 AND (
				_branch_hist_A.cA <> _A.cA
				OR
				_branch_hist_A.B_id <> _A.B_id
				OR
				_branch_hist_A.this_is_my_column_name <> _A.this_is_my_column_name
			 )
			 
	   -- Deletes (current)
	   DELETE FROM dbo.A
	   WHERE branch_id = 'master' and id in (
		  SELECT id from dbo.hist_A where branch_id = @branch_id and is_delete = 1 and valid_to is null
	   )

	   -- Fix previous master history
	   UPDATE h_master
		  SET valid_to = @current_datetime
	   FROM dbo.hist_A h_master
	   INNER JOIN dbo.hist_A h_branch
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