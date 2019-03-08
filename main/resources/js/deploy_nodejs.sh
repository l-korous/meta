#!/bin/bash  

echo Installing NodeJS modules
npm install
npm install -g nodemon
echo Starting NodeJS
nodemon server.js
mkdir -p tmp