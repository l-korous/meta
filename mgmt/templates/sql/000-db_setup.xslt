<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:meta="meta">
    <xsl:import href="../utilities.xsl"/>
	<xsl:output method="text" indent="no" encoding="UTF-8" omit-xml-declaration="yes" />
	<xsl:strip-space elements="*"/>
    <xsl:template match="configurations">
USE master
DECLARE @should_create int = 0;
DECLARE @should_drop int = 0;
IF (EXISTS (SELECT name FROM master.dbo.sysdatabases WHERE ('[' + name + ']' = '<xsl:value-of select="//configuration[@key='DbName']/@value" />' OR name = '<xsl:value-of select="//configuration[@key='DbName']/@value" />')))
BEGIN
    IF (
        NOT (
            EXISTS (
                SELECT * FROM <xsl:value-of select="//configuration[@key='DbName']/@value" />.sys.TABLES t inner join <xsl:value-of select="//configuration[@key='DbName']/@value" />.sys.schemas s ON t.schema_id = s.schema_id AND t.name = 'table' and s.name = 'meta'
            )
        )
    )
    BEGIN
	   ALTER DATABASE <xsl:value-of select="//configuration[@key='DbName']/@value" /> SET single_user WITH ROLLBACK IMMEDIATE;
	   DROP DATABASE <xsl:value-of select="//configuration[@key='DbName']/@value" />
	   CREATE DATABASE <xsl:value-of select="//configuration[@key='DbName']/@value" /> COLLATE SQL_Latin1_General_CP1_CI_AI;
	   exec('USE <xsl:value-of select="//configuration[@key='DbName']/@value" />; exec sp_executesql N''CREATE SCHEMA meta'' ')
    END
END
ELSE
    BEGIN
	   CREATE DATABASE <xsl:value-of select="//configuration[@key='DbName']/@value" /> COLLATE SQL_Latin1_General_CP1_CI_AI;
	   exec('USE <xsl:value-of select="//configuration[@key='DbName']/@value" />; exec sp_executesql N''CREATE SCHEMA meta'' ')
    END
    
</xsl:template>
</xsl:stylesheet>