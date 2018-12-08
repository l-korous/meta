
    
use meta3

IF OBJECT_ID ('dbo.close_version') IS NOT NULL 
     DROP PROCEDURE dbo.close_version
GO

CREATE PROCEDURE dbo.close_version
(@version_id NVARCHAR(50))
AS
BEGIN
    SET XACT_ABORT, NOCOUNT ON
    DECLARE @msg nvarchar(255)
    BEGIN TRY
    BEGIN TRANSACTION
	   -- SANITY CHECKS
	   -- Version exists
	   IF NOT EXISTS (select * from dbo.version where version_id = @version_id)
		  BEGIN
			 set @msg = 'ERROR: Version ' + @version_id + ' does not exist';
			 THROW 50000, @msg, 1
		  END
	   -- Version is not closed
	   IF (select version_status from dbo.version where version_id = @version_id) = 'closed'
		  BEGIN
			 set @msg = 'ERROR: Version ' + @version_id + ' already closed';
			 THROW 50000, @msg, 1
		  END

       -- Close the version of the branch
	   UPDATE dbo.version
	   SET version_status = 'closed'
	   WHERE version_id = @version_id
	   
	   UPDATE dbo.branch
	   SET last_closed_version_id = @version_id
	   WHERE branch_id = (select branch_id from dbo.version where version_id = @version_id)
	   
	   UPDATE dbo.branch
	   SET current_version_id = NULL
	   WHERE branch_id = (select branch_id from dbo.version where version_id = @version_id)

	   COMMIT TRANSACTION;
    END TRY 
    BEGIN CATCH 
	   ROLLBACK TRANSACTION;
	   THROW
    END CATCH 
END
