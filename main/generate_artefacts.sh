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
[[ "${templatesPath}" != */ ]] && templatesPath="${templatesPath}/"
[[ "${targetPath}" != */ ]] && targetPath="${targetPath}/"

# Delete target
# rm -rf ${targetPath}*



for ext in sql kafka js
do
    for f in $(find ${templatesPath}${ext} -name "*.xslt")
    do
        printf "."
        mkdir -p ${targetPath}${ext}
        filename=${f##*/}
        filename=${filename%".xslt"}
        java -jar saxon9he.jar -s:$xmlModelFile -xsl:$f -o:${targetPath}${ext}/${filename}.${ext}
    done
done

java -jar saxon9he.jar -s:$xmlModelFile -xsl:templates/deploy_mssql.xslt -o:${targetPath}/sql/deploy_mssql.sh
echo
echo  Generation successful.