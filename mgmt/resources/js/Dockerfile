FROM debian:latest

RUN apt-get update
RUN apt-get -y upgrade
RUN apt-get -y install curl software-properties-common
RUN curl -sL https://deb.nodesource.com/setup_10.x | bash -
RUN apt-get install -y nodejs
       
RUN useradd -m meta && echo "meta:meta" | chpasswd && adduser meta sudo

RUN mkdir -p /var/meta && chown -R meta:meta /var/meta && chmod 2777 /var/meta

WORKDIR /var/meta
COPY . .
RUN npm install
RUN npm install -g nodemon