touch /etc/apt/sources.list.d/nodesource.list
echo deb https://deb.nodesource.com/node_10.x stretch main | tee --append /etc/apt/sources.list.d/nodesource.list
echo deb-src https://deb.nodesource.com/node_10.x stretch main | tee --append /etc/apt/sources.list.d/nodesource.list
curl -sL https://deb.nodesource.com/setup_10.x | bash -
apt install -y nodejs
apt-get install -y build-essential