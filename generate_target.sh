#!/bin/bash  
#=================
# $1 Model XML path
templatesPath=${pwd}templates
targetPath=${pwd}target
#=================
if [ $# -lt 1 ] 
then
    echo "usage: generage_target.sh <xmlModelFile>"
    exit
fi

# Add trailing slash
[[ "${templatesPath}" != */ ]] && templatesPath="${templatesPath}/"
[[ "${targetPath}" != */ ]] && targetPath="${targetPath}/"

# Delete target
rm -rf ${targetPath}*

for f in ${templatesPath}*;
do
    printf "."
    filename=${f##*/}
    filename=${filename%".xslt"}
    xsltproc $f $1 > ${targetPath}$filename.sql
done
echo  Generation successful.