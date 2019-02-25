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

# TODO: this should be uncommented together with adding cp from resources to target >>>
# Delete target
# rm -rf ${targetPath}*
# <<<

# All templates for the target technology
for ext in sql kafka js html
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

# Deployment etc. templates that require custom handling
java -jar saxon9he.jar -s:$xmlModelFile -xsl:templates/deploy_mssql.xslt -o:${targetPath}/sql/deploy_mssql.s
echo
echo  Generation done.