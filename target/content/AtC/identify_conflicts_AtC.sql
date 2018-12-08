use metaSimple2

IF OBJECT_ID ('dbo.identify_conflicts_AtC') IS NOT NULL 
     DROP PROCEDURE dbo.identify_conflicts_AtC
GO

CREATE PROCEDURE dbo.identify_conflicts_AtC
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
		  FROM dbo.hist_AtC h_master
			 INNER JOIN dbo.hist_AtC h_branch ON
				h_master.A_sru = h_branch.A_sru
				AND h_master.Cid = h_branch.Cid
				AND h_master.branch_id = 'master'
				AND h_branch.branch_id = @branch_id
				AND h_master.version_id in (SELECT version_id from dbo.[version] where version_order > @min_version_order_master)
				AND h_master.valid_to IS NULL
				AND h_branch.valid_to IS NULL
				AND (
					   0 = 1
				)

	   )
	   IF @number_of_conflicts > 0 BEGIN
		  INSERT INTO dbo.conflicts_AtC
		  SELECT @merge_version_id, h_master.A_sru, h_master.Cid, h_master.is_delete, h_branch.is_delete, h_master.author, h_master.version_id, h_master.valid_from
		  FROM
			 dbo.hist_AtC h_master
			 INNER JOIN dbo.hist_AtC h_branch
				ON  h_master.A_sru = h_branch.A_sru
				    AND h_master.Cid = h_branch.Cid
				    AND h_master.branch_id = 'master'
				    AND h_branch.branch_id = @branch_id
				    AND h_master.version_id in (SELECT version_id from dbo.[version] where version_order > @min_version_order_master)
				    AND h_master.valid_to IS NULL
				    AND h_branch.valid_to IS NULL
				    AND (
					   0 = 1
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