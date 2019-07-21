<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:meta="meta">
    <xsl:import href="utilities.xsl"/>
	<xsl:output method="text" indent="no" encoding="UTF-8" omit-xml-declaration="yes" />
	<xsl:strip-space elements="*"/>
    <xsl:template match="configurations">
#!/bin/bash  
set -e
currentDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &gt;/dev/null 2&gt;&amp;1 &amp;&amp; pwd )"

# Deploy DB
${currentDir}/sql/deploy_mssql.sh

# For development only
if [[ "$OSTYPE" != "linux-gnu" ]]; then
    PATH=$PATH:"/c/Program Files/Docker/Docker/Resources/bin"
fi

# For production only
if [[ "$OSTYPE" == "linux-gnu" ]]; then
    # Create Kafka topics, Confluent plugins / scanners
    ${currentDir}/kafka/deploy_kafka.sh
    
    # Create a container with Node.js app
    tag="<xsl:value-of select="lower-case(//configuration[@key='DbName']/@value)" />-${PWD##*/}"
    (cd ${currentDir}/js &amp;&amp; docker build -t $tag --build-arg BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ') .)
    echo "docker save $tag | gzip -c &gt; docker-img-$tag.tar.gz; echo -n docker-img-$tag.tar.gz;" > save_docker_img.sh
fi

echo Deployment done.
	</xsl:template>
</xsl:stylesheet>
