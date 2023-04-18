# Do manual edits to config.json using a text editor

# Convert back to protobuf
configtxlator proto_encode --input config.json --type common.Config --output config.pb
configtxlator proto_encode --input modified_config.json --type common.Config --output modified_config.pb

# Compute a config update, based on the differences between config.json and modified_config.json:
configtxlator compute_update --channel_id mychannel --original config.pb --updated modified_config.pb --output config_update.pb

# Convert into ConfigUpdate
configtxlator proto_decode --input config_update.pb --type common.ConfigUpdate --output config_update.json

# Create ConfigUpdateEnvelope
echo '{"payload":{"header":{"channel_header":{"channel_id":"mychannel", "type":2}},"data":{"config_update":'$(cat config_update.json)'}}}' | jq . > config_update_unsigned_envelope.json

# Convert back to protobuf for signing
configtxlator proto_encode --input config_update_unsigned_envelope.json --type common.Envelope --output config_update_unsigned_envelope.pb

# Sign the config update as Org1 admin
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_ADDRESS=localhost:7051
peer channel signconfigtx -f config_update_unsigned_envelope.pb

# Sign the config update as Org2 admin
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="Org2MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
export CORE_PEER_ADDRESS=localhost:9051
peer channel signconfigtx -f config_update_unsigned_envelope.pb

# Back to JSON
configtxlator proto_decode --input config_update_unsigned_envelope.pb --type common.Envelope --output config_update_in_envelope.json

# Convert to protobuf
configtxlator proto_encode --input config_update_in_envelope.json --type common.Envelope --output config_update_in_envelope.pb

# Submit the config update
peer channel update -f config_update_in_envelope.pb -c mychannel -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem"

# Verify the new config
# peer channel fetch config config_block.pb -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com -c mychannel --tls --cafile "${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem"
# configtxlator proto_decode --input config_block.pb --type common.Block | jq .data.data[0].payload.data.config > config.json
# cat config.json | jq .channel_group.groups.Application.groups