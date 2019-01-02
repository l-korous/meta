#!/bin/bash  
#=================
# SQL credentials (! no quotes)
sqlCredentials="-S localhost\\SQLEXPRESS"
logDir=${pwd}deployment_log
#=================
if [ $# -lt 1 ] 
then
    echo "usage: ${0##*/} <targetPath>"
    targetPath="/b/sw/meta/tests/structures/target"
    #exit
else
    targetPath=$1
fi

# Add trailing slash

[[ "${logDir}" != */ ]] && logDir="${logDir}/"
mkdir -p ${logDir}
[[ "${targetPath}" != */ ]] && targetPath="${targetPath}/"

# Deploy SQL
echo Deploying DB
for f in ${targetPath}sql/*;
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
#echo Setting up NodeJS directory
#cp -r resources/nodejs/* ${targetPath}js/
cd ${targetPath}js/
#echo Installing NodeJS modules
#npm install
#echo Installing NodeMon
#npm install -g nodemon
#echo Starting NodeJS
nodemon npm start

