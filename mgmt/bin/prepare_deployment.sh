#!/bin/bash
# A wrapper for all there is before actual deployment.
#=================
# Add trailing slash
metaHome=$META_HOME
[[ "${metaHome}" != */ ]] && metaHome="${metaHome}/"
# This MUST have a trailing slash
templatesPath=${metaHome}mgmt/templates/
#=================
if [ $# -lt 2 ]
then
    echo "usage: ${0##*/} <xmlModelPath> <targetPath>"
    exit
else
    xmlModelPath=$1
    targetPath=$2
    [[ "${targetPath}" != */ ]] && targetPath="${targetPath}/"
fi

mkdir -p $targetPath


echo "Generating artefacts - DB"
mkdir -p ${targetPath}db
for f in $(find ${templatesPath}db -name "*.xslt")
do
    printf "."
    filename=${f##*/}
    filename=${filename%".xslt"}
    java -jar ${metaHome}mgmt/bin/saxon9he.jar -s:$xmlModelPath -xsl:$f -o:${targetPath}db/${filename}.sql
done
echo ""

echo "Generating artefacts - BE"
mkdir -p ${targetPath}app
for f in $(find ${templatesPath}be -name "*.xslt")
do
    printf "."
    filename=${f##*/}
    filename=${filename%".xslt"}
    java -jar ${metaHome}mgmt/bin/saxon9he.jar -s:$xmlModelPath -xsl:$f -o:${targetPath}app/${filename}.js
done
echo ""

echo "Generating artefacts - FE"
mkdir -p ${targetPath}app/public/app
for f in $(find ${templatesPath}fe -name "*.xslt")
do
    printf "."
    filename=${f##*/}
    filename=${filename%".xslt"}
    java -jar ${metaHome}mgmt/bin/saxon9he.jar -s:$xmlModelPath -xsl:$f -o:${targetPath}app/public/app/${filename}.js
done
echo ""
    

# Deployment etc. templates that require custom handling
java -jar ${metaHome}mgmt/bin/saxon9he.jar -s:$xmlModelPath -xsl:${metaHome}mgmt/templates/deploy.xslt -o:${targetPath}/deploy.sh
java -jar ${metaHome}mgmt/bin/saxon9he.jar -s:$xmlModelPath -xsl:${metaHome}mgmt/templates/runApp.xslt -o:${targetPath}/runApp.sh
java -jar ${metaHome}mgmt/bin/saxon9he.jar -s:$xmlModelPath -xsl:${metaHome}mgmt/templates/deploy_mssql.xslt -o:${targetPath}/db/deploy_mssql.sh
java -jar ${metaHome}mgmt/bin/saxon9he.jar -s:$xmlModelPath -xsl:${metaHome}mgmt/templates/Dockerfile.xslt -o:${targetPath}/app/Dockerfile

echo Copying resources
printf "."
cp -r ${metaHome}mgmt/resources/* $targetPath
echo ""

echo Preparation successful, run deploy.sh in ${targetPath}