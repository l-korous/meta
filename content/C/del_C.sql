use metaSimple2

IF OBJECT_ID ('dbo.del_C') IS NOT NULL 
     DROP PROCEDURE dbo.del_C
GO

CREATE PROCEDURE dbo.del_C
(@branch_id NVARCHAR(50), @_123 nvarchar(255), @_4 nvarchar(255))
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
	   -- Record exists
	   IF NOT EXISTS (select * from dbo.C where _123 = @_123 AND branch_id = @branch_id)
		  BEGIN
			 set @msg = 'ERROR: C (_123: ' + CAST(@_123 AS NVARCHAR(MAX)) + ') does not exist';

			 THROW 50000, @msg, 1
		  END

	   declare @current_datetime datetime = getdate()
	   declare @current_version nvarchar(50) = (SELECT current_version_id from [branch] where branch_id = @branch_id)

	   

	   DELETE FROM dbo.C
	   WHERE _123 = @_123
		  AND branch_id = @branch_id

	   COMMIT TRANSACTION;
    END TRY 
    BEGIN CATCH 
	   ROLLBACK TRANSACTION;
	   THROW
    END CATCH
END
GO

IF OBJECT_ID('TRG_del_C') IS NOT NULL
DROP TRIGGER TRG_del_C
GO

CREATE TRIGGER TRG_del_C
ON dbo.C
AFTER DELETE AS
BEGIN
    declare @current_datetime datetime = getdate()
    
    -- EXISTENCE of history record for this branch (always true for master)
    INSERT INTO dbo.hist_C
    SELECT
	   _d._123,
	   _d._4,
	   _d.branch_id, _h.version_id, _h.valid_from, @current_datetime, _h.is_delete, _h.author
    FROM dbo.hist_C _h
    INNER JOIN DELETED _d
	   ON _h.[_123] = _d.[_123] AND _h.branch_id = 'master' and _h.valid_to is null
    LEFT JOIN dbo.hist_C _h_branch
	   ON _h_branch.[_123] = _d.[_123] AND _h_branch.branch_id = _d.branch_id
    WHERE
	   _h_branch.branch_id IS NULL
	
    BEGIN
	   UPDATE _h SET
		  valid_to = @current_datetime
	   FROM
		  dbo.hist_C _h
		  INNER JOIN 
		  DELETED _d
	   ON _h.[_123] = _d.[_123]
		  AND _h.branch_id = _d.branch_id
		  AND valid_to IS NULL
    END

    INSERT INTO dbo.hist_C SELECT
	   DELETED.[_123],
	   -- GENERATED >>>
	   NULL,
	   -- <<<
	   DELETED.branch_id,
	   _b.current_version_id,
	   @current_datetime,
	   NULL,
	   1,
	   CURRENT_USER
    FROM DELETED
    INNER JOIN [branch] _b
	   ON DELETED.branch_id = _b.branch_id
END
GO