#!/bin/bash  
#=================
# $1 Model XML path
templatesPath=${pwd}templates
#=================
if [ $# -lt 2 ] 
then
    echo "usage: ${0##*/} <xmlModelFile> <targetPath>"
    exit
fi

# Add trailing slash
targetPath=$2
[[ "${templatesPath}" != */ ]] && templatesPath="${templatesPath}/"
[[ "${targetPath}" != */ ]] && targetPath="${targetPath}/"

# Delete target
rm -rf ${targetPath}*

for f in $(find ${templatesPath} -name "*.xslt")
do
    fullPath=$(dirname "${f/$templatesPath/""}")
    extension=$(echo "$fullPath" | cut -d "/" -f1)
    mkdir -p ${targetPath}${fullPath}
    printf "."
    filename=${f##*/}
    filename=${filename%".xslt"}
    xsltproc $f $1 > ${targetPath}${fullPath}/${filename}.${extension}
done

echo  Generation successful.