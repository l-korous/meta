#!/bin/bash  
#=================
# Should run in the folder with sqls (../sql)
# SQL credentials (! no quotes)
# This needs to come from a file in the target directory (generated)
sqlCredentials="-S localhost\\SQLEXPRESS -Usa -Pasdf"
logDir=${pwd}deployment_log
#=================

# Add trailing slash
[[ "${logDir}" != */ ]] && logDir="${logDir}/"
mkdir -p ${logDir}

# Deploy SQL
echo Deploying DB
for f in *;
do
    printf "."
    filename=${f##*/}
    filename=${filename%".sql"}
	if [[ "$OSTYPE" == "linux-gnu" ]]; then
	f=$f
	else
	f=$(sed -e 's/^\///' -e 's/\//\\/g' -e 's/^./\0:/' <<< $f)
	fi
    sqlcmd -b -C -o ${logDir}$filename.txt $sqlCredentials -i "$f" -f 65001
	if [ "$?" -ne 0 ] ; then
		cat ${logDir}$filename.txt
		exit $?
	fi 
done
echo SQL Deployment successful.