#!/bin/bash
# A wrapper for all there is before actual deployment.
# - calls generate_artefacts.sh
#=================
# Add trailing slash
metaHome=$META_HOME
[[ "${metaHome}" != */ ]] && metaHome="${metaHome}/"
templatesPath=${metaHome}main/templates
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

echo Generating artefacts
${metaHome}main/bin/generate_artefacts.sh $xmlModelFile $targetPath $sqlCredentials
echo Copying resources
cp -r ${metaHome}main/resources/* $targetPath

echo Preparation successful, run deploy.sh.