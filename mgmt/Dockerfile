FROM debian:stretch

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

RUN mkdir -p /var/meta && chmod 2777 /var/meta

RUN npm install -g nodemon
EXPOSE 4499

WORKDIR /var/meta-mgmt
ADD bin bin
ADD templates templates
ADD public public
COPY *.js ./
COPY *.json ./
RUN mkdir tmp
RUN mkdir targets
RUN npm install

CMD ["sh","-c","service docker start; nodemon server.js"]

# correct execution: docker run --privileged=true -it meta-mgmt:latest
