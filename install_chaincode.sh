# HLF Related
export FABRIC_CFG_PATH=${PWD}/../config/
export PEER0_ORG1_CA=${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export PEER0_ORG2_CA=${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
export ORDERER_CA=${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem

### Chaincode ###
CHANNEL_NAME="mychannel"
CC_RUNTIME_LANGUAGE="golang"
CC_SRC_PATH="${PWD}/src/github.com/sensor_chaincode/go/"
CC_NAME="sensor_chaincode"
CC_VERSION="1.0"
CC_SEQUENCE=1
CC_VALID_PLUGIN="vscc"
CC_POLICY="AND('Org1MSP.peer','Org2MSP.peer')"

### Utils ###
setGlobalsForPeer0Org1() {
  echo "Setting globals for peer0.org1.example.com"
  export CORE_PEER_TLS_ENABLED=true
  export CORE_PEER_LOCALMSPID="Org1MSP"
  export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG1_CA
  export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
  export CORE_PEER_ADDRESS=localhost:7051
}

setGlobalsForPeer0Org2() {
  echo "Setting globals for peer0.org2.example.com"
  export CORE_PEER_TLS_ENABLED=true
  export CORE_PEER_LOCALMSPID="Org2MSP"
  export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG2_CA
  export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
  export CORE_PEER_ADDRESS=localhost:9051
}
### End Utils ###

presetup() {
  echo "Vendoring Go dependencies ..."
  # shellcheck disable=SC2164
  pushd ./src/github.com/sensor_chaincode/go
  GO111MODULE=on go mod vendor
  # shellcheck disable=SC2164
  popd
  echo "Finished vendoring Go dependencies"
}

packageChaincode() {
  echo "Packaging chaincode ..."

  # Remove old chaincode package
  rm -rf sensor_chaincode.tar.gz

  peer lifecycle chaincode package ${CC_NAME}.tar.gz \
    --path "${CC_SRC_PATH}" \
    --lang ${CC_RUNTIME_LANGUAGE} \
    --label ${CC_NAME}_${CC_VERSION}
  echo "Finished packaging chaincode"
}

installChaincode() {
  echo "Installing chaincode on peer0.org1.example.com ..."

  setGlobalsForPeer0Org1
  peer lifecycle chaincode install ${CC_NAME}.tar.gz
  echo "Finished installing chaincode on peer0.org1.example.com"

  setGlobalsForPeer0Org2
  echo "Installing chaincode on peer0.org2.example.com ..."
  peer lifecycle chaincode install ${CC_NAME}.tar.gz
  echo "Finished installing chaincode on peer0.org2.example.com"
}

getPackageId() {
  echo "Getting package ID ..."
  CC_PACKAGE_ID=$(peer lifecycle chaincode queryinstalled | sed -n "/${CC_NAME}_${CC_VERSION}/{s/^Package ID: //; s/, Label:.*$//; p;}")
  echo "Package ID is ${CC_PACKAGE_ID}"
}

approveForMyOrgs() {
  echo "Approving chaincode definition for my orgs ..."
  setGlobalsForPeer0Org1
  peer lifecycle chaincode approveformyorg \
    -o localhost:7050 \
    --ordererTLSHostnameOverride orderer.example.com \
    --channelID ${CHANNEL_NAME} \
    --name ${CC_NAME} \
    --version ${CC_VERSION} \
    --package-id "${CC_PACKAGE_ID}" \
    --sequence ${CC_SEQUENCE} \
    --init-required \
    --tls \
    --cafile "$ORDERER_CA" \
    --signature-policy ${CC_POLICY} \
    --validation-plugin ${CC_VALID_PLUGIN}

  setGlobalsForPeer0Org2
  peer lifecycle chaincode approveformyorg \
    --orderer localhost:7050 \
    --ordererTLSHostnameOverride orderer.example.com \
    --channelID ${CHANNEL_NAME} \
    --name ${CC_NAME} \
    --version ${CC_VERSION} \
    --package-id "${CC_PACKAGE_ID}" \
    --sequence ${CC_SEQUENCE} \
    --init-required \
    --tls \
    --cafile "$ORDERER_CA" \
    --signature-policy ${CC_POLICY} \
    --validation-plugin ${CC_VALID_PLUGIN}
  echo "Finished approving chaincode definition for my orgs"
}

checkCommitReadiness() {
  echo "Checking commit readiness ..."
  peer lifecycle chaincode checkcommitreadiness \
    --channelID ${CHANNEL_NAME} \
    --name ${CC_NAME} \
    --version ${CC_VERSION} \
    --sequence ${CC_SEQUENCE} \
    --init-required \
    --tls \
    --cafile "$ORDERER_CA" \
    --signature-policy ${CC_POLICY} \
    --validation-plugin ${CC_VALID_PLUGIN} \
    --output json
  echo "Finished checking commit readiness"
}

commitChaincode() {
  echo "Committing chaincode definition ..."
  peer lifecycle chaincode commit \
    -o localhost:7050 \
    --ordererTLSHostnameOverride orderer.example.com \
    --channelID ${CHANNEL_NAME} \
    --name ${CC_NAME} \
    --version ${CC_VERSION} \
    --sequence ${CC_SEQUENCE} \
    --init-required \
    --tls \
    --cafile "$ORDERER_CA" \
    --signature-policy ${CC_POLICY} \
    --validation-plugin ${CC_VALID_PLUGIN} \
    --peerAddresses localhost:7051 \
    --tlsRootCertFiles "$PEER0_ORG1_CA" \
    --peerAddresses localhost:9051 \
    --tlsRootCertFiles "$PEER0_ORG2_CA"
  echo "Finished committing chaincode definition"
}

queryCommitted() {
  echo "Querying chaincode definition ..."
  peer lifecycle chaincode querycommitted \
    --channelID ${CHANNEL_NAME} \
    --name ${CC_NAME}
  echo "Finished querying chaincode definition"
}

chaincodeInvokeInit() {
  echo "Initializing with Init transaction"
  setGlobalsForPeer0Org1
  peer chaincode invoke \
    -o localhost:7050 \
    --ordererTLSHostnameOverride orderer.example.com \
    --tls \
    --cafile "$ORDERER_CA" \
    -C ${CHANNEL_NAME} \
    -n ${CC_NAME} \
    --isInit \
    --peerAddresses localhost:7051 \
    --tlsRootCertFiles "$PEER0_ORG1_CA" \
    --peerAddresses localhost:9051 \
    --tlsRootCertFiles "$PEER0_ORG2_CA" \
    -c '{"function":"Init","Args":[]}'
}

chaincodeInvokeProcessSensorData() {
  echo "Invoking transaction"
  peer chaincode invoke \
    -o localhost:7050 \
    --ordererTLSHostnameOverride orderer.example.com \
    --tls \
    --cafile "$ORDERER_CA" \
    -C ${CHANNEL_NAME} \
    -n ${CC_NAME} \
    --peerAddresses localhost:7051 \
    --tlsRootCertFiles "$PEER0_ORG1_CA" \
    -c '{"function":"processSensorData","Args":["sensor15","10"]}'

#    --peerAddresses localhost:9051 \
#    --tlsRootCertFiles "$PEER0_ORG2_CA" \
}

# Installing chaincode all together
chainCodeInstallAndDeploy() {
  presetup
  packageChaincode
  installChaincode
  getPackageId
  approveForMyOrgs
  checkCommitReadiness
  commitChaincode
  queryCommitted
  chaincodeInvokeInit
}

# Only upgrade chaincode
chainCodeUpgrade() {
  presetup
  getPackageId
  approveForMyOrgs
  checkCommitReadiness
  commitChaincode
  queryCommitted
}

# Only invoke chaincode
chainCodeInvoke() {
  chaincodeInvokeProcessSensorData
}

# Choose according to arguments passed when invoking script
if [ "$1" == "install" ]; then
  chainCodeInstallAndDeploy
elif [ "$1" == "upgrade" ]; then
  chainCodeUpgrade
elif [ "$1" == "invoke" ]; then
  chainCodeInvoke
else
  echo "Invalid argument. Expecting one of: install, upgrade, invoke"
fi
