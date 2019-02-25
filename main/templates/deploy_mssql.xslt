<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:meta="meta">
    <xsl:import href="utilities.xsl"/>
	<xsl:output method="text" indent="no" encoding="UTF-8" omit-xml-declaration="yes" />
	<xsl:strip-space elements="*"/>
    <xsl:template match="configurations">
#!/bin/bash  
#=================
# Should run in the folder with sqls
# SQL credentials (! no quotes)
<xsl:if test="//configuration[@key='UseEmbeddedDb']/@value = 1">
sqlCredentials="-S localhost\\SQLEXPRESS"
</xsl:if>
<xsl:if test="//configuration[@key='UseEmbeddedDb']/@value = 0">
sqlCredentials="-S <xsl:value-of select="//configuration[@key='DbHostName']/@value" /><xsl:if test="//configuration[@key='DbInstanceName']/@value != ''">\\<xsl:value-of select="//configuration[@key='DbInstanceName']/@value" />"</xsl:if>
</xsl:if>
logDir=${pwd}deployment_log
#=================

# Add trailing slash
[[ "${logDir}" != */ ]] &amp;&amp; logDir="${logDir}/"
mkdir -p ${logDir}

# Deploy SQL
echo Deploying DB
for f in *.sql;
do
    printf "."
    sqlcmd -b -C -o ${logDir}$f.txt $sqlCredentials -i "$f" -f 65001
	if [ "$?" -ne 0 ] ; then
		cat ${logDir}$filename.txt
		exit $?
	fi 
done
echo
echo SQL Deployment successful.
    </xsl:template>
</xsl:stylesheet>
