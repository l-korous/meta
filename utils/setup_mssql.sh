echo 'deb http://ftp.debian.org/debian jessie-backports main' | tee --append /etc/apt/sources.list
apt-get update
apt-get install -t jessie-backports openssl ca-certificates
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | apt-key add -
add-apt-repository "$(wget -qO- https://packages.microsoft.com/config/ubuntu/16.04/mssql-server-2017.list)"
add-apt-repository "$(wget -qO- https://packages.microsoft.com/config/ubuntu/16.04/prod.list)"
apt-get update
apt-get install -y mssql-server mssql-tools
MSSQL_SA_PASSWORD=Asdf*314 MSSQL_PID=express /opt/mssql/bin/mssql-conf -n setup accept-eula
ln -sfn /opt/mssql-tools/bin/sqlcmd /usr/bin/sqlcmd
tar -xf sqljdbc_6.0.8112.200_enu.tar.gz
rm 	sqljdbc_6.0.8112.200_enu.tar.gz
mv sqljdbc_6.0/enu/jre8/*.jar /usr/share/java/kafka-connect-jdbc
