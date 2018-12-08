use metaSimple2

IF OBJECT_ID ('dbo.ins_A') IS NOT NULL 
     DROP PROCEDURE dbo.ins_A
GO

CREATE PROCEDURE dbo.ins_A(@branch_id NVARCHAR(50), @id int,
@cA nvarchar(255),
@B_id int,
@this_is_my_column_name float
)
AS
BEGIN
    SET XACT_ABORT, NOCOUNT ON
    DECLARE @msg nvarchar(255)
    BEGIN TRY
    BEGIN TRANSACTION
	   -- SANITY CHECKS
	   -- Branch exists
	   IF NOT EXISTS (select * from dbo.branch where branch_id = @branch_id) BEGIN
		  set @msg = 'ERROR: Branch ' + @branch_id + ' does not exist';
		  THROW 50000, @msg, 1
	   END
	   -- Branch has a current version
	   IF NOT EXISTS (select * from dbo.branch _b inner join dbo.version _v on _b.branch_id = @branch_id and _v.version_id = _b.current_version_id) BEGIN
		  set @msg = 'ERROR: Branch ' + @branch_id + ' does not have a current version';
		  THROW 50000, @msg, 1
	   END
	   -- Branch's current version is open
	   IF (select _v.version_status from dbo.branch _b inner join dbo.version _v on _b.branch_id = @branch_id and _v.version_id = _b.current_version_id) <> 'open' BEGIN
		  set @msg = 'ERROR: Branch ' + @branch_id + ' has a current version, but it is not open';
		  THROW 50000, @msg, 1
	   END
		  
	   declare @current_datetime datetime = getdate()
	   declare @current_version nvarchar(50) = (SELECT current_version_id from [branch] where branch_id = @branch_id)

	   IF EXISTS(SELECT id FROM dbo.A WHERE id = @id AND branch_id = @branch_id) BEGIN
		  set @msg = 'ERROR: A (id: ' + CAST(@id AS NVARCHAR(MAX)) + ') already exists';
		  THROW 50000, @msg, 1
	   END
	   ELSE BEGIN
		  INSERT INTO dbo.A VALUES (
			 @id,
			 @cA,
			 @B_id,
			 @this_is_my_column_name,
			 @branch_id
		  )

		  -- This handles the case when the entry used to exist, and was deleted. So we finish the validity of the deletion.
		  UPDATE dbo.hist_A SET
				valid_to = @current_datetime
			 WHERE id = @id
				AND branch_id = @branch_id
				AND valid_to IS NULL
			 
		  INSERT INTO dbo.hist_A VALUES (
			 @id,
			 @cA,
			 @B_id,
			 @this_is_my_column_name,
			 @branch_id,
			 @current_version,
			 @current_datetime,
			 NULL,
			 0,
			 CURRENT_USER
		  )
	   END
	   COMMIT TRANSACTION;
    END TRY 
    BEGIN CATCH 
	   ROLLBACK TRANSACTION;
	   THROW
    END CATCH
END