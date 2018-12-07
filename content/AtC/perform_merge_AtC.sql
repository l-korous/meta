use metaSimple2

IF OBJECT_ID ('dbo.perform_merge_AtC') IS NOT NULL 
     DROP PROCEDURE dbo.perform_merge_AtC
GO

CREATE PROCEDURE dbo.perform_merge_AtC
(@branch_id NVARCHAR(50), @merge_version_id NVARCHAR(50), @current_datetime datetime)
AS
BEGIN
    SET XACT_ABORT, NOCOUNT ON
    DECLARE @msg nvarchar(255)
    BEGIN TRY
	   BEGIN TRANSACTION
    	   -- SANITY CHECKS DONE IN THE CALLER (merge_branch)

	   -- Inserts (history)
	   INSERT INTO dbo.hist_AtC
	   SELECT A_sru, [Cid], 'master', @merge_version_id, @current_datetime, NULL, is_delete, CURRENT_USER
	   FROM dbo.hist_AtC _h_AtC
	   WHERE
		  branch_id = @branch_id
		  AND valid_to IS NULL
		  AND is_delete = 0
		  AND NOT EXISTS(select * from dbo.AtC _AtC where _AtC.[A_sru] = _h_AtC.[A_sru] and _AtC.branch_id = 'master')

	   -- Updates (history)
	   INSERT INTO dbo.hist_AtC
	   SELECT A_sru, [Cid], 'master', @merge_version_id, @current_datetime, NULL, is_delete, CURRENT_USER
	   FROM dbo.hist_AtC _h_AtC
	   WHERE
		  branch_id = @branch_id
		  AND valid_to IS NULL
		  AND is_delete = 0
		  AND EXISTS(select * from dbo.AtC _AtC where _AtC.[A_sru] = _h_AtC.[A_sru] and _AtC.branch_id = 'master')
		  AND (
			 (_h_AtC.[Cid] <> (select [Cid] from dbo.AtC _AtC where _AtC.[A_sru] = _h_AtC.[A_sru] and _AtC.branch_id = 'master'))
		  )

	   -- Deletes (history)
	   INSERT INTO dbo.hist_AtC
	   SELECT A_sru, [Cid], 'master', @merge_version_id, @current_datetime, NULL, is_delete, CURRENT_USER
	   FROM dbo.hist_AtC _h_AtC
	   WHERE
		  branch_id = @branch_id
		  AND valid_to IS NULL
		  AND is_delete = 1
		  AND EXISTS(select * from dbo.AtC _AtC where _AtC.[A_sru] = _h_AtC.[A_sru] and _AtC.branch_id = 'master')
		  
	   -- Inserts (current)
	   INSERT INTO dbo.AtC
	   SELECT _branch_AtC.[A_sru], _branch_AtC.[Cid], 'master'
	   FROM dbo.AtC _branch_AtC
	   INNER JOIN dbo.hist_AtC _branch_hist_AtC
		  ON _branch_hist_AtC.[A_sru] = _branch_AtC.[A_sru]
			 AND _branch_hist_AtC.branch_id = @branch_id
			 AND valid_to IS NULL
	   WHERE _branch_AtC.branch_id = @branch_id
		  AND NOT EXISTS(select * from dbo.AtC _AtC where _AtC.[A_sru] = _branch_AtC.[A_sru] and _AtC.branch_id = 'master')
		  
	   -- Updates (current)
	   UPDATE _AtC
		  SET
			 _AtC.[Cid] = _branch_AtC.[Cid]
	   FROM dbo.AtC _AtC
	   INNER JOIN dbo.AtC _branch_AtC
		  ON _AtC.[A_sru] = _branch_AtC.[A_sru]
			 AND _AtC.branch_id = 'master'
			 AND _branch_AtC.branch_id = @branch_id
	   INNER JOIN dbo.hist_AtC _branch_hist_AtC
		  ON _branch_hist_AtC.[A_sru] = _branch_AtC.[A_sru]
			 AND _branch_hist_AtC.branch_id = @branch_id
			 AND valid_to IS NULL
			 AND (
				_branch_hist_AtC.[Cid] <> _AtC.[Cid]
			 )
			 
	   -- Deletes (current)
	   DELETE FROM dbo.AtC
	   WHERE branch_id = 'master' and A_sru in (
		  SELECT A_sru from dbo.hist_AtC where branch_id = 'master' and version_id = @merge_version_id and is_delete = 1 and valid_to is null
	   )

	   -- Fix previous master history
	   UPDATE h_master
		  SET valid_to = @current_datetime
	   FROM dbo.hist_AtC h_master
	   INNER JOIN dbo.hist_AtC h_branch
		  on h_master.[A_sru] = h_branch.[A_sru]
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