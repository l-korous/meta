FROM debian:latest

ARG BUILD_DATE
LABEL org.label-schema.build-date=$BUILD_DATE

RUN apt-get update
RUN apt-get -y upgrade
RUN apt-get -y install curl software-properties-common
RUN curl -sL https://deb.nodesource.com/setup_10.x | bash -
RUN apt-get install -y nodejs
       
RUN useradd -m meta && echo "meta:meta" | chpasswd && adduser meta sudo

RUN mkdir -p /var/meta/nodejs && chown -R meta:meta /var/meta && chmod 2777 /var/meta

WORKDIR /var/meta/nodejs

COPY . .

RUN npm install
RUN npm install -g nodemon

EXPOSE 80
EXPOSE 443
EXPOSE 22
EXPOSE 3000

ENTRYPOINT nodemon server.js