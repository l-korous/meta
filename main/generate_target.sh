#!/bin/bash  
#=================
templatesPath=${pwd}templates
#=================
if [ $# -lt 2 ] 
then
    echo "usage: ${0##*/} <xmlModelFile> <targetPath>"
    xmlModelFile="/c/sw/meta/main/input/model-out.xml"
    targetPath="/c/sw/meta/main/target"
    # exit
else
    xmlModelFile=$1
    targetPath=$2
fi

# Add trailing slash
[[ "${templatesPath}" != */ ]] && templatesPath="${templatesPath}/"
[[ "${targetPath}" != */ ]] && targetPath="${targetPath}/"

# Delete target
# rm -rf ${targetPath}*

for f in $(find ${templatesPath} -name "*.xslt")
do
    fullPath=$(dirname "${f/$templatesPath/""}")
    extension=$(echo "$fullPath" | cut -d "/" -f1)
    mkdir -p ${targetPath}${fullPath}
    printf "."
    filename=${f##*/}
    filename=${filename%".xslt"}
    java -jar saxon9he.jar -s:$xmlModelFile -xsl:$f -o:${targetPath}${fullPath}/${filename}.${extension}
done

#cp -r resources/* ${targetPath}

echo  Generation successful.