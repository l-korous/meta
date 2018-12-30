
    
use meta3
GO
IF OBJECT_ID ('dbo.delete_branch') IS NOT NULL 
     DROP PROCEDURE dbo.delete_branch
GO
CREATE PROCEDURE dbo.delete_branch
(@branch_id NVARCHAR(50))
AS
BEGIN
    SET XACT_ABORT, NOCOUNT ON
    DECLARE @msg nvarchar(255)
    BEGIN TRY
    BEGIN TRANSACTION
	   EXEC sp_MSforeachtable "ALTER TABLE ? NOCHECK CONSTRAINT all"

	   -- SANITY CHECKS
	   -- Branch exists
	   IF NOT EXISTS (select * from dbo.branch where branch_id = @branch_id)
		  BEGIN
			 set @msg = 'ERROR: Branch ' + @branch_id + ' does not exist';
			 THROW 50000, @msg, 1
		  END

	   
            DELETE FROM dbo.[Table]
                WHERE branch_id = @branch_id

            DELETE FROM dbo.hist_Table
            DELETE FROM dbo.[Column]
                WHERE branch_id = @branch_id

            DELETE FROM dbo.hist_Column
            DELETE FROM dbo.[Reference]
                WHERE branch_id = @branch_id

            DELETE FROM dbo.hist_Reference
            DELETE FROM dbo.[ReferenceDetail]
                WHERE branch_id = @branch_id

            DELETE FROM dbo.hist_ReferenceDetail

	   DELETE FROM dbo.[version]
	   WHERE branch_id = @branch_id

	   DELETE FROM dbo.[branch]
	   WHERE branch_id = @branch_id

	   exec sp_MSforeachtable "ALTER TABLE ? WITH CHECK CHECK CONSTRAINT all"
	   
	   COMMIT TRANSACTION;
	   
    END TRY
    BEGIN CATCH 
	   ROLLBACK TRANSACTION;
	   THROW
    END CATCH 
END