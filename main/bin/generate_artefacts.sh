#!/bin/bash  
# Generate all artefacts, both generic and special
#=================
# Add trailing slash
metaHome=$META_HOME
[[ "${metaHome}" != */ ]] && metaHome="${metaHome}/"
# This MUST have a trailing slash
templatesPath=${metaHome}main/templates/
# This MUST have a trailing slash
logDir=${metaHome}deployment_log/
#=================
if [ $# -lt 3 ] 
then
    echo "usage: ${0##*/} <xmlModelFile> <targetPath> <sql credentials>"
    xmlModelFile="${metaHome}testing/assets/model.xml"
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
        java -jar ${metaHome}main/bin/saxon9he.jar -s:$xmlModelFile -xsl:$f -o:${targetPath}${ext}/${filename}.${ext}
    done
done

# Deployment etc. templates that require custom handling
java -jar ${metaHome}main/bin/saxon9he.jar -s:$xmlModelFile -xsl:${metaHome}main/templates/deploy_mssql.xslt -o:${targetPath}/sql/deploy_mssql.sh
echo
echo  Generation done.