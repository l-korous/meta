use metaSimple2

IF OBJECT_ID ('dbo.create_version') IS NOT NULL 
     DROP PROCEDURE dbo.create_version
GO

CREATE PROCEDURE dbo.create_version
(@branch_id NVARCHAR(50), @version_id NVARCHAR(50))
AS
BEGIN
    SET XACT_ABORT, NOCOUNT ON
    DECLARE @msg nvarchar(255)
    BEGIN TRY
    BEGIN TRANSACTION
	   -- SANITY CHECKS
	   -- Branch exists
	   IF NOT EXISTS (select * from dbo.branch where branch_id = @branch_id)
		  BEGIN
			 set @msg = 'ERROR: Branch ' + @branch_id + ' does not exist';
			 THROW 50000, @msg, 1
		  END
	   -- Version does not exist
	   IF EXISTS (select * from dbo.version where version_id = @version_id)
		  BEGIN
			 set @msg = 'ERROR: Version ' + @version_id + ' already exists on branch: ' + (select branch_id from dbo.version where version_id = @version_id);
			 THROW 50000, @msg, 1
		  END
	   -- There is no open version
	   IF (SELECT current_version_id from dbo.branch where branch_id = @branch_id) IS NOT NULL
		  BEGIN
			 set @msg = 'ERROR: Branch has an open version ' + (SELECT current_version_id from dbo.branch where branch_id = @branch_id) + ', close that first';
			 THROW 50000, @msg, 1
		  END

	   declare @max_version_order_plus_one int = (SELECT MAX(version_order) from dbo.version) + 1
	   declare @previous_version_id NVARCHAR(50) = (select last_closed_version_id from dbo.branch where branch_id = @branch_id)
	   insert into dbo.version values (@version_id, @branch_id, @previous_version_id, @max_version_order_plus_one, 'open')
	   update branch set current_version_id = @version_id where branch_id = @branch_id

	   COMMIT TRANSACTION;
    END TRY 
    BEGIN CATCH 
	   ROLLBACK TRANSACTION;
	   THROW
    END CATCH 
END