#!/bin/bash
# Add trailing slash
metaHome=$META_HOME
[[ "${metaHome}" != */ ]] && metaHome="${metaHome}/"
 
mkdir -p ${metaHome}main/target/js/public/app
mv ${metaHome}main/target/html/*.html ${metaHome}main/target/js/public/app
mv ${metaHome}main/target/html/*.js ${metaHome}main/target/js/public/app
mv ${metaHome}main/target/html/*.css ${metaHome}main/target/js/public/app