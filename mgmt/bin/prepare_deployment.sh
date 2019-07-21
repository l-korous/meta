#!/bin/bash
# A wrapper for all there is before actual deployment.
#=================
# Add trailing slash
metaHome=$META_HOME
[[ "${metaHome}" != */ ]] && metaHome="${metaHome}/"
# This MUST have a trailing slash
templatesPath=${metaHome}mgmt/templates/
#=================
if [ $# -lt 2 ]
then
    echo "usage: ${0##*/} <xmlModelFile> <targetDirName>"
    exit
else
    xmlModelFile=$1
    targetDirName=$2
fi

targetPath="${metaHome}mgmt/targets/${targetDirName}/"
xmlModelPath="${metaHome}mgmt/tmp/${xmlModelFile}"
mkdir -p $targetPath

echo Delete target
rm -rf ${targetPath}*

# All templates for the target technology
for ext in sql js html
do
    echo "Generating artefacts - ${ext}"
    for f in $(find ${templatesPath}${ext} -name "*.xslt")
    do
        printf "."
        mkdir -p ${targetPath}${ext}
        filename=${f##*/}
        filename=${filename%".xslt"}
        java -jar ${metaHome}mgmt/bin/saxon9he.jar -s:$xmlModelPath -xsl:$f -o:${targetPath}${ext}/${filename}.${ext}
    done
    echo ""
done

# Deployment etc. templates that require custom handling
java -jar ${metaHome}mgmt/bin/saxon9he.jar -s:$xmlModelPath -xsl:${metaHome}mgmt/templates/deploy.xslt -o:${targetPath}/deploy.sh
java -jar ${metaHome}mgmt/bin/saxon9he.jar -s:$xmlModelPath -xsl:${metaHome}mgmt/templates/deploy_mssql.xslt -o:${targetPath}/sql/deploy_mssql.sh

echo Copying resources
cp -r ${metaHome}mgmt/resources/* $targetPath

echo Preparation successful, run deploy.sh.