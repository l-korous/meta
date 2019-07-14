<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:meta="meta">
    <xsl:import href="utilities.xsl"/>
	<xsl:output method="text" indent="no" encoding="UTF-8" omit-xml-declaration="yes" />
	<xsl:strip-space elements="*"/>
    <xsl:template match="configurations">
FROM meta-app:latest

ARG BUILD_DATE
LABEL org.label-schema.build-date=$BUILD_DATE

WORKDIR /var/meta

COPY . .

EXPOSE <xsl:value-of select="//configuration[@key='NodeJsPort']/@value" />

ENTRYPOINT nodemon server.js
	</xsl:template>
</xsl:stylesheet>
