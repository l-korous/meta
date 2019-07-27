FROM debian:stable

# Node.js
RUN apt-get update
RUN apt-get -y upgrade
RUN apt-get -y install curl software-properties-common
RUN curl -sL https://deb.nodesource.com/setup_10.x | bash -
RUN apt-get install -y nodejs

# Docker
RUN curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -
RUN add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"
RUN apt-get update
RUN apt-get install -y gzip docker-ce docker-ce-cli containerd.io

RUN useradd -m meta && echo "meta:meta" | chpasswd && adduser meta sudo
RUN mkdir -p /var/meta-mgmt && chown -R meta:meta /var/meta-mgmt && chmod 2777 /var/meta-mgmt

RUN npm install -g nodemon
EXPOSE 4499

WORKDIR /var/meta-mgmt
COPY . .
RUN npm install

WORKDIR /var/meta-mgmt/resources/js
RUN service docker start
RUN sleep 1
RUN docker build -t meta-app .

WORKDIR /var/meta-mgmt
ENTRYPOINT nodemon server.js

# correct execution: winpty docker run --privileged=true -it meta-mgmt:latest
