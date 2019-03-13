#!/bin/bash  
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
    xmlModelFile="${metaHome}main/input/model.xml"
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

# Load model into the DB
# Old way:
#sqlcmd -b -C -o ${logfile} $sqlCredentials -i "${metaHome}/main/bin/recreate_model_management_procedures.sql" -f 65001
#sqlcmd -b -C -o ${logfile} $sqlCredentials -q "exec meta.model_upload(${xmlModelFile});" -f 65001 -o modelDiff.txt
# NEW proposal
# - upload XML (! is only a part of the deployment)
# - download the latest XML (replace the root tag with "-old")
# - here I need an XSLT that will take the old one and new one and generate DROP, CREATE, ALTER, and (!!!!) based on object names


# Read modelDiff.txt (or return value of the procedure call)
# - if DB empty, generate standard, no info
# - else, call generation of diff SQL, output it to the working directory, info that SQL part is not generated
# actual generation: ALTER - or - BACKUP TABLE -> CREATE NEW -> INSERT DATA TO NEW FROM BACKUP


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