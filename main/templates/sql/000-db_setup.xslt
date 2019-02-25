<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:meta="meta">
    <xsl:import href="../utilities.xsl"/>
	<xsl:output method="text" indent="no" encoding="UTF-8" omit-xml-declaration="yes" />
	<xsl:strip-space elements="*"/>
    <xsl:template match="configurations">
USE master
IF (EXISTS (SELECT name FROM master.dbo.sysdatabases WHERE ('[' + name + ']' = '<xsl:value-of select="//configuration[@key='DbName']/@value" />' OR name = '<xsl:value-of select="//configuration[@key='DbName']/@value" />')))
    BEGIN
	   ALTER DATABASE <xsl:value-of select="//configuration[@key='DbName']/@value" /> SET single_user WITH ROLLBACK IMMEDIATE;
	   DROP DATABASE <xsl:value-of select="//configuration[@key='DbName']/@value" />
    END
GO
CREATE DATABASE <xsl:value-of select="//configuration[@key='DbName']/@value" />;
GO
USE <xsl:value-of select="//configuration[@key='DbName']/@value" />
GO
CREATE SCHEMA meta
GO
CREATE TABLE meta.[configuration] (
    [key] nvarchar(max),
    [value] nvarchar(max)
);
GO
    BEGIN TRY
        BEGIN TRANSACTION
        <xsl:for-each select="//configuration" >
            INSERT INTO meta.[configuration] VALUES ('<xsl:value-of select="@key" />', '<xsl:value-of select="@value" />')
        </xsl:for-each>
        COMMIT TRANSACTION;
    END TRY 
    BEGIN CATCH 
	   ROLLBACK TRANSACTION;
	   THROW
    END CATCH
GO
</xsl:template>
<xsl:template match="tables">
CREATE FUNCTION meta.is_version_closed (@version_name NVARCHAR(255)) RETURNS BIT
AS
BEGIN
    IF @version_name IS NULL
	   RETURN 1
    IF (SELECT version_status FROM meta.[version] WHERE version_name = @version_name) = 'CLOSED'
        return 1
    return 0
END
GO
CREATE TABLE meta.[branch]
(
    branch_name NVARCHAR(255) PRIMARY KEY,
    start_master_version_name NVARCHAR(255),
    last_closed_version_name NVARCHAR(255),
    current_version_name NVARCHAR(255)
)

CREATE TABLE meta.[version]
(
    version_name NVARCHAR(255) PRIMARY KEY,
    branch_name NVARCHAR(255),
    previous_version_name NVARCHAR(255),
    version_order int, -- Internal, only gives order on a particular branch
    version_status nvarchar(255)
)

ALTER TABLE meta.[branch] ADD CONSTRAINT FK_branch_start_master_version_name FOREIGN KEY (start_master_version_name) REFERENCES meta.[version] (version_name)
ALTER TABLE meta.[branch] ADD CONSTRAINT FK_branch_last_closed_version_name FOREIGN KEY (last_closed_version_name) REFERENCES meta.[version] (version_name)
ALTER TABLE meta.[branch] ADD CONSTRAINT FK_branch_current_version_name FOREIGN KEY (current_version_name) REFERENCES meta.[version] (version_name)
ALTER TABLE meta.[branch] ADD CONSTRAINT CHK_branch_last_closed_version_name CHECK (meta.is_version_closed(last_closed_version_name) = 1)

ALTER TABLE meta.[version] ADD CONSTRAINT FK_version_previous_version_name FOREIGN KEY (previous_version_name) REFERENCES meta.[version] (version_name)
ALTER TABLE meta.[version] ADD CONSTRAINT FK_version_branch_name FOREIGN KEY (branch_name) REFERENCES meta.[branch] (branch_name)

INSERT INTO meta.[branch] VALUES ('master', NULL, NULL, NULL)
INSERT INTO meta.[version] VALUES ('initial_version', 'master', NULL, 0, 'OPEN')
UPDATE meta.[branch] SET current_version_name = (select top 1 version_name from meta.[version] where version_name = 'initial_version')

CREATE TABLE meta.[datatype] (
    datatype_name nvarchar(255) primary key
);
INSERT INTO meta.[datatype] VALUES ('string');
INSERT INTO meta.[datatype] VALUES ('long_string');
INSERT INTO meta.[datatype] VALUES ('int');
INSERT INTO meta.[datatype] VALUES ('float');
INSERT INTO meta.[datatype] VALUES ('datetime');
INSERT INTO meta.[datatype] VALUES ('date');
INSERT INTO meta.[datatype] VALUES ('time');
INSERT INTO meta.[datatype] VALUES ('boolean');

CREATE TABLE meta.[table] (
    table_name nvarchar(255) PRIMARY KEY
);
GO
CREATE TABLE meta.[column] (
    column_name nvarchar(255), 
    table_name nvarchar(255), 
    datatype nvarchar(255), 
    is_primary_key bit,
    is_unique bit,
    is_nullable bit,
    PRIMARY KEY ([table_name], [column_name])
);
GO
ALTER TABLE meta.[column] ADD CONSTRAINT FK_column_table FOREIGN KEY (table_name) REFERENCES meta.[table] (table_name);
GO
ALTER TABLE meta.[column] ADD CONSTRAINT FK_column_datatype FOREIGN KEY (datatype) REFERENCES meta.[datatype] (datatype_name);
GO
CREATE TABLE meta.[reference] (
    reference_name nvarchar(255),
    src_table_name nvarchar(255),
    dest_table_name nvarchar(255),
    on_delete nvarchar(255),
    PRIMARY KEY ([reference_name])
);
GO
ALTER TABLE meta.[reference] ADD CONSTRAINT FK_reference_src_table_name FOREIGN KEY (src_table_name) REFERENCES meta.[table] (table_name);
GO
ALTER TABLE meta.[reference] ADD CONSTRAINT FK_reference_dest_table_name FOREIGN KEY (dest_table_name) REFERENCES meta.[table] (table_name);
GO
CREATE TABLE meta.[reference_detail] (
    reference_name nvarchar(255),
    src_table_name nvarchar(255),
    src_column_name nvarchar(255),
    dest_table_name nvarchar(255),
    dest_column_name nvarchar(255),
    PRIMARY KEY ([reference_name], [src_table_name], [src_column_name], [dest_table_name], [dest_column_name])
);
GO
ALTER TABLE meta.[reference_detail] ADD CONSTRAINT FK_reference_detail_reference_name FOREIGN KEY (reference_name) REFERENCES meta.[reference] (reference_name);
GO
ALTER TABLE meta.[reference_detail] ADD CONSTRAINT FK_reference_detail_src_table_name FOREIGN KEY (src_table_name) REFERENCES meta.[table] (table_name);
GO
ALTER TABLE meta.[reference_detail] ADD CONSTRAINT FK_reference_detail_dest_table_name FOREIGN KEY (dest_table_name) REFERENCES meta.[table] (table_name);
GO
ALTER TABLE meta.[reference_detail] ADD CONSTRAINT FK_reference_detail_src_column_name FOREIGN KEY (src_table_name, src_column_name) REFERENCES meta.[column] (table_name, column_name);
GO
ALTER TABLE meta.[reference_detail] ADD CONSTRAINT FK_reference_detail_dest_column_name FOREIGN KEY (dest_table_name, dest_column_name) REFERENCES meta.[column] (table_name, column_name);
GO
    BEGIN TRY
        BEGIN TRANSACTION
        <xsl:for-each select="//table" >
            INSERT INTO meta.[table] VALUES ('<xsl:value-of select="@table_name" />')
            <xsl:for-each select="columns/column" >
                INSERT INTO meta.[column] VALUES ('<xsl:value-of select="@column_name" />',
                    '<xsl:value-of select="../../@table_name" />',
                    '<xsl:value-of select="@datatype" />',
                    '<xsl:value-of select="@is_primary_key" />',
                    '<xsl:value-of select="@is_unique" />',
                    '<xsl:value-of select="@is_nullable" />')
            </xsl:for-each>
            <xsl:for-each select="references/reference" >
                INSERT INTO meta.[reference] VALUES ('<xsl:value-of select="@reference_name" />',
                    '<xsl:value-of select="@src_table_name" />',
                    '<xsl:value-of select="@dest_table_name" />',
                    '<xsl:value-of select="@on_delete" />')
                <xsl:for-each select="reference_details/reference_detail" >
                    INSERT INTO meta.[reference_detail] VALUES ('<xsl:value-of select="../../@reference_name" />',
                        '<xsl:value-of select="@src_table_name" />',
                        '<xsl:value-of select="@src_column_name" />',
                        '<xsl:value-of select="@dest_table_name" />',
                        '<xsl:value-of select="@dest_column_name" />')
                </xsl:for-each>
            </xsl:for-each>
        </xsl:for-each>
        COMMIT TRANSACTION;
    END TRY 
    BEGIN CATCH 
	   ROLLBACK TRANSACTION;
	   THROW
    END CATCH
GO
IF OBJECT_ID ('meta.get_tables') IS NOT NULL 
     DROP PROCEDURE meta.get_tables
GO
CREATE PROCEDURE meta.get_tables
AS
BEGIN
    SET XACT_ABORT, NOCOUNT ON
    DECLARE @msg nvarchar(255)
    BEGIN TRY
        SELECT * FROM meta.[table];
    END TRY
    BEGIN CATCH
    END CATCH
END
GO
IF OBJECT_ID ('meta.get_columns') IS NOT NULL 
     DROP PROCEDURE meta.get_columns
GO
CREATE PROCEDURE meta.get_columns
AS
BEGIN
    SET XACT_ABORT, NOCOUNT ON
    DECLARE @msg nvarchar(255)
    BEGIN TRY
        SELECT * FROM meta.[column];
    END TRY
    BEGIN CATCH
    END CATCH
END
GO
IF OBJECT_ID ('meta.get_references') IS NOT NULL 
     DROP PROCEDURE meta.get_references
GO
CREATE PROCEDURE meta.get_references
AS
BEGIN
    SET XACT_ABORT, NOCOUNT ON
    DECLARE @msg nvarchar(255)
    BEGIN TRY
        SELECT * FROM meta.[reference];
    END TRY
    BEGIN CATCH
    END CATCH
END
GO
IF OBJECT_ID ('meta.get_reference_details') IS NOT NULL 
     DROP PROCEDURE meta.get_reference_details
GO
CREATE PROCEDURE meta.get_reference_details
AS
BEGIN
    SET XACT_ABORT, NOCOUNT ON
    DECLARE @msg nvarchar(255)
    BEGIN TRY
        SELECT * FROM meta.[reference_detail];
    END TRY
    BEGIN CATCH
    END CATCH
END
GO
    </xsl:template>
</xsl:stylesheet>
