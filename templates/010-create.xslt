<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE xsl:stylesheet [<!ENTITY s "&#160;">]>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output method="text" indent="no" encoding="UTF-8" omit-xml-declaration="yes" />
    <xsl:strip-space elements="*"/>
    <xsl:template match="tables">
    
use <xsl:value-of select="//configuration[@key='DbName']/@value" />
GO
<xsl:for-each select="//table" >
CREATE TABLE dbo.[<xsl:value-of select="@table_name" />]
(
    <xsl:for-each select="columns/column" >
        [<xsl:value-of select="@column_name" />]&s;<xsl:value-of select="@datatype" /> <xsl:if test="@is_nullable = 0">&s;NOT NULL</xsl:if>,
    </xsl:for-each>
    branch_id NVARCHAR(50),
    PRIMARY KEY (
        <xsl:for-each select="columns/column[@is_primary_key=1]" >
            [<xsl:value-of select="@column_name" />],
        </xsl:for-each>
    branch_id
    )
)

CREATE TABLE dbo.hist_<xsl:value-of select="@table_name" />
(
    <xsl:for-each select="columns/column" >
        [<xsl:value-of select="@column_name" />]&s;<xsl:value-of select="@datatype" />,
    </xsl:for-each>
    branch_id NVARCHAR(50),
    version_id NVARCHAR(50),
    valid_from DATETIME,
    valid_to DATETIME,
    is_delete BIT,
    author NVARCHAR(255)
)

CREATE TABLE dbo.conflicts_<xsl:value-of select="@table_name" />
(
    merge_version_id NVARCHAR(50),
    <xsl:for-each select="columns/column[@is_primary_key=1]" >
        [<xsl:value-of select="@column_name" />]&s;<xsl:value-of select="@datatype" />,
    </xsl:for-each>
    is_del_master BIT,
    is_del_branch BIT,
    <xsl:for-each select="columns/column[@is_primary_key=0]" >
        <xsl:value-of select="@column_name" />_master &s; <xsl:value-of select="@datatype" />,
    </xsl:for-each>
    <xsl:for-each select="columns/column[@is_primary_key=0]" >
        <xsl:value-of select="@column_name" />_branch &s; <xsl:value-of select="@datatype" />,
    </xsl:for-each>
    last_author_master NVARCHAR(255),
    last_version_id_master NVARCHAR(50),
    last_change_master datetime
)
GO

ALTER TABLE dbo.[<xsl:value-of select="@table_name" />] ADD CONSTRAINT FK_<xsl:value-of select="@table_name" />_branch_id FOREIGN KEY (branch_id) REFERENCES dbo.[branch] (branch_id)
ALTER TABLE dbo.hist_<xsl:value-of select="@table_name" /> ADD CONSTRAINT FK_hist_<xsl:value-of select="@table_name" />_branch_id FOREIGN KEY (branch_id) REFERENCES dbo.[branch] (branch_id)
ALTER TABLE dbo.hist_<xsl:value-of select="@table_name" /> ADD CONSTRAINT FK_hist_<xsl:value-of select="@table_name" />_version_id FOREIGN KEY (version_id) REFERENCES dbo.[version] (version_id)
ALTER TABLE dbo.conflicts_<xsl:value-of select="@table_name" /> ADD CONSTRAINT FK_conflicts_<xsl:value-of select="@table_name" />_merge_version_id FOREIGN KEY (merge_version_id) REFERENCES dbo.[version] (version_id)
ALTER TABLE dbo.conflicts_<xsl:value-of select="@table_name" /> ADD CONSTRAINT FK_conflicts_<xsl:value-of select="@table_name" />_last_version_id_master FOREIGN KEY (last_version_id_master) REFERENCES dbo.[version] (version_id)
</xsl:for-each>
</xsl:template>
</xsl:stylesheet>
