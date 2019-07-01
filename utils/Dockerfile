FROM debian:latest

RUN apt-get update
    
RUN apt install -y nodejs
RUN apt-get install -y build-essential
    
RUN useradd -m meta && echo "meta:meta" | chpasswd && adduser meta sudo

RUN mkdir -p /var/meta/nodejs && chown -R meta:meta /var/meta && chmod 2777 /var/meta

WORKDIR /var/meta/nodejs

COPY . .

# RUN touch /etc/apt/sources.list.d/nodesource.list
# RUN echo deb https://deb.nodesource.com/node_10.x stretch main | tee --append /etc/apt/sources.list.d/nodesource.list
# RUN echo deb-src https://deb.nodesource.com/node_10.x stretch main | tee --append /etc/apt/sources.list.d/nodesource.list
# RUN curl -sL https://deb.nodesource.com/setup_10.x | bash -

RUN ./deploy_nodejs.sh
RUN ./run_nodejs.sh

EXPOSE 80
EXPOSE 443
EXPOSE 22
EXPOSE 3000