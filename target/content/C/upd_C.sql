use metaSimple2

IF OBJECT_ID ('dbo.upd_C') IS NOT NULL 
     DROP PROCEDURE dbo.upd_C
GO

CREATE PROCEDURE dbo.upd_C(@branch_id NVARCHAR(50), @_123 nvarchar(255), @_4 nvarchar(255))
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

	   IF EXISTS(SELECT _123 FROM dbo.C WHERE _123 = @_123 AND branch_id = @branch_id)
            BEGIN
			 -- EQUALITY CHECK
			 declare @_4_same bit = (select IIF(_4 = @_4,1,0) FROM dbo.C WHERE _123 = @_123 AND branch_id = @branch_id)

			 IF
				@_4_same = 1
				BEGIN
                    COMMIT TRANSACTION;
                    RETURN
                END

			 UPDATE dbo.C SET
				_4 = @_4
			 WHERE _123 = @_123
				AND branch_id = @branch_id

			 -- EXISTENCE of history record for this branch (always true for master)
			 IF @branch_id <> 'master' AND NOT EXISTS (SELECT 1 FROM dbo.hist_C WHERE _123 = @_123 AND branch_id = @branch_id)
				BEGIN
				    INSERT INTO dbo.hist_C
				    SELECT _123,
				    _4,
				    @branch_id, @current_version, valid_from, @current_datetime, is_delete, author
				    FROM dbo.hist_C WHERE _123 = @_123 AND branch_id = 'master' and valid_to is null
				END
			 ELSE
				BEGIN
				    UPDATE dbo.hist_C SET
					   valid_to = @current_datetime
				    WHERE _123 = @_123
					   AND branch_id = @branch_id
					   AND valid_to IS NULL
				END

			 INSERT INTO dbo.hist_C VALUES (
				@_123,
				@_4,
				@branch_id,
				@current_version,
				@current_datetime,
				NULL,
				0,
				CURRENT_USER
			 )
		  END
	   ELSE
		  BEGIN
			 set @msg = 'ERROR: C (_123: ' + CAST(@_123 AS NVARCHAR(MAX)) + ') does not exist';
			 THROW 50000, @msg, 1
		  END
	   COMMIT TRANSACTION;
    END TRY 
    BEGIN CATCH 
	   ROLLBACK TRANSACTION;
	   THROW
    END CATCH
END