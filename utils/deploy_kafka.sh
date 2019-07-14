#!/bin/bash  
#=================
# Should run in the folder with kafka commands (../kafka)
currentDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &gt;/dev/null 2&gt;&amp;1 &amp;&amp; pwd )"
#=================

# Deploy SQL
echo Deploying Kafka

chmod +x ${currentDir}/create_topic.kafka
${currentDir}/create_topic.kafka > ${currentDir}/log-create_topic 2>&1

for f in ${currentDir}/meta_jdbc_connector_*;
do
    printf "."
	mv $f /etc/kafka-connect-jdbc/
done

chmod +x ${currentDir}/load_connector_instance.kafka
${currentDir}/load_connector_instance.sh > log-load_connector_instance 2>&1

echo Kafka Deployment successful.