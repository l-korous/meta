#!/bin/bash
# Add trailing slash
metaHome=$META_HOME
[[ "${metaHome}" != */ ]] && metaHome="${metaHome}/"
 
cp ${metaHome}main/target/html/*.html ${metaHome}main/target/js/public/app