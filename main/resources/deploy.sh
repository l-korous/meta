#!/bin/bash  
#=================
(cd sql && exec ./deploy_mssql.sh)
(cd js && exec ./deploy_nodejs.sh)
# Must be done after Nodejs (goes to public folder)
(cd js && exec ./deploy_html.sh)

if [[ "$OSTYPE" == "linux-gnu" ]]; then
    (cd kafka && exec ./deploy_kafka.sh)
fi

echo Deployment done.