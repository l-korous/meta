#!/bin/bash  
#=================
templatesPath=${pwd}templates
#=================
if [ $# -lt 2 ] 
then
    echo "usage: ${0##*/} <xmlModelFile> <targetPath>"
    xmlModelFile="/b/sw/meta/main/input/model-out.xml"
    targetPath="/b/sw/meta/main/target"
    # exit
else
    xmlModelFile=$1
    targetPath=$2
fi

# Add trailing slash
[[ "${targetPath}" != */ ]] && targetPath="${targetPath}/"

echo Generating artefacts
./generate_artefacts.sh $xmlModelFile $targetPath
echo Copying resources
cp -r resources/* $targetPath

echo Preparation successful, run deploy.sh.