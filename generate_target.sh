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

for f in ${templatesPath}*.xslt;
do
    printf "."
    filename=${f##*/}
    filename=${filename%".xslt"}
	xsltproc $f $1 > ${targetPath}$filename.sql
done
echo  Generation successful.