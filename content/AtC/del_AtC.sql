use metaSimple2

IF OBJECT_ID ('dbo.del_AtC') IS NOT NULL 
     DROP PROCEDURE dbo.del_AtC
GO

CREATE PROCEDURE dbo.del_AtC
(@branch_id NVARCHAR(50), @A_sru int, @Cid int)
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
	   IF NOT EXISTS (select * from dbo.AtC where A_sru = @A_sru AND Cid = @Cid AND branch_id = @branch_id)
		  BEGIN
			 set @msg = 'ERROR: AtC (A_sru: ' + CAST(@A_sru AS NVARCHAR(MAX)) + ', Cid: ' + CAST(@Cid AS NVARCHAR(MAX)) + ') does not exist';
			 THROW 50000, @msg, 1
		  END

	   declare @current_datetime datetime = getdate()
	   declare @current_version nvarchar(50) = (SELECT current_version_id from [branch] where branch_id = @branch_id)

	   -- EXISTENCE of history record for this branch (always true for master)
	   IF @branch_id <> 'master' AND NOT EXISTS (SELECT 1 FROM dbo.hist_AtC WHERE A_sru = @A_sru AND Cid = @Cid AND branch_id = @branch_id)
		  BEGIN
			 INSERT INTO dbo.hist_AtC
			 SELECT
				A_sru,
				Cid,
				@branch_id, @current_version, valid_from, @current_datetime, is_delete, author
			 FROM dbo.hist_AtC WHERE A_sru = @A_sru AND Cid = @Cid AND branch_id = 'master' and valid_to is null
		  END
	   ELSE
		  BEGIN
			 UPDATE dbo.hist_AtC SET
				valid_to = @current_datetime
			 WHERE A_sru = @A_sru AND Cid = @Cid
				AND branch_id = @branch_id
				AND valid_to IS NULL
		  END

	   DELETE FROM dbo.AtC
	   WHERE A_sru = @A_sru AND Cid = @Cid
		  AND branch_id = @branch_id

	   INSERT INTO dbo.hist_AtC VALUES (
		  -- GENERATED >>>
		  @A_sru,
		  @Cid,
		  -- <<<
		  @branch_id,
		  @current_version,
		  @current_datetime,
		  NULL,
		  1,
		  CURRENT_USER
	   )
	   COMMIT TRANSACTION;
    END TRY 
    BEGIN CATCH 
	   ROLLBACK TRANSACTION;
	   THROW
    END CATCH
END
GO

IF OBJECT_ID('TRG_del_AtC') IS NOT NULL
DROP TRIGGER TRG_del_AtC
GO

CREATE TRIGGER TRG_del_AtC
ON dbo.AtC
AFTER DELETE AS
BEGIN
    declare @current_datetime datetime = getdate()
    
    -- EXISTENCE of history record for this branch (always true for master)
    INSERT INTO dbo.hist_AtC
    SELECT
	   _d.A_sru,
	   _d.Cid,
	   _d.branch_id, _h.version_id, _h.valid_from, @current_datetime, _h.is_delete, _h.author
    FROM dbo.hist_AtC _h
    INNER JOIN DELETED _d
	   ON _h.A_sru = _d.A_sru AND _h.Cid = _d.Cid AND _h.branch_id = 'master' and _h.valid_to is null
    LEFT JOIN dbo.hist_AtC _h_branch
	   ON _h_branch.A_sru = _d.A_sru AND _h_branch.Cid = _d.Cid AND _h_branch.branch_id = _d.branch_id
    WHERE
	   _h_branch.branch_id IS NULL
	
    BEGIN
	   UPDATE _h SET
		  valid_to = @current_datetime
	   FROM
		  dbo.hist_AtC _h
		  INNER JOIN 
		  DELETED _d
	   ON _h.A_sru = _d.A_sru
		 AND _h.Cid = _d.Cid
		  AND _h.branch_id = _d.branch_id
		  AND valid_to IS NULL
    END

    INSERT INTO dbo.hist_AtC SELECT
	   DELETED.A_sru,
	   DELETED.Cid,
	   -- GENERATED >>>
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