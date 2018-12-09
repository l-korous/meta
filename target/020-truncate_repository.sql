
USE meta3
GO

IF OBJECT_ID ('dbo.truncate_repository') IS NOT NULL 
     DROP PROCEDURE dbo.truncate_repository
GO
CREATE PROCEDURE dbo.truncate_repository
AS
BEGIN
    SET XACT_ABORT, NOCOUNT ON
    BEGIN TRY
    BEGIN TRANSACTION
        EXEC sp_MSforeachtable "ALTER TABLE ? NOCHECK CONSTRAINT all"
        delete from dbo.version;
        delete from dbo.branch;
        
            delete from dbo.[Column];
            delete from dbo.conflicts_Column;
        
            delete from dbo.[Reference];
            delete from dbo.conflicts_Reference;
        
            delete from dbo.[Table];
            delete from dbo.conflicts_Table;
        
            delete from dbo.hist_Column;
        
            delete from dbo.hist_Reference;
        
            delete from dbo.hist_Table;
        
        
        exec sp_MSforeachtable "ALTER TABLE ? WITH CHECK CHECK CONSTRAINT all"
        INSERT INTO dbo.[branch] VALUES ('master', NULL, NULL, NULL)
        INSERT INTO dbo.[version] VALUES ('empty', 'master', NULL, 0, 'closed')
        UPDATE dbo.[branch] SET last_closed_version_id = (select top 1 version_id from dbo.[version] where version_id = 'empty')
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH 
	   ROLLBACK TRANSACTION;
	   THROW
    END CATCH 
END
GO
