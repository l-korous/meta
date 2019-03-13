#!/bin/bash  
#=================
# Add trailing slash
metaHome=$META_HOME
[[ "${metaHome}" != */ ]] && metaHome="${metaHome}/"

${metaHome}main/target/sql/deploy_mssql.sh
(cd ${metaHome}main/target/js && ./deploy_nodejs.sh)
# Must be done after Nodejs (goes to public folder)
${metaHome}main/target/html/deploy_html.sh

if [[ "$OSTYPE" == "linux-gnu" ]]; then
	${metaHome}main/target/kafka/deploy_kafka.sh
fi

echo Deployment done.