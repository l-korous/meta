use metaSimple2

IF OBJECT_ID ('dbo.upd_B') IS NOT NULL 
     DROP PROCEDURE dbo.upd_B
GO

CREATE PROCEDURE dbo.upd_B(@branch_id NVARCHAR(50), @id int, @select nvarchar(255))
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

	   IF EXISTS(SELECT id FROM dbo.B WHERE id = @id AND branch_id = @branch_id)
		  BEGIN
			 -- EQUALITY CHECK
			 declare @select_same bit = (select IIF([select] = @select,1,0) FROM dbo.B WHERE id = @id AND branch_id = @branch_id)

			 IF	@select_same = 1
				BEGIN
                    COMMIT TRANSACTION;
                    RETURN
                END

			 UPDATE dbo.B SET
				[select] = @select
			 WHERE id = @id
				AND branch_id = @branch_id

			 -- EXISTENCE of history record for this branch (always true for master)
			 IF @branch_id <> 'master' AND NOT EXISTS (SELECT 1 FROM dbo.hist_B WHERE id = @id AND branch_id = @branch_id)
				BEGIN
				    INSERT INTO dbo.hist_B
				    SELECT id,
				    [select],
				    @branch_id, @current_version, valid_from, @current_datetime, is_delete, author
				    FROM dbo.hist_B WHERE id = @id AND branch_id = 'master' and valid_to is null
				END
			 ELSE
				BEGIN
				    UPDATE dbo.hist_B SET
					   valid_to = @current_datetime
				    WHERE id = @id
					   AND branch_id = @branch_id
					   AND valid_to IS NULL
				END

			 INSERT INTO dbo.hist_B VALUES (
				@id,
				@select,
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
			 set @msg = 'ERROR: B (id: ' + CAST(@id AS NVARCHAR(MAX)) + ') does not exist';
			 THROW 50000, @msg, 1
		  END
	   COMMIT TRANSACTION;
    END TRY 
    BEGIN CATCH 
        ROLLBACK TRANSACTION;
        THROW
    END CATCH
END