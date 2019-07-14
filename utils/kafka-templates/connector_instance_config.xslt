<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE xsl:stylesheet [<!ENTITY s "&#160;">]>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:meta="meta">
    <xsl:import href="../utilities.xsl"/>
	<xsl:output method="text" indent="no" encoding="UTF-8" omit-xml-declaration="yes" />
    <xsl:strip-space elements="*"/>
    <xsl:template match="tables">
	<xsl:for-each select="//table" >
		<xsl:result-document method="xml" href="meta_jdbc_connector_{@table_name}.kafka">
			name=source-mssql-<xsl:value-of select="@table_name" />
			connector.class=io.confluent.connect.jdbc.JdbcSourceConnector
			tasks.max=1
			connection.url=jdbc:sqlserver://<xsl:value-of select="//configuration[@key='DbHostName']/@value" />:<xsl:value-of select="//configuration[@key='DbPort']/@value" />;user=<xsl:value-of select="//configuration[@key='DbUser']/@value" />;password=<xsl:value-of select="//configuration[@key='DbPassword']/@value" />;DatabaseName=<xsl:value-of select="//configuration[@key='DbName']/@value" />
			mode=incrementing
			query=select * from <xsl:value-of select="@table_name" />
			incrementing.column.name=unused
			topic.prefix=meta_<xsl:value-of select="@table_name" />
		</xsl:result-document>
	</xsl:for-each>
</xsl:template>
</xsl:stylesheet>