#!/bin/bash  
#=================
if [[ "$OSTYPE" == "linux-gnu" ]]; then
    (cd sql && exec ./deploy_mssql.sh)
    (cd js && exec ./deploy_nodejs.sh)
    (cd kafka && exec ./deploy_kafka.sh)
else
    (cd sql && exec ./deploy_mssql.sh)
    (cd js && exec ./deploy_nodejs.sh)
fi
echo Deployment successful.