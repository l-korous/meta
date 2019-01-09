FROM debian:jessie

RUN apt-get update
    
RUN apt-get install -y nodejs
    
RUN useradd -m meta && echo "meta:meta" | chpasswd && adduser meta sudo

RUN mkdir -p /var/meta && chown -R meta:meta /var/meta && chmod 2777 /var/meta

WORKDIR /var/meta

COPY . .

WORKDIR /var/meta/nodejs

#RUN ./deploy_target.sh
#CMD ./run_target.sh

EXPOSE 80
EXPOSE 443
#EXPOSE 22
EXPOSE 3000