<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output method="text" indent="no" encoding="UTF-8" omit-xml-declaration="yes" />
    <xsl:strip-space elements="*"/>
    <xsl:template match="tables">
use <xsl:value-of select="//configuration[@key='DbName']/@value" />
GO
<xsl:for-each select="//table" >
    <xsl:for-each select="references/reference" >
ALTER TABLE dbo.[<xsl:value-of select="../../@table_name" />] ADD CONSTRAINT FK_<xsl:value-of select="@reference_name" />_<xsl:value-of select="@src_table_name" />_<xsl:value-of select="@dest_table_name" /> FOREIGN KEY (
    <xsl:for-each select="reference_details/reference_detail" >
        [<xsl:value-of select="@src_column_name" />],
    </xsl:for-each>
    [branch_id])
    REFERENCES dbo.[<xsl:value-of select="@dest_table_name" />] (
    <xsl:for-each select="reference_details/reference_detail" >
        [<xsl:value-of select="@dest_column_name" />],
    </xsl:for-each>
    [branch_id])
    ON UPDATE NO ACTION ON DELETE <xsl:if test="@on_delete='NULL'">NO ACTION</xsl:if><xsl:if test="@on_delete!='NULL'"><xsl:value-of select="@on_delete" /></xsl:if>
    </xsl:for-each>
</xsl:for-each>
</xsl:template>
</xsl:stylesheet>
