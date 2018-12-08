
    
use meta3

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

	   
            DELETE FROM dbo.A
                WHERE branch_id = @branch_id

            DELETE FROM dbo.hist_A
            DELETE FROM dbo.AtC
                WHERE branch_id = @branch_id

            DELETE FROM dbo.hist_AtC
            DELETE FROM dbo.B
                WHERE branch_id = @branch_id

            DELETE FROM dbo.hist_B
            DELETE FROM dbo.C
                WHERE branch_id = @branch_id

            DELETE FROM dbo.hist_C

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
