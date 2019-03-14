#!/bin/bash
# Usage: <script> <xml> <xslt> <outputName>
# Add trailing slash
metaHome=$META_HOME
[[ "${metaHome}" != */ ]] && metaHome="${metaHome}/"
java -jar ${metaHome}main/bin/saxon9he.jar -s:$1 -xsl:$2 -o:$3