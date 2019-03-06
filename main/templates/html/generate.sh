#!/bin/bash
# Usage: <script> <xml> <xslt> <outputName>
java -jar saxon9he.jar -s:$1 -xsl:$2 -o:$3