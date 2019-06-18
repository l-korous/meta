#!/bin/bash  
# === Setup ===
# SQL credentials (! no quotes)
sqlCredentials="-S LK-HP-NEW\\SQLEXPRESS"
# =================

if [ $# -lt 2 ] 
then
    echo "usage: csv_to_xml.sh <csvInputRoot> <xmlOutputFileName>"
    exit
fi

# Add trailing slash
path=$1
[[ "${path}" != */ ]] && path="${path}/"

# Put proper paths into the SQL
sqlScript="`cat csv_to_xml.sql`"
sqlScript="${sqlScript//tableCsv/\"${path}tables.csv\"}"
sqlScript="${sqlScript//colCsv/\"${path}columns.csv\"}"
sqlScript="${sqlScript//refCsv/\"${path}references.csv\"}"
sqlScript="${sqlScript//confCsv/\"${path}configuration.csv\"}"

if [[ "$OSTYPE" == "linux-gnu" ]]; then
    bcp "${sqlScript}" queryout $2 -c -T $sqlCredentials
else
    winpty bcp "${sqlScript}" queryout $2 -c -T $sqlCredentials
fi
