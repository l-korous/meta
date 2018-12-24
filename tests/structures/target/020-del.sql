
    
use meta3
GO

IF OBJECT_ID ('dbo.del_Table') IS NOT NULL 
     DROP PROCEDURE dbo.del_Table
GO
CREATE PROCEDURE dbo.del_Table
(
    @branch_id NVARCHAR(50)

    , @table_name nvarchar(255)

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
	   -- Record exists
	   IF NOT EXISTS (select * from dbo.[Table] where
       
            [table_name] = @table_name AND
        
       branch_id = @branch_id) BEGIN
            set @msg = 'ERROR: Table ( '+
            
            '[table_name]: ' + CAST(@table_name AS NVARCHAR(MAX)) + ', ' +
            
            'branch_id: ' + @branch_id + ') does not exist';
		  THROW 50000, @msg, 1
	   END

	   DELETE FROM dbo.[Table]
	   WHERE
        
            [table_name] = @table_name AND
        
		  branch_id = @branch_id

	   COMMIT TRANSACTION;
    END TRY 
    BEGIN CATCH 
	   ROLLBACK TRANSACTION;
	   THROW
    END CATCH
END
GO
IF OBJECT_ID('TRG_del_Table') IS NOT NULL
DROP TRIGGER TRG_del_Table
GO
CREATE TRIGGER TRG_del_Table
ON dbo.[Table]
AFTER DELETE AS
BEGIN
    declare @current_datetime datetime = getdate()

    -- EXISTENCE of history record for this branch (always true for master)
    INSERT INTO dbo.hist_Table
    SELECT
        
            _h.[table_name],
        
        _d.branch_id, _h.version_id, _h.valid_from, @current_datetime, _h.is_delete, _h.author
    FROM dbo.hist_Table _h
    INNER JOIN DELETED _d
	   ON
        
            _h.[table_name] = _d.[table_name] AND
        
        _h.branch_id = 'master' and _h.valid_to is null
    LEFT JOIN dbo.hist_Table _h_branch
	   ON
        
            _h_branch.[table_name] = _d.[table_name] AND
        
        _h_branch.branch_id = _d.branch_id
    WHERE
	   _h_branch.branch_id IS NULL
	
    BEGIN
	   UPDATE _h SET
		  valid_to = @current_datetime
	   FROM
		  dbo.hist_Table _h
		  INNER JOIN DELETED _d
		  ON
          
            _h.[table_name] = _d.[table_name] AND
        
			 _h.branch_id = _d.branch_id
			 AND valid_to IS NULL
    END

    INSERT INTO dbo.hist_Table SELECT
    
        DELETED.[table_name],
    
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

IF OBJECT_ID ('dbo.del_Column') IS NOT NULL 
     DROP PROCEDURE dbo.del_Column
GO
CREATE PROCEDURE dbo.del_Column
(
    @branch_id NVARCHAR(50)

    , @column_name nvarchar(255)
    , @table_name nvarchar(255)

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
	   -- Record exists
	   IF NOT EXISTS (select * from dbo.[Column] where
       
            [column_name] = @column_name AND
        
            [table_name] = @table_name AND
        
       branch_id = @branch_id) BEGIN
            set @msg = 'ERROR: Column ( '+
            
            '[column_name]: ' + CAST(@column_name AS NVARCHAR(MAX)) + ', ' +
            
            '[table_name]: ' + CAST(@table_name AS NVARCHAR(MAX)) + ', ' +
            
            'branch_id: ' + @branch_id + ') does not exist';
		  THROW 50000, @msg, 1
	   END

	   DELETE FROM dbo.[Column]
	   WHERE
        
            [column_name] = @column_name AND
        
            [table_name] = @table_name AND
        
		  branch_id = @branch_id

	   COMMIT TRANSACTION;
    END TRY 
    BEGIN CATCH 
	   ROLLBACK TRANSACTION;
	   THROW
    END CATCH
END
GO
IF OBJECT_ID('TRG_del_Column') IS NOT NULL
DROP TRIGGER TRG_del_Column
GO
CREATE TRIGGER TRG_del_Column
ON dbo.[Column]
AFTER DELETE AS
BEGIN
    declare @current_datetime datetime = getdate()

    -- EXISTENCE of history record for this branch (always true for master)
    INSERT INTO dbo.hist_Column
    SELECT
        
            _h.[column_name],
        
            _h.[table_name],
        
            _h.[datatype],
        
            _h.[is_primary_key],
        
            _h.[is_unique],
        
            _h.[is_nullable],
        
        _d.branch_id, _h.version_id, _h.valid_from, @current_datetime, _h.is_delete, _h.author
    FROM dbo.hist_Column _h
    INNER JOIN DELETED _d
	   ON
        
            _h.[column_name] = _d.[column_name] AND
        
            _h.[table_name] = _d.[table_name] AND
        
        _h.branch_id = 'master' and _h.valid_to is null
    LEFT JOIN dbo.hist_Column _h_branch
	   ON
        
            _h_branch.[column_name] = _d.[column_name] AND
        
            _h_branch.[table_name] = _d.[table_name] AND
        
        _h_branch.branch_id = _d.branch_id
    WHERE
	   _h_branch.branch_id IS NULL
	
    BEGIN
	   UPDATE _h SET
		  valid_to = @current_datetime
	   FROM
		  dbo.hist_Column _h
		  INNER JOIN DELETED _d
		  ON
          
            _h.[column_name] = _d.[column_name] AND
        
            _h.[table_name] = _d.[table_name] AND
        
			 _h.branch_id = _d.branch_id
			 AND valid_to IS NULL
    END

    INSERT INTO dbo.hist_Column SELECT
    
        DELETED.[column_name],
    
        DELETED.[table_name],
    
        NULL,
    
        NULL,
    
        NULL,
    
        NULL,
    
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

IF OBJECT_ID ('dbo.del_Reference') IS NOT NULL 
     DROP PROCEDURE dbo.del_Reference
GO
CREATE PROCEDURE dbo.del_Reference
(
    @branch_id NVARCHAR(50)

    , @reference_name nvarchar(255)

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
	   -- Record exists
	   IF NOT EXISTS (select * from dbo.[Reference] where
       
            [reference_name] = @reference_name AND
        
       branch_id = @branch_id) BEGIN
            set @msg = 'ERROR: Reference ( '+
            
            '[reference_name]: ' + CAST(@reference_name AS NVARCHAR(MAX)) + ', ' +
            
            'branch_id: ' + @branch_id + ') does not exist';
		  THROW 50000, @msg, 1
	   END

	   DELETE FROM dbo.[Reference]
	   WHERE
        
            [reference_name] = @reference_name AND
        
		  branch_id = @branch_id

	   COMMIT TRANSACTION;
    END TRY 
    BEGIN CATCH 
	   ROLLBACK TRANSACTION;
	   THROW
    END CATCH
END
GO
IF OBJECT_ID('TRG_del_Reference') IS NOT NULL
DROP TRIGGER TRG_del_Reference
GO
CREATE TRIGGER TRG_del_Reference
ON dbo.[Reference]
AFTER DELETE AS
BEGIN
    declare @current_datetime datetime = getdate()

    -- EXISTENCE of history record for this branch (always true for master)
    INSERT INTO dbo.hist_Reference
    SELECT
        
            _h.[reference_name],
        
            _h.[src_table_name],
        
            _h.[dest_table_name],
        
            _h.[on_delete],
        
        _d.branch_id, _h.version_id, _h.valid_from, @current_datetime, _h.is_delete, _h.author
    FROM dbo.hist_Reference _h
    INNER JOIN DELETED _d
	   ON
        
            _h.[reference_name] = _d.[reference_name] AND
        
        _h.branch_id = 'master' and _h.valid_to is null
    LEFT JOIN dbo.hist_Reference _h_branch
	   ON
        
            _h_branch.[reference_name] = _d.[reference_name] AND
        
        _h_branch.branch_id = _d.branch_id
    WHERE
	   _h_branch.branch_id IS NULL
	
    BEGIN
	   UPDATE _h SET
		  valid_to = @current_datetime
	   FROM
		  dbo.hist_Reference _h
		  INNER JOIN DELETED _d
		  ON
          
            _h.[reference_name] = _d.[reference_name] AND
        
			 _h.branch_id = _d.branch_id
			 AND valid_to IS NULL
    END

    INSERT INTO dbo.hist_Reference SELECT
    
        DELETED.[reference_name],
    
        NULL,
    
        NULL,
    
        NULL,
    
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

IF OBJECT_ID ('dbo.del_ReferenceDetail') IS NOT NULL 
     DROP PROCEDURE dbo.del_ReferenceDetail
GO
CREATE PROCEDURE dbo.del_ReferenceDetail
(
    @branch_id NVARCHAR(50)

    , @reference_name nvarchar(255)
    , @src_column_name nvarchar(255)

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
	   -- Record exists
	   IF NOT EXISTS (select * from dbo.[ReferenceDetail] where
       
            [reference_name] = @reference_name AND
        
            [src_column_name] = @src_column_name AND
        
       branch_id = @branch_id) BEGIN
            set @msg = 'ERROR: ReferenceDetail ( '+
            
            '[reference_name]: ' + CAST(@reference_name AS NVARCHAR(MAX)) + ', ' +
            
            '[src_column_name]: ' + CAST(@src_column_name AS NVARCHAR(MAX)) + ', ' +
            
            'branch_id: ' + @branch_id + ') does not exist';
		  THROW 50000, @msg, 1
	   END

	   DELETE FROM dbo.[ReferenceDetail]
	   WHERE
        
            [reference_name] = @reference_name AND
        
            [src_column_name] = @src_column_name AND
        
		  branch_id = @branch_id

	   COMMIT TRANSACTION;
    END TRY 
    BEGIN CATCH 
	   ROLLBACK TRANSACTION;
	   THROW
    END CATCH
END
GO
IF OBJECT_ID('TRG_del_ReferenceDetail') IS NOT NULL
DROP TRIGGER TRG_del_ReferenceDetail
GO
CREATE TRIGGER TRG_del_ReferenceDetail
ON dbo.[ReferenceDetail]
AFTER DELETE AS
BEGIN
    declare @current_datetime datetime = getdate()

    -- EXISTENCE of history record for this branch (always true for master)
    INSERT INTO dbo.hist_ReferenceDetail
    SELECT
        
            _h.[reference_name],
        
            _h.[src_table_name],
        
            _h.[src_column_name],
        
            _h.[dest_table_name],
        
            _h.[dest_column_name],
        
        _d.branch_id, _h.version_id, _h.valid_from, @current_datetime, _h.is_delete, _h.author
    FROM dbo.hist_ReferenceDetail _h
    INNER JOIN DELETED _d
	   ON
        
            _h.[reference_name] = _d.[reference_name] AND
        
            _h.[src_column_name] = _d.[src_column_name] AND
        
        _h.branch_id = 'master' and _h.valid_to is null
    LEFT JOIN dbo.hist_ReferenceDetail _h_branch
	   ON
        
            _h_branch.[reference_name] = _d.[reference_name] AND
        
            _h_branch.[src_column_name] = _d.[src_column_name] AND
        
        _h_branch.branch_id = _d.branch_id
    WHERE
	   _h_branch.branch_id IS NULL
	
    BEGIN
	   UPDATE _h SET
		  valid_to = @current_datetime
	   FROM
		  dbo.hist_ReferenceDetail _h
		  INNER JOIN DELETED _d
		  ON
          
            _h.[reference_name] = _d.[reference_name] AND
        
            _h.[src_column_name] = _d.[src_column_name] AND
        
			 _h.branch_id = _d.branch_id
			 AND valid_to IS NULL
    END

    INSERT INTO dbo.hist_ReferenceDetail SELECT
    
        DELETED.[reference_name],
    
        DELETED.[src_column_name],
    
        NULL,
    
        NULL,
    
        NULL,
    
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
