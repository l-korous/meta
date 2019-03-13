#!/bin/bash  
#=================
# Add trailing slash
metaHome=$META_HOME
[[ "${metaHome}" != */ ]] && metaHome="${metaHome}/"

(cd ${metaHome}main/target/js && ./run_nodejs.sh)
