#!/bin/bash  
#=================
# Should run in the folder with kafka commands (../kafka)
logDir=${pwd}deployment_log
#=================

# Add trailing slash
[[ "${logDir}" != */ ]] && logDir="${logDir}/"
mkdir -p ${logDir}

# Deploy SQL
echo Deploying Kafka

chmod +x create_topic.kafka
./create_topic.kafka > ${logDir}create_topic 2>&1

for f in meta_jdbc_connector_*;
do
    printf "."
	mv $f /etc/kafka-connect-jdbc/
done

chmod +x load_connector_instance.kafka
./load_connector_instance.sh > ${logDir}load_connector_instance 2>&1

echo Kafka Deployment successful.