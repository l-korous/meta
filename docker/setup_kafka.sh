wget -qO - https://packages.confluent.io/deb/5.1/archive.key | apt-key add -
add-apt-repository "deb [arch=amd64] https://packages.confluent.io/deb/5.1 stable main"
apt-get update && apt-get install -y confluent-community-2.11
confluent start