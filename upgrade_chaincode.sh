peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --channelID mychannel\
 --signature-policy "OR(AND('Org1MSP.peer', 'Org2MSP.peer'), 'Org1MSP.peer')" --name sensor_chaincode --version 1.0 --package-id $CC_PACKAGE_ID\
 --sequence 5 --init-required --tls --cafile "${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem"

peer lifecycle chaincode checkcommitreadiness --channelID mychannel --signature-policy "OR(AND('Org1MSP.peer'), 'Org1MSP.peer')"\
 --name sensor_chaincode --version 1.0 --sequence 5 --init-required --tls \
 --cafile "${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem" --output json

peer lifecycle chaincode commit -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --channelID mychannel\
 --signature-policy "OR(AND('Org1MSP.peer'), 'Org1MSP.peer')" --name sensor_chaincode --version 1.0 --sequence 5\
 --init-required --tls --cafile "${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem"\
 --peerAddresses localhost:7051 --tlsRootCertFiles "${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt"
