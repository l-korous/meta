use metaSimple2

IF OBJECT_ID ('dbo.upd_AtC') IS NOT NULL 
     DROP PROCEDURE dbo.upd_AtC
GO

CREATE PROCEDURE dbo.upd_AtC(@branch_id NVARCHAR(50),
@A_sru int,
@Cid int
)
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
	   -- Branch has a current version
	   IF NOT EXISTS (select * from dbo.branch _b inner join dbo.version _v on _b.branch_id = @branch_id and _v.version_id = _b.current_version_id)
		  BEGIN
			 set @msg = 'ERROR: Branch ' + @branch_id + ' does not have a current version';
			 THROW 50000, @msg, 1
		  END
	   -- Branch's current version is open
	   IF (select _v.version_status from dbo.branch _b inner join dbo.version _v on _b.branch_id = @branch_id and _v.version_id = _b.current_version_id) <> 'open'
		  BEGIN
			 set @msg = 'ERROR: Branch ' + @branch_id + ' has a current version, but it is not open';
			 THROW 50000, @msg, 1
		  END
		  
	   declare @current_datetime datetime = getdate()
	   declare @current_version nvarchar(50) = (SELECT current_version_id from [branch] where branch_id = @branch_id)

	   IF EXISTS(SELECT * FROM dbo.AtC WHERE A_sru = @A_sru AND Cid = @Cid AND branch_id = @branch_id)
            BEGIN
                COMMIT TRANSACTION;
                RETURN
            END
	   ELSE
		  BEGIN
			 set @msg = 'ERROR: AtC (A_sru: ' + CAST(@A_sru AS NVARCHAR(MAX)) + ', Cid: ' + CAST(@Cid AS NVARCHAR(MAX)) + ') does not exist';
			 THROW 50000, @msg, 1
		  END
	   COMMIT TRANSACTION;
    END TRY 
    BEGIN CATCH 
	   ROLLBACK TRANSACTION;
	   THROW
    END CATCH
END