<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output method="text" indent="no" encoding="UTF-8" omit-xml-declaration="yes" />
    <xsl:strip-space elements="*"/>
    <xsl:template match="tables">
    
use <xsl:value-of select="$metaDbName" />

<xsl:for-each select="//_table" >
    CREATE TABLE dbo.<xsl:value-of select="@_table" />
    (
        <xsl:for-each select="_column" >
            <xsl:value-of select="@_column" /> <xsl:value-of select="@_datatype" /> <xsl:if test="not(@_is_nullable)">NOT NULL</xsl:if>,
        </xsl:for-each>
        branch_id NVARCHAR(50),
        PRIMARY KEY (
        <xsl:for-each select="_column[@_is_primary_key=1]" >
            <xsl:value-of select="@_column" />,
        </xsl:for-each>
            branch_id
        )
    )

    ALTER TABLE dbo.<xsl:value-of select="@_table" /> ADD CONSTRAINT FK_<xsl:value-of select="@_table" />_branch_id FOREIGN KEY (branch_id) REFERENCES dbo.[branch] (branch_id)
    ALTER TABLE dbo.hist_<xsl:value-of select="@_table" /> ADD CONSTRAINT FK_hist_<xsl:value-of select="@_table" />_branch_id FOREIGN KEY (branch_id) REFERENCES dbo.[branch] (branch_id)
    ALTER TABLE dbo.hist_<xsl:value-of select="@_table" /> ADD CONSTRAINT FK_hist_<xsl:value-of select="@_table" />_version_id FOREIGN KEY (version_id) REFERENCES dbo.[version] (version_id)
    ALTER TABLE dbo.conflicts_<xsl:value-of select="@_table" /> ADD CONSTRAINT FK_conflicts_<xsl:value-of select="@_table" />_merge_version_id FOREIGN KEY (merge_version_id) REFERENCES dbo.[version] (version_id)
    ALTER TABLE dbo.conflicts_<xsl:value-of select="@_table" /> ADD CONSTRAINT FK_conflicts_<xsl:value-of select="@_table" />_last_version_id_master FOREIGN KEY (last_version_id_master) REFERENCES dbo.[version] (version_id)
</xsl:for-each>
</xsl:template>
</xsl:stylesheet>
