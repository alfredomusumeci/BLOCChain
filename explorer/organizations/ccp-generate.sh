#!/bin/bash

# This script defines three Bash functions and sets some variables to create two JSON and two YAML files that contain connection information
# for two organizations, org1.example.com and org2.example.com, in a Hyperledger Fabric network. Here is what each function does:

# one_line_pem function: This function takes a single argument, which is a path to a PEM file. The function removes newlines from the PEM file
# and replaces them with \\\n, which is a newline character with a backslash escape sequence. The function then echoes the modified PEM file
# contents.

# json_ccp function: This function takes five arguments: $1 is the organization name, $2 is the peer port number, $3 is the CA port number,
# $4 is the path to the peer's PEM file, and $5 is the path to the CA's PEM file. The function reads the organizations/ccp-template.json file,
# which contains a template for a JSON-formatted connection profile for a Hyperledger Fabric network. The function replaces placeholders in the
# template with the values of the five arguments, using the sed command. The function also uses the one_line_pem function to convert the PEM
# files into single-line strings before inserting them into the template. Finally, the function echoes the modified template.

# yaml_ccp function: This function is similar to json_ccp, but it reads the organizations/ccp-template.yaml file, which contains a template
# for a YAML-formatted connection profile. The function replaces placeholders in the template with the values of the five arguments, using 
# the sed command. The function also uses the one_line_pem function to convert the PEM files into single-line strings before inserting them
# into the template. However, this function also replaces the literal string \n with a newline character (\n) and eight spaces to improve
# the indentation in the resulting YAML file. Finally, the function echoes the modified template.

# After defining the three functions, the script sets some variables (ORG, P0PORT, CAPORT, PEERPEM, and CAPEM) to specify the connection
# information for two organizations in a Hyperledger Fabric network. The script then calls the json_ccp and yaml_ccp functions with different
# arguments to generate two JSON and two YAML files (connection-org1.json, connection-org1.yaml, connection-org2.json, and connection-org2.yaml)
# that contain the connection information for the two organizations. The generated files are saved in the 
# organizations/peerOrganizations/org1.example.com and organizations/peerOrganizations/org2.example.com directories.

function one_line_pem {
    echo "`awk 'NF {sub(/\\n/, ""); printf "%s\\\\\\\n",$0;}' $1`"
}

function json_ccp {
    local PP=$(one_line_pem $4)
    local CP=$(one_line_pem $5)
    sed -e "s/\${ORG}/$1/" \
        -e "s/\${P0PORT}/$2/" \
        -e "s/\${CAPORT}/$3/" \
        -e "s#\${PEERPEM}#$PP#" \
        -e "s#\${CAPEM}#$CP#" \
        organizations/ccp-template.json
}

function yaml_ccp {
    local PP=$(one_line_pem $4)
    local CP=$(one_line_pem $5)
    sed -e "s/\${ORG}/$1/" \
        -e "s/\${P0PORT}/$2/" \
        -e "s/\${CAPORT}/$3/" \
        -e "s#\${PEERPEM}#$PP#" \
        -e "s#\${CAPEM}#$CP#" \
        organizations/ccp-template.yaml | sed -e $'s/\\\\n/\\\n          /g'
}

ORG=1
P0PORT=7051
CAPORT=7054
PEERPEM=organizations/peerOrganizations/org1.example.com/tlsca/tlsca.org1.example.com-cert.pem
CAPEM=organizations/peerOrganizations/org1.example.com/ca/ca.org1.example.com-cert.pem

echo "$(json_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/org1.example.com/connection-org1.json
echo "$(yaml_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/org1.example.com/connection-org1.yaml

ORG=2
P0PORT=9051
CAPORT=8054
PEERPEM=organizations/peerOrganizations/org2.example.com/tlsca/tlsca.org2.example.com-cert.pem
CAPEM=organizations/peerOrganizations/org2.example.com/ca/ca.org2.example.com-cert.pem

echo "$(json_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/org2.example.com/connection-org2.json
echo "$(yaml_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/org2.example.com/connection-org2.yaml
