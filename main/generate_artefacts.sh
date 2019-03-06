#!/bin/bash  
#=================
# Add trailing slash
metaHome=$META_HOME
[[ "${metaHome}" != */ ]] && metaHome="${metaHome}/"
# This should have a trailing slash
templatesPath=${metaHome}main/templates/
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
        java -jar ${metaHome}main/saxon9he.jar -s:$xmlModelFile -xsl:$f -o:${targetPath}${ext}/${filename}.${ext}
    done
done

# Deployment etc. templates that require custom handling
java -jar ${metaHome}main/saxon9he.jar -s:$xmlModelFile -xsl:${metaHome}main/templates/deploy_mssql.xslt -o:${targetPath}/sql/deploy_mssql.sh
echo
echo  Generation done.