#!/bin/bash  
#=================
# SQL credentials (! no quotes)
sqlCredentials="-S localhost\\SQLEXPRESS -Usa -Pasdf"
logDir=${pwd}deployment_log
#=================

# Add trailing slash
[[ "${logDir}" != */ ]] && logDir="${logDir}/"
mkdir -p ${logDir}

# Deploy SQL
echo Deploying DB
for f in sql/*;
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

# Deploy JS
#echo Executing 'npm install'
npm install
#echo Installing NodeMon
npm install -g nodemon