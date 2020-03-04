<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:meta="meta">
    <xsl:import href="utilities.xsl"/>
	<xsl:output method="text" indent="no" encoding="UTF-8" omit-xml-declaration="yes" />
	<xsl:strip-space elements="*"/>
    <xsl:template match="configurations">
#!/bin/bash
# SQL credentials (! no quotes)
sqlCredentials="-S <xsl:value-of select="//configuration[@key='DbHostNameMgmt']/@value" /><xsl:if test="//configuration[@key='DbInstanceName']/@value != ''">\\<xsl:value-of select="//configuration[@key='DbInstanceName']/@value" /></xsl:if> -U <xsl:value-of select="//configuration[@key='DbUser']/@value" /> -P <xsl:value-of select="//configuration[@key='DbPassword']/@value" />"

#=================
# For development only
if [[ "$OSTYPE" != "linux-gnu" ]]; then
    PATH=$PATH:"/c/Program Files/Microsoft SQL Server/Client SDK/ODBC/130/Tools/Binn"
fi

# Deploy SQL
currentDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &gt;/dev/null 2&gt;&amp;1 &amp;&amp; pwd )"
echo Deploying DB
scriptCount=$(ls -l ${currentDir}/*.sql | wc -l)
i=1
for f in ${currentDir}/*.sql;
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
		cat ${logfile}
		exit $?
    else
        rm ${logfile}
	fi
    i=$((i+1))
done
echo SQL Deployment successful.
	</xsl:template>
</xsl:stylesheet>
