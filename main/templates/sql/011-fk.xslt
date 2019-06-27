<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:meta="meta">
    <xsl:import href="../utilities.xsl"/>
	<xsl:output method="text" indent="no" encoding="UTF-8" omit-xml-declaration="yes" />
    <xsl:strip-space elements="*"/>
    <xsl:template match="tables">
use <xsl:value-of select="//configuration[@key='DbName']/@value" />
GO
<xsl:for-each select="//table" >
    <xsl:for-each select="columns/column[@referenced_table_name != '']" >
ALTER TABLE dbo.__new_<xsl:value-of select="../../@table_name" /> ADD CONSTRAINT FK__new__<xsl:value-of select="@column_name" />_<xsl:value-of select="../../@table_name" />_<xsl:value-of select="@referenced_table_name" />_<xsl:value-of select="@referenced_column_name" /> FOREIGN KEY (
    [<xsl:value-of select="@column_name" />],
    [branch_name])
    REFERENCES dbo.__new_<xsl:value-of select="@referenced_table_name" /> (
    [<xsl:value-of select="@referenced_column_name" />],
    [branch_name])
    ON UPDATE NO ACTION ON DELETE <xsl:if test="not(@on_delete != '')">CASCADE</xsl:if><xsl:if test="@on_delete!=''"><xsl:value-of select="@on_delete" /></xsl:if>
    </xsl:for-each>
</xsl:for-each>
</xsl:template>
</xsl:stylesheet>
