apt-get install -y sudo

apt-get update

apt-get -y install vim git software-properties-common apt-transport-https curl dirmngr net-tools jq --install-recommends

touch  /etc/apt/sources.list.d/java-8-debian.list

echo 'deb http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main' | tee --append  /etc/apt/sources.list.d/java-8-debian.list

echo 'deb-src http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main' | tee --append  /etc/apt/sources.list.d/java-8-debian.list

apt-key adv --keyserver keyserver.ubuntu.com --recv-keys EEA14886

apt-get update

echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections

apt-get install oracle-java8-installer

apt-get install oracle-java8-set-default