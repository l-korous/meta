<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:meta="meta">
    <xsl:import href="../utilities.xsl"/>
	<xsl:output method="text" indent="no" encoding="UTF-8" omit-xml-declaration="yes" />
	<xsl:strip-space elements="*"/>
    <xsl:template match="tables">
USE master
IF (EXISTS (SELECT name FROM master.dbo.sysdatabases WHERE ('[' + name + ']' = '<xsl:value-of select="//configuration[@key='DbName']/@value" />' OR name = '<xsl:value-of select="//configuration[@key='DbName']/@value" />')))
    BEGIN
	   ALTER DATABASE <xsl:value-of select="//configuration[@key='DbName']/@value" /> SET single_user WITH ROLLBACK IMMEDIATE;
	   DROP DATABASE <xsl:value-of select="//configuration[@key='DbName']/@value" />
    END
GO
CREATE DATABASE <xsl:value-of select="//configuration[@key='DbName']/@value" />;
GO
use <xsl:value-of select="//configuration[@key='DbName']/@value" />
GO
CREATE FUNCTION dbo.is_version_closed (@version_name NVARCHAR(255)) RETURNS BIT
AS
BEGIN
    IF @version_name IS NULL
	   RETURN 1
    IF (SELECT version_status FROM dbo.[version] WHERE version_name = @version_name) = 'CLOSED'
        return 1
    return 0
END
GO
CREATE TABLE dbo.[branch]
(
    branch_name NVARCHAR(255) PRIMARY KEY,
    start_master_version_name NVARCHAR(255),
    last_closed_version_name NVARCHAR(255),
    current_version_name NVARCHAR(255)
)

CREATE TABLE dbo.[version]
(
    version_name NVARCHAR(255) PRIMARY KEY,
    branch_name NVARCHAR(255),
    previous_version_name NVARCHAR(255),
    version_order int, -- Internal, only gives order on a particular branch
    version_status nvarchar(255)
)

ALTER TABLE dbo.[branch] ADD CONSTRAINT FK_branch_start_master_version_name FOREIGN KEY (start_master_version_name) REFERENCES dbo.[version] (version_name)
ALTER TABLE dbo.[branch] ADD CONSTRAINT FK_branch_last_closed_version_name FOREIGN KEY (last_closed_version_name) REFERENCES dbo.[version] (version_name)
ALTER TABLE dbo.[branch] ADD CONSTRAINT FK_branch_current_version_name FOREIGN KEY (current_version_name) REFERENCES dbo.[version] (version_name)
ALTER TABLE dbo.[branch] ADD CONSTRAINT CHK_branch_last_closed_version_name CHECK (dbo.is_version_closed(last_closed_version_name) = 1)

ALTER TABLE dbo.[version] ADD CONSTRAINT FK_version_previous_version_name FOREIGN KEY (previous_version_name) REFERENCES dbo.[version] (version_name)
ALTER TABLE dbo.[version] ADD CONSTRAINT FK_version_branch_name FOREIGN KEY (branch_name) REFERENCES dbo.[branch] (branch_name)

INSERT INTO dbo.[branch] VALUES ('master', NULL, NULL, NULL)
INSERT INTO dbo.[version] VALUES ('empty', 'master', NULL, 0, 'CLOSED')
UPDATE dbo.[branch] SET last_closed_version_name = (select top 1 version_name from dbo.[version] where version_name = 'empty')
</xsl:template>
</xsl:stylesheet>
