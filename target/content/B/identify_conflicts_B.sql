use metaSimple2

IF OBJECT_ID ('dbo.identify_conflicts_B') IS NOT NULL 
     DROP PROCEDURE dbo.identify_conflicts_B
GO

CREATE PROCEDURE dbo.identify_conflicts_B
(@branch_id NVARCHAR(50), @merge_version_id NVARCHAR(50), @min_version_order_master int, @number_of_conflicts int output)
AS
BEGIN
    SET XACT_ABORT, NOCOUNT ON
    DECLARE @msg nvarchar(255)
    BEGIN TRY
	   BEGIN TRANSACTION
    	   -- SANITY CHECKS DONE IN THE CALLER (merge_branch)
	   
	   set @number_of_conflicts = (
		  SELECT COUNT(*)
		  FROM dbo.hist_B h_master
			 INNER JOIN dbo.hist_B h_branch ON
				h_master.id = h_branch.id
				AND h_master.branch_id = 'master'
				AND h_branch.branch_id = @branch_id
				AND h_master.version_id in (SELECT version_id from dbo.[version] where version_order > @min_version_order_master)
				AND h_master.valid_to IS NULL
				AND h_branch.valid_to IS NULL
				AND (
					   (
						  (h_master.[select] IS NULL AND h_branch.[select] IS NOT NULL)
						  OR
						  (h_master.[select] IS NOT NULL AND h_branch.[select] IS NULL)
						  OR
						  (h_master.[select] <> h_branch.[select])
					   )
				    )

	   )
	   IF @number_of_conflicts > 0 BEGIN
		  INSERT INTO dbo.conflicts_B
		  SELECT @merge_version_id, h_master.id, h_master.is_delete, h_branch.is_delete, h_master.[select], h_branch.[select], h_master.author, h_master.version_id, h_master.valid_from
		  FROM
			 dbo.hist_B h_master
			 INNER JOIN dbo.hist_B h_branch
				ON h_master.id = h_branch.id
				    AND h_master.branch_id = 'master'
				    AND h_branch.branch_id = @branch_id
				    AND h_master.version_id in (SELECT version_id from dbo.[version] where version_order > @min_version_order_master)
				    AND h_master.valid_to IS NULL
				    AND h_branch.valid_to IS NULL
				    AND (
					   (
						  (h_master.[select] IS NULL AND h_branch.[select] IS NOT NULL)
						  OR
						  (h_master.[select] IS NOT NULL AND h_branch.[select] IS NULL)
						  OR
						  (h_master.[select] <> h_branch.[select])
					   )
				    )
	   END
	   COMMIT TRANSACTION;
    END TRY 
    BEGIN CATCH
	   IF ERROR_NUMBER() <> 60000
		  ROLLBACK TRANSACTION;
	   THROW
    END CATCH
END