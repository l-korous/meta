<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE xsl:stylesheet [<!ENTITY s "&#160;">]>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:meta="meta">
    <xsl:import href="../utilities.xsl"/>
	<xsl:output method="text" indent="no" encoding="UTF-8" omit-xml-declaration="yes" />
    <xsl:strip-space elements="*"/>
    <xsl:template match="tables">
    
use <xsl:value-of select="//configuration[@key='DbName']/@value" />
GO
<xsl:for-each select="//table" >
CREATE TABLE dbo.[<xsl:value-of select="@table_name" />]
(
    <xsl:for-each select="columns/column" >
        [<xsl:value-of select="@column_name" />]&s;<xsl:value-of select="meta:datatype_to_sql(@datatype)" /> <xsl:if test="@is_nullable = 0">&s;NOT NULL</xsl:if>,
    </xsl:for-each>
    branch_name NVARCHAR(255),
    PRIMARY KEY (
        <xsl:for-each select="columns/column[@is_primary_key=1]" >
            [<xsl:value-of select="@column_name" />],
        </xsl:for-each>
    branch_name
    )
)

CREATE TABLE dbo.hist_<xsl:value-of select="@table_name" />
(
    <xsl:for-each select="columns/column" >
        [<xsl:value-of select="@column_name" />]&s;<xsl:value-of select="meta:datatype_to_sql(@datatype)" />,
    </xsl:for-each>
    branch_name NVARCHAR(255),
    version_name NVARCHAR(255),
    valid_from DATETIME,
    valid_to DATETIME,
    is_delete BIT,
    author NVARCHAR(255)
)

CREATE TABLE meta.conflicts_<xsl:value-of select="@table_name" />
(
    merge_version_name NVARCHAR(255),
    <xsl:for-each select="columns/column[@is_primary_key=1]" >
        [<xsl:value-of select="@column_name" />]&s;<xsl:value-of select="meta:datatype_to_sql(@datatype)" />,
    </xsl:for-each>
    is_del_master BIT,
    is_del_branch BIT,
    <xsl:for-each select="columns/column[@is_primary_key=0]" >
        <xsl:value-of select="@column_name" />_master &s; <xsl:value-of select="meta:datatype_to_sql(@datatype)" />,
    </xsl:for-each>
    <xsl:for-each select="columns/column[@is_primary_key=0]" >
        <xsl:value-of select="@column_name" />_branch &s; <xsl:value-of select="meta:datatype_to_sql(@datatype)" />,
    </xsl:for-each>
    last_author_master NVARCHAR(255),
    last_version_name_master NVARCHAR(255),
    last_change_master datetime
)
GO

ALTER TABLE dbo.[<xsl:value-of select="@table_name" />] ADD CONSTRAINT FK_<xsl:value-of select="@table_name" />_branch_name FOREIGN KEY (branch_name) REFERENCES meta.branch (branch_name)
ALTER TABLE dbo.hist_<xsl:value-of select="@table_name" /> ADD CONSTRAINT FK_hist_<xsl:value-of select="@table_name" />_branch_name FOREIGN KEY (branch_name) REFERENCES meta.branch (branch_name)
ALTER TABLE dbo.hist_<xsl:value-of select="@table_name" /> ADD CONSTRAINT FK_hist_<xsl:value-of select="@table_name" />_version_name FOREIGN KEY (version_name) REFERENCES meta.[version] (version_name)
ALTER TABLE meta.conflicts_<xsl:value-of select="@table_name" /> ADD CONSTRAINT FK_conflicts_<xsl:value-of select="@table_name" />_merge_version_name FOREIGN KEY (merge_version_name) REFERENCES meta.[version] (version_name)
ALTER TABLE meta.conflicts_<xsl:value-of select="@table_name" /> ADD CONSTRAINT FK_conflicts_<xsl:value-of select="@table_name" />_last_version_name_master FOREIGN KEY (last_version_name_master) REFERENCES meta.[version] (version_name)
</xsl:for-each>
</xsl:template>
</xsl:stylesheet>
