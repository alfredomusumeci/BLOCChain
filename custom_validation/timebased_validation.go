package timebased_validation

import (
	"fmt"
	"time"

	"github.com/alfredom/fabric-samples/test-network-3-orgs/src/github.com/sensor_app/go/vendor/github.com/hyperledger/fabric-sdk-go/internal/github.com/hyperledger/fabric/protoutil"
	"github.com/hyperledger/fabric-protos-go/common"
	"github.com/hyperledger/fabric/core/handlers/validation/api"
	"github.com/hyperledger/fabric/core/handlers/validation/api/capabilities"
	"github.com/hyperledger/fabric/core/handlers/validation/api/identities"
	"github.com/hyperledger/fabric/core/handlers/validation/api/policies"
	"github.com/hyperledger/fabric/core/handlers/validation/api/state"
	"github.com/hyperledger/fabric/protoutil"
)

type TimeBasedValidationPlugin struct {
	policyEvaluator policies.PolicyEvaluator
	deserializer    identities.Deserializer
	capabilities	capabilities.Capabilities
	stateFetcher	state.StateFetcher
}

func (t *TimeBasedValidationPlugin) Init(dependencies ...validation.Dependency) error {
	for _, dep := range dependencies {
		switch v := dep.(type) {
		case policies.PolicyEvaluator:
			t.policyEvaluator = v
		case identities.Deserializer:
			t.deserializer = v
		case capabilities.Capabilities:
			t.capabilities = v
		case state.StateFetcher:
			t.stateFetcher = v
		}
	}
	return nil
}

func (t *TimeBasedValidationPlugin) Validate(block *common.Block, namespace string, txPosition int, actionPosition int, contextData ...validation.ContextDatum) error {
	// Get tx and proposal
	env, err := protoutil.GetEnvelopeFromBlock(block.Data.Data[txPosition])
	if err != nil {
		return fmt.Errorf("CustomValidate: failed to get envelope from block: %v", err)
	}

	tx, err := protoutil.UnmarshalTransaction(env.Payload)
	if err != nil {
		return fmt.Errorf("CustomValidate: failed to get transaction from envelope: %v", err)
	}

	ccActionPayload, err := protoutil.UnmarshalChaincodeActionPayload(tx.Actions[actionPosition].Payload)
	if err != nil {
		return fmt.Errorf("CustomValidate: failed to get chaincode action payload: %v", err)
	}

	proposal, err := protoutil.UnmarshalProposal(ccActionPayload.ChaincodeProposalPayload.Input)
	if err != nil {
		return fmt.Errorf("CustomValidate: failed to get proposal: %v", err)
	}

	// Time based validation
	elapsedTime := time.Since(time.Unix((proposal.Header.GetTimestamp().Seconds), 0))
	threshold := 10 * time.Millisecond
	if elapsedTime > threshold {
		// Revert to leader-based validation
		return fmt.Errorf("CustomValidate: leader-based validation should kick here")
	}

	policyBytes := contextData[0].policyBytes
	// Validate tx
	return t.policyEvaluator.Evaluate(policyBytes, protoutil.SignedDataArray{
        {
            Data:      env.Payload,
            Identity:  chaincodeActionPayload.Action.Endorsements[0].Endorser,
            Signature: chaincodeActionPayload.Action.Endorsements[0].Signature,
        },
    })
}
	