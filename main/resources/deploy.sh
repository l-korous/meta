#!/bin/bash  
#=================
# Add trailing slash
set -e
metaHome=$META_HOME
[[ "${metaHome}" != */ ]] && metaHome="${metaHome}/"

# Deploy DB
${metaHome}main/target/sql/deploy_mssql.sh

# Create Kafka topics, Confluent plugins / scanners
if [[ "$OSTYPE" == "linux-gnu" ]]; then
	${metaHome}main/target/kafka/deploy_kafka.sh
fi

# Create a container with Node.js app
${metaHome}main/target/html/deploy_html.sh
(cd ${metaHome}main/target/js && docker build .)

echo Deployment done.