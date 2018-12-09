<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output method="text" indent="no" encoding="UTF-8" omit-xml-declaration="yes" />
    <xsl:strip-space elements="*"/>
    <xsl:template match="tables">
use <xsl:value-of select="$metaDbName" />
GO
<xsl:for-each select="//_table" >
    <xsl:for-each select="_column[@_referenced_table!='NULL']" >
ALTER TABLE dbo.[<xsl:value-of select="../@_table" />] ADD CONSTRAINT FK_<xsl:value-of select="../@_table" />_<xsl:value-of select="@_column" />_<xsl:value-of select="@_referenced_table" />_<xsl:value-of select="@_referenced_table_column" /> FOREIGN KEY ([<xsl:value-of select="@_column" />], [branch_id]) REFERENCES dbo.[<xsl:value-of select="@_referenced_table" />]([<xsl:value-of select="@_referenced_table_column" />], [branch_id]) ON UPDATE NO ACTION ON DELETE <xsl:if test="@_on_delete='NULL'">NO ACTION</xsl:if><xsl:if test="@_on_delete!='NULL'"><xsl:value-of select="@_on_delete" /></xsl:if>
    </xsl:for-each>
</xsl:for-each>
</xsl:template>
</xsl:stylesheet>
