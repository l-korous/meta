#!/bin/bash  
ps aux | grep "node" > /dev/null 2>&1
if [[ "$?" == "0" ]]; then
    echo Node already running, skipping install.
else
    echo Installing NodeJS modules...
    npm install
    npm install -g nodemon
    mkdir -p tmp
fi
