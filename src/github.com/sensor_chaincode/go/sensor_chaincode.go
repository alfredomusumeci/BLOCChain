package main

import (
	"fmt"
	"strconv"

	"github.com/hyperledger/fabric-chaincode-go/shim"
	sc "github.com/hyperledger/fabric-protos-go/peer"
	"github.com/hyperledger/fabric/common/flogging"
)

type SensorChaincode struct {
}

// Init ; initialize the chaincode
func (s *SensorChaincode) Init(APIstub shim.ChaincodeStubInterface) sc.Response {
	return shim.Success(nil)
}

var logger = flogging.MustGetLogger("sensor_chaincode")

// Invoke ; invoke the chaincode
func (s *SensorChaincode) Invoke(APIstub shim.ChaincodeStubInterface) sc.Response {
	// Retrieve the requested Smart Contract function and arguments
	function, args := APIstub.GetFunctionAndParameters()
	
	logger.Info("Function: " + function)
	logger.Info("Args: " + args[0])

	// Route to the appropriate handler function to interact with the ledger appropriately
	switch function {
		case "processSensorData":
			return s.processSensorData(APIstub, args)
		default:
			return shim.Error("Invalid Smart Contract function name.")
	}
}

func (s *SensorChaincode) processSensorData(APIstub shim.ChaincodeStubInterface, args []string) sc.Response {
	if len(args) != 2 {
		return shim.Error("Incorrect number of arguments. Expecting 2")
	}

	sensorID := args[0]
	sensorData, err := strconv.Atoi(args[1])
	if err != nil {
		return shim.Error("Expecting integer value but got " + args[1])
	}

	// Process the sensor data and return the result
	result := fmt.Sprintf("Sensor ID: %s, Sensor Data: %d", sensorID, sensorData)
	return shim.Success([]byte(result))
}

// main ; main is only relevant in unit test mode. Only included here for completeness.
func main() {
	// Create a new Smart Contract
	err := shim.Start(new(SensorChaincode))
	if err != nil {
		fmt.Printf("Error starting chaincode: %s", err)
	}
}
