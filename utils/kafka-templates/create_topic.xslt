<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE xsl:stylesheet [<!ENTITY s "&#160;">]>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:meta="meta">
    <xsl:import href="../utilities.xsl"/>
	<xsl:output method="text" indent="no" encoding="UTF-8" omit-xml-declaration="yes" />
    <xsl:strip-space elements="*"/>
    <xsl:template match="tables">
	<xsl:for-each select="//table" >
		kafka-topics --create --topic meta_<xsl:value-of select="@table_name" /> --zookeeper <xsl:value-of select="//configuration[@key='ZookeeperHostAndPort']/@value" /> --partitions 1 --replication-factor 1
	</xsl:for-each>
</xsl:template>
</xsl:stylesheet>


