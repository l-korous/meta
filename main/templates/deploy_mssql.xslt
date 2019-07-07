<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:meta="meta">
    <xsl:import href="utilities.xsl"/>
	<xsl:output method="text" indent="no" encoding="UTF-8" omit-xml-declaration="yes" />
	<xsl:strip-space elements="*"/>
    <xsl:template match="configurations">
#!/bin/bash
# Should run in the folder with sqls
# SQL credentials (! no quotes)
<xsl:if test="//configuration[@key='UseEmbeddedDb']/@value = 1">
sqlCredentials="-S localhost\\SQLEXPRESS"
</xsl:if>
<xsl:if test="//configuration[@key='UseEmbeddedDb']/@value = 0">
sqlCredentials="-S <xsl:value-of select="//configuration[@key='DbHostName']/@value" /><xsl:if test="//configuration[@key='DbInstanceName']/@value != ''">\\<xsl:value-of select="//configuration[@key='DbInstanceName']/@value" />"</xsl:if>
</xsl:if>
# Add trailing slash
metaHome=$META_HOME
[[ "${metaHome}" != */ ]] &amp;&amp; metaHome="${metaHome}/"
#=================

# Deploy SQL
echo Deploying DB
scriptCount=$(ls -l ${metaHome}main/target/sql/*.sql | wc -l)
i=1
for f in ${metaHome}main/target/sql/*.sql;
do
    filename=${f##*/}
	filename=${filename%".sql"}
    printf "($i / $scriptCount) $filename";echo
	logfile=$filename.txt
	
	if [[ "$OSTYPE" != "linux-gnu" ]]; then
		f=$(echo "$f" | sed -e 's/^\///' -e 's/\//\\/g' -e 's/^./\0:/')
	fi
	
	sqlcmd -b -C -o ${logfile} $sqlCredentials -i "$f" -f 65001
	
	if [ "$?" -ne 0 ] ; then
		cat $filename.txt
		exit $?
    else
        rm $filename.txt
	fi
    i=$((i+1))
done
echo
echo SQL Deployment successful.
	</xsl:template>
</xsl:stylesheet>
