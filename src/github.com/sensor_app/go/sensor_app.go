package main

import (
	"fmt"
	"io/ioutil"

	"github.com/hyperledger/fabric-sdk-go/pkg/core/config"
	"github.com/hyperledger/fabric-sdk-go/pkg/gateway"
)

func readSensorData() int {
	// dummy data; to be replaced by actual sensor data
	return 30
}

func main() {
	// Reading the cert and key files for the Proposer.
	certPath := "/home/alfredo/go/src/github.com/alfredom/fabric-samples/test-network-3-orgs/explorer/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/signcerts/Admin@org1.example.com-cert.pem"
	keyPath := "/home/alfredo/go/src/github.com/alfredom/fabric-samples/test-network-3-orgs/explorer/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/keystore/priv_sk"
	certBytes, err := ioutil.ReadFile(certPath)
	if err != nil {
		fmt.Printf("Failed to read cert file: %v\n", err)
	}
	keyBytes, err := ioutil.ReadFile(keyPath)
	if err != nil {
		fmt.Printf("Failed to read key file: %v\n", err)
	}

	// This is the identity of the user who is submitting the transactions or performing the queries.
	id := gateway.NewX509Identity("Org1MSP", string(certBytes), string(keyBytes))
	wallet := gateway.NewInMemoryWallet()
	wallet.Put("Admin", id)

	// Initialise the gateway using the connection profile for the network
	connectionProfilePath := "/home/alfredo/go/src/github.com/alfredom/fabric-samples/test-network-3-orgs/connection-profile-debug.yaml"
	gw, err := gateway.Connect(
		gateway.WithConfig(config.FromFile(connectionProfilePath)),
		gateway.WithIdentity(wallet, "Admin"),
	)
	if err != nil {
		fmt.Printf("Failed to connect to gateway: %v\n", err)
		return
	}
	defer gw.Close()

	// Obtain a smart contract for the channel
	network, err := gw.GetNetwork("mychannel")
	if err != nil {
		fmt.Printf("Failed to get network: %v\n", err)
		return
	}
	contract := network.GetContract("sensor_chaincode")

	// Invoke the chaincode & submit the transaction
	sensorData := readSensorData()

	response, err := contract.SubmitTransaction("processSensorData", "sensor1", fmt.Sprintf("%d", sensorData))
	if err != nil {
		fmt.Printf("Failed to submit transaction: %v\n", err)
		return
	}

	fmt.Printf("Transaction successful: %s\n", string(response))
}
