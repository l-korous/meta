FROM debian:latest

RUN apt-get update \
    sudo apt-get install -y mssql-server nodejs npm
    
RUN sudo MSSQL_PID=EXPRESS ACCEPT_EULA=Y MSSQL_SA_PASSWORD='asdf' /opt/mssql/bin/mssql-conf -n setup

RUN useradd -m meta && echo "meta:meta" | chpasswd && adduser meta admin

RUN mkdir -p /var/meta && chown -R meta:meta /var/meta && chmod 2777 /var/meta

WORKDIR /var/meta

COPY . .

WORKDIR /var/meta/nodejs

RUN ./deploy_target.sh

CMD ./run_target.sh

EXPOSE 80
EXPOSE 3000
EXPOSE 1433

