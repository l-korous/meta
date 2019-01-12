#!/bin/bash  

#cp -r resources/nodejs/* ${targetPath}js/
echo Installing NodeJS modules
npm install
echo Starting NodeJS
npm start
mkdir -p tmp