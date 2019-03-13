#!/bin/bash  
#=================
# Add trailing slash
metaHome=$META_HOME
[[ "${metaHome}" != */ ]] && metaHome="${metaHome}/"
templatesPath=${metaHome}main/templates
#=================
if [ $# -lt 3 ] 
then
    echo "usage: ${0##*/} <xmlModelFile> <targetPath> <sql credentials>"
    xmlModelFile="${metaHome}main/input/model.xml"
    targetPath="${metaHome}main/target"
	sqlCredentials="-S localhost\\SQLEXPRESS"
    # exit
else
    xmlModelFile=$1
    targetPath=$2
	sqlCredentials=$3
fi

# Add trailing slash
[[ "${targetPath}" != */ ]] && targetPath="${targetPath}/"

echo Generating artefacts
${metaHome}main/bin/generate_artefacts.sh $xmlModelFile $targetPath $sqlCredentials
echo Copying resources
cp -r ${metaHome}main/resources/* $targetPath

echo Preparation successful, run deploy.sh.