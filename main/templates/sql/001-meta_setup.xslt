<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:meta="meta">
    <xsl:import href="../utilities.xsl"/>
	<xsl:output method="text" indent="no" encoding="UTF-8" omit-xml-declaration="yes" />
	<xsl:strip-space elements="*"/>
    <xsl:template match="configurations">
USE <xsl:value-of select="//configuration[@key='DbName']/@value" />

/** Special case - function used in check constraint. Done this way because of MSSQL limitations about CREATE FUNCTION being first in batch etc. **/
IF OBJECT_ID ('dbo.[branch]', 'U') IS NOT NULL ALTER TABLE dbo.[branch] DROP CONSTRAINT CHK_branch_last_closed_version_name;
IF OBJECT_ID ('dbo.is_version_closed') IS NOT NULL DROP FUNCTION dbo.is_version_closed;
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
IF OBJECT_ID ('dbo.[branch]', 'U') IS NOT NULL ALTER TABLE dbo.[branch] ADD CONSTRAINT CHK_branch_last_closed_version_name CHECK (dbo.is_version_closed(last_closed_version_name) = 1);
GO
    
IF OBJECT_ID ('meta.get_tables') IS NOT NULL DROP PROCEDURE meta.get_tables;
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

IF OBJECT_ID ('meta.get_columns') IS NOT NULL DROP PROCEDURE meta.get_columns;
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

IF OBJECT_ID ('meta.get_references') IS NOT NULL DROP PROCEDURE meta.get_references;
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

IF OBJECT_ID ('meta.get_reference_details') IS NOT NULL DROP PROCEDURE meta.get_reference_details;
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

IF (
        NOT (
            EXISTS (
                SELECT * FROM <xsl:value-of select="//configuration[@key='DbName']/@value" />.sys.TABLES t inner join <xsl:value-of select="//configuration[@key='DbName']/@value" />.sys.schemas s ON t.schema_id = s.schema_id AND t.name = 'table' and s.name = 'meta'
            )
        )
    )
BEGIN
    CREATE TABLE meta.[configuration] (
        [key] nvarchar(max),
        [value] nvarchar(max)
    );
    
    CREATE TABLE dbo.[branch]
    (
        branch_name NVARCHAR(255) PRIMARY KEY,
        start_master_version_name NVARCHAR(255),
        last_closed_version_name NVARCHAR(255),
        current_version_name NVARCHAR(255)
    );

    CREATE TABLE dbo.[version]
    (
        version_name NVARCHAR(255) PRIMARY KEY,
        branch_name NVARCHAR(255),
        previous_version_name NVARCHAR(255),
        version_order int, -- Internal, only gives order on a particular branch
        version_status nvarchar(255)
    );
    
    CREATE TABLE meta.[datatype] (
        datatype_name nvarchar(255) primary key,
        datatype_sql nvarchar(255)
    );  

    CREATE TABLE meta.[model_version] (
        model_version int PRIMARY KEY IDENTITY(1, 1)
    );

    CREATE TABLE meta.[table] (
        model_version int,
        table_name nvarchar(255),
        PRIMARY KEY (model_version, table_name)
    );

    CREATE TABLE meta.[column] (
        model_version int,
        column_name nvarchar(255), 
        table_name nvarchar(255), 
        datatype_name nvarchar(255),
        is_primary_key bit,
        is_unique bit,
        is_required bit,
        PRIMARY KEY (model_version, [table_name], [column_name])
    ); 

    CREATE TABLE meta.[reference] (
        model_version int,
        reference_name nvarchar(255),
        referencing_table_name nvarchar(255),
        referenced_table_name nvarchar(255),
        on_delete nvarchar(255),
        PRIMARY KEY (model_version, [reference_name])
    );

    CREATE TABLE meta.[reference_detail] (
        model_version int,
        reference_name nvarchar(255),
        referencing_table_name nvarchar(255),
        referencing_column_name nvarchar(255),
        referenced_table_name nvarchar(255),
        referenced_column_name nvarchar(255),
        PRIMARY KEY (model_version, [reference_name], [referencing_table_name], [referencing_column_name], [referenced_table_name], [referenced_column_name])
    );

    ALTER TABLE dbo.[branch] ADD CONSTRAINT FK_branch_start_master_version_name FOREIGN KEY (start_master_version_name) REFERENCES dbo.[version] (version_name);
    ALTER TABLE dbo.[branch] ADD CONSTRAINT FK_branch_last_closed_version_name FOREIGN KEY (last_closed_version_name) REFERENCES dbo.[version] (version_name);
    ALTER TABLE dbo.[branch] ADD CONSTRAINT FK_branch_current_version_name FOREIGN KEY (current_version_name) REFERENCES dbo.[version] (version_name);
    ALTER TABLE dbo.[branch] ADD CONSTRAINT CHK_branch_last_closed_version_name CHECK (dbo.is_version_closed(last_closed_version_name) = 1);
    ALTER TABLE dbo.[version] ADD CONSTRAINT FK_version_previous_version_name FOREIGN KEY (previous_version_name) REFERENCES dbo.[version] (version_name);
    ALTER TABLE dbo.[version] ADD CONSTRAINT FK_version_branch_name FOREIGN KEY (branch_name) REFERENCES dbo.[branch] (branch_name);
    ALTER TABLE meta.[table] ADD CONSTRAINT FK_table_model_version FOREIGN KEY (model_version) REFERENCES meta.[model_version] (model_version);
    ALTER TABLE meta.[column] ADD CONSTRAINT FK_column_model_version FOREIGN KEY (model_version) REFERENCES meta.[model_version] (model_version);
    ALTER TABLE meta.[column] ADD CONSTRAINT FK_column_table FOREIGN KEY (model_version, table_name) REFERENCES meta.[table] (model_version, table_name);
    ALTER TABLE meta.[column] ADD CONSTRAINT FK_column_datatype FOREIGN KEY (datatype_name) REFERENCES meta.[datatype] (datatype_name);
    ALTER TABLE meta.[reference] ADD CONSTRAINT FK_reference_model_version FOREIGN KEY (model_version) REFERENCES meta.[model_version] (model_version);
    ALTER TABLE meta.[reference] ADD CONSTRAINT FK_reference_referencing_table_name FOREIGN KEY (model_version, referencing_table_name) REFERENCES meta.[table] (model_version, table_name);
    ALTER TABLE meta.[reference] ADD CONSTRAINT FK_reference_referenced_table_name FOREIGN KEY (model_version, referenced_table_name) REFERENCES meta.[table] (model_version, table_name);
    ALTER TABLE meta.[reference_detail] ADD CONSTRAINT FK_reference_detail_model_version FOREIGN KEY (model_version) REFERENCES meta.[model_version] (model_version);
    ALTER TABLE meta.[reference_detail] ADD CONSTRAINT FK_reference_detail_reference_name FOREIGN KEY (model_version, reference_name) REFERENCES meta.[reference] (model_version, reference_name);
    ALTER TABLE meta.[reference_detail] ADD CONSTRAINT FK_reference_detail_referencing_table_name FOREIGN KEY (model_version, referencing_table_name) REFERENCES meta.[table] (model_version, table_name);
    ALTER TABLE meta.[reference_detail] ADD CONSTRAINT FK_reference_detail_referenced_table_name FOREIGN KEY (model_version, referenced_table_name) REFERENCES meta.[table] (model_version, table_name);
    ALTER TABLE meta.[reference_detail] ADD CONSTRAINT FK_reference_detail_referencing_column_name FOREIGN KEY (model_version, referencing_table_name, referencing_column_name) REFERENCES meta.[column] (model_version, table_name, column_name);
    ALTER TABLE meta.[reference_detail] ADD CONSTRAINT FK_reference_detail_referenced_column_name FOREIGN KEY (model_version, referenced_table_name, referenced_column_name) REFERENCES meta.[column] (model_version, table_name, column_name);
    
    INSERT INTO dbo.[branch] VALUES ('master', NULL, NULL, NULL)
    INSERT INTO dbo.[version] VALUES ('initial_version', 'master', NULL, 0, 'OPEN')
    UPDATE dbo.[branch] SET current_version_name = (select top 1 version_name from dbo.[version] where version_name = 'initial_version')

    INSERT INTO meta.[datatype] VALUES ('string', 'NVARCHAR(255)');
    INSERT INTO meta.[datatype] VALUES ('long_string', 'NVARCHAR(MAX)');
    INSERT INTO meta.[datatype] VALUES ('int', 'INT');
    INSERT INTO meta.[datatype] VALUES ('float', 'FLOAT');
    INSERT INTO meta.[datatype] VALUES ('datetime', 'DATETIME');
    INSERT INTO meta.[datatype] VALUES ('date', 'DATE');
    INSERT INTO meta.[datatype] VALUES ('boolean', 'BIT');
    INSERT INTO meta.[datatype] VALUES ('time', 'TIME');
END

TRUNCATE TABLE meta.[configuration];

<xsl:for-each select="//configuration" >
    INSERT INTO meta.[configuration] VALUES ('<xsl:value-of select="@key" />', '<xsl:value-of select="@value" />')
</xsl:for-each>

</xsl:template>
<xsl:template match="tables">
INSERT INTO meta.[model_version] DEFAULT VALUES;
<xsl:for-each select="//table" >
    INSERT INTO meta.[table] VALUES ((SELECT MAX(model_version) from meta.[model_version]), '<xsl:value-of select="@table_name" />')
    <xsl:for-each select="columns/column" >
        INSERT INTO meta.[column] VALUES ((SELECT MAX(model_version) from meta.[model_version]), '<xsl:value-of select="@column_name" />',
            '<xsl:value-of select="../../@table_name" />',
            '<xsl:value-of select="@datatype" />',
            '<xsl:value-of select="@is_primary_key" />',
            '<xsl:value-of select="@is_unique" />',
            '<xsl:value-of select="@is_required" />')
    </xsl:for-each>
    <xsl:for-each select="references/reference" >
        INSERT INTO meta.[reference] VALUES ((SELECT MAX(model_version) from meta.[model_version]), '<xsl:value-of select="@reference_name" />',
            '<xsl:value-of select="@referencing_table_name" />',
            '<xsl:value-of select="@referenced_table_name" />',
            '<xsl:value-of select="@on_delete" />')
        <xsl:for-each select="reference_details/reference_detail" >
            INSERT INTO meta.[reference_detail] VALUES ((SELECT MAX(model_version) from meta.[model_version]), '<xsl:value-of select="../../@reference_name" />',
                '<xsl:value-of select="@referencing_table_name" />',
                '<xsl:value-of select="@referencing_column_name" />',
                '<xsl:value-of select="@referenced_table_name" />',
                '<xsl:value-of select="@referenced_column_name" />')
        </xsl:for-each>
    </xsl:for-each>
</xsl:for-each>

    </xsl:template>
</xsl:stylesheet>