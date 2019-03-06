#!/bin/bash  
#=================
# Add trailing slash
metaHome=$META_HOME
[[ "${metaHome}" != */ ]] && metaHome="${metaHome}/"
templatesPath=${metaHome}main/templates
#=================
if [ $# -lt 2 ] 
then
    echo "usage: ${0##*/} <xmlModelFile> <targetPath>"
	xmlModelFile="${metaHome}main/input/model-out.xml"
    targetPath="${metaHome}main/target"
    # exit
else
    xmlModelFile=$1
    targetPath=$2
fi

# Add trailing slash
[[ "${targetPath}" != */ ]] && targetPath="${targetPath}/"

echo Generating artefacts
${metaHome}main/generate_artefacts.sh $xmlModelFile $targetPath
echo Copying resources
cp -r ${metaHome}main/resources/* $targetPath

echo Preparation successful, run deploy.sh.