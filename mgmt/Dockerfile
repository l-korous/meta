FROM debian:latest

# Node.js
RUN apt-get update
RUN apt-get -y upgrade
RUN apt-get -y install curl software-properties-common
RUN curl -sL https://deb.nodesource.com/setup_10.x | bash -
RUN apt-get install -y nodejs

# Mssql
RUN echo 'deb http://ftp.debian.org/debian jessie-backports main' | tee --append /etc/apt/sources.list
apt-get update
RUN apt-get install -t jessie-backports openssl ca-certificates
RUN wget -qO- https://packages.microsoft.com/keys/microsoft.asc | apt-key add -
RUN add-apt-repository "$(wget -qO- https://packages.microsoft.com/config/ubuntu/16.04/mssql-server-2017.list)"
RUN add-apt-repository "$(wget -qO- https://packages.microsoft.com/config/ubuntu/16.04/prod.list)"
RUN apt-get update
RUN apt-get install -y mssql-server mssql-tools
RUN MSSQL_SA_PASSWORD=Asdf*314 MSSQL_PID=express /opt/mssql/bin/mssql-conf -n setup accept-eula
RUN ln -sfn /opt/mssql-tools/bin/sqlcmd /usr/bin/sqlcmd
RUN tar -xf sqljdbc_6.0.8112.200_enu.tar.gz
RUN rm 	sqljdbc_6.0.8112.200_enu.tar.gz
RUN mv sqljdbc_6.0/enu/jre8/*.jar /usr/share/java/kafka-connect-jdbc

# Docker
RUN curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -
RUN add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"
RUN apt-get update
RUN apt-get install docker-ce docker-ce-cli containerd.io
RUN service docker stop
RUN service docker start
       
RUN useradd -m meta && echo "meta:meta" | chpasswd && adduser meta sudo

RUN mkdir -p /var/meta/nodejs && chown -R meta:meta /var/meta && chmod 2777 /var/meta

WORKDIR /var/meta/nodejs

COPY . .

RUN npm install
RUN npm install -g nodemon

EXPOSE 3000

ENTRYPOINT nodemon server.js




