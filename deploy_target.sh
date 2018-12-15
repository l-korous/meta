#!/bin/bash  
#=================
# SQL credentials (! no quotes)
sqlCredentials="-S LK-HP-NEW\\SQLEXPRESS"
logDir=${pwd}deployment_log
targetPath=${pwd}target
#=================

# Add trailing slash
[[ "${logDir}" != */ ]] && logDir="${logDir}/"
[[ "${targetPath}" != */ ]] && targetPath="${targetPath}/"

# Delete logs
rm -rf ${logDir}*

# Deploy
for f in ${targetPath}*;
do
    printf "."
    filename=${f##*/}
    filename=${filename%".sql"}
    sqlcmd -b -C -o ${logDir}$filename.txt $sqlCredentials -i "$f" -f 65001
done
echo  Deployment successful.
