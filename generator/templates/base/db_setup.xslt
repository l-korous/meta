<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output method="text" indent="no" encoding="UTF-8" omit-xml-declaration="yes" />
	<xsl:strip-space elements="*"/>
    <xsl:template match="tables">
USE master
IF (EXISTS (SELECT name FROM master.dbo.sysdatabases WHERE ('[' + name + ']' = '<xsl:value-of select="$metaDbName" />' OR name = '<xsl:value-of select="$metaDbName" />')))
    BEGIN
	   ALTER DATABASE <xsl:value-of select="$metaDbName" /> SET single_user WITH ROLLBACK IMMEDIATE;
	   DROP DATABASE <xsl:value-of select="$metaDbName" />
    END
GO
CREATE DATABASE <xsl:value-of select="$metaDbName" />;
GO
use <xsl:value-of select="$metaDbName" />;
GO
CREATE FUNCTION dbo.is_version_closed (@version_id NVARCHAR(50)) RETURNS BIT
AS
BEGIN
    IF @version_id IS NULL
	   RETURN 1
    IF (SELECT version_status FROM dbo.[version] WHERE version_id = @version_id) = 'closed'
        return 1
    return 0
END
GO

CREATE TABLE dbo.[branch]
(
    branch_id NVARCHAR(50) PRIMARY KEY,
    start_master_version_id NVARCHAR(50),
    last_closed_version_id NVARCHAR(50),
    current_version_id NVARCHAR(50)
)

CREATE TABLE dbo.[version]
(
    version_id NVARCHAR(50) PRIMARY KEY,
    branch_id NVARCHAR(50),
    previous_version_id NVARCHAR(50),
    version_order int, -- Internal, only gives order on a particular branch
    version_status nvarchar(255)
)

ALTER TABLE dbo.[branch] ADD CONSTRAINT FK_branch_start_master_version_id FOREIGN KEY (start_master_version_id) REFERENCES dbo.[version] (version_id)
ALTER TABLE dbo.[branch] ADD CONSTRAINT FK_branch_last_closed_version_id FOREIGN KEY (last_closed_version_id) REFERENCES dbo.[version] (version_id)
ALTER TABLE dbo.[branch] ADD CONSTRAINT FK_branch_current_version_id FOREIGN KEY (current_version_id) REFERENCES dbo.[version] (version_id)
ALTER TABLE dbo.[branch] ADD CONSTRAINT CHK_branch_last_closed_version_id CHECK (dbo.is_version_closed(last_closed_version_id) = 1)

ALTER TABLE dbo.[version] ADD CONSTRAINT FK_version_previous_version_id FOREIGN KEY (previous_version_id) REFERENCES dbo.[version] (version_id)
ALTER TABLE dbo.[version] ADD CONSTRAINT FK_version_branch_id FOREIGN KEY (branch_id) REFERENCES dbo.[branch] (branch_id)

INSERT INTO dbo.[branch] VALUES ('master', NULL, NULL, NULL)
INSERT INTO dbo.[version] VALUES ('empty', 'master', NULL, 0, 'closed')
UPDATE dbo.[branch] SET last_closed_version_id = (select top 1 version_id from dbo.[version] where version_id = 'empty')

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
        <xsl:for-each select="//_table" >
            delete from dbo.<xsl:value-of select="@_table" />;
            delete from dbo.conflicts_<xsl:value-of select="@_table" />;
        </xsl:for-each>
        <xsl:for-each select="//_table" >
            delete from dbo.hist_<xsl:value-of select="@_table" />;
        </xsl:for-each>
        
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
</xsl:template>
</xsl:stylesheet>
