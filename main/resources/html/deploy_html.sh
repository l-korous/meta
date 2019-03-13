#!/bin/bash
# Add trailing slash
metaHome=$META_HOME
[[ "${metaHome}" != */ ]] && metaHome="${metaHome}/"
 
mkdir -p ${metaHome}main/target/js/public/app
cp ${metaHome}main/target/html/*.html ${metaHome}main/target/js/public/app