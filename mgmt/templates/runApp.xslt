<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:meta="meta">
    <xsl:import href="utilities.xsl"/>
	<xsl:output method="text" indent="no" encoding="UTF-8" omit-xml-declaration="yes" />
	<xsl:strip-space elements="*"/>
    <xsl:template match="configurations">
#!/bin/bash
# docker stop $(docker ps -a -q --filter ancestor=<xsl:value-of select="lower-case(//configuration[@key='DbName']/@value)" />-${PWD##*/}) || :
docker stop $(docker ps -a -q)

docker run -p80:80 <xsl:value-of select="lower-case(//configuration[@key='DbName']/@value)" />-${PWD##*/}:latest
	</xsl:template>
</xsl:stylesheet>
