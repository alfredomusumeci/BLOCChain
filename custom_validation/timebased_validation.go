package timebased_validation

import (
	"fmt"
	"reflect"

	customvalidator "github.com/alfredom/fabric-samples/test-network-3-orgs/custom_validation/custom_validator"
	"github.com/hyperledger/fabric-protos-go/common"
	commonerrors "github.com/hyperledger/fabric/common/errors"
	"github.com/hyperledger/fabric/common/flogging"
	"github.com/hyperledger/fabric/core/committer/txvalidator/v20/plugindispatcher"
	validation "github.com/hyperledger/fabric/core/handlers/validation/api"
	vc "github.com/hyperledger/fabric/core/handlers/validation/api/capabilities"
	vi "github.com/hyperledger/fabric/core/handlers/validation/api/identities"
	vp "github.com/hyperledger/fabric/core/handlers/validation/api/policies"
	vs "github.com/hyperledger/fabric/core/handlers/validation/api/state"
	v12 "github.com/hyperledger/fabric/core/handlers/validation/builtin/v12"
	v13 "github.com/hyperledger/fabric/core/handlers/validation/builtin/v13"
	v20 "github.com/hyperledger/fabric/core/handlers/validation/builtin/v20"
	"github.com/pkg/errors"
)

var logger = flogging.MustGetLogger("timebased_validation")

type CustomValidationFactory struct {}

func (*CustomValidationFactory) New() validation.Plugin {
	return &CustomValidation{}
}

type CustomValidation struct {
	Capabilities	vc.Capabilities
	CustomTxValidator TransactionValidator
	TxValidatorV1_2 TransactionValidator
	TxValidatorV1_3 TransactionValidator
	TxValidatorV2_0 TransactionValidator
}

type TransactionValidator interface {
	Validate(block *common.Block, namespace string, txPosition int, actionPosition int, policy []byte) commonerrors.TxValidationError
}

func (cv *CustomValidation) Validate(block *common.Block, namespace string, txPosition int, actionPosition int, contextData ...validation.ContextDatum) error {
	if len(contextData) == 0 {
		logger.Panicf("Expected to receive policy bytes in context data")
	}

	serializedPolicy, isSerializedPolicy := contextData[0].(vp.SerializedPolicy)
	if !isSerializedPolicy {
		logger.Panicf("Expected to receive a serialized policy in the first context data")
	}
	if block == nil || block.Data == nil {
		return errors.New("empty block")
	}
	if txPosition >= len(block.Data.Data) {
		return errors.Errorf("block has only %d transactions, but requested tx at position %d", len(block.Data.Data), txPosition)
	}
	if block.Header == nil {
		return errors.Errorf("no block header")
	}

	var err error
	// switch {
	// //TODO: Add custom validation here
	// // Ideally, one should check if the incoming transaction updates the existing endorsement policy

	// case cv.Capabilities.V2_0Validation():
	// 	err = cv.TxValidatorV2_0.Validate(block, namespace, txPosition, actionPosition, serializedPolicy.Bytes())

	// case cv.Capabilities.V1_3Validation():
	// 	err = cv.TxValidatorV1_3.Validate(block, namespace, txPosition, actionPosition, serializedPolicy.Bytes())

	// case cv.Capabilities.V1_2Validation():
	// 	fallthrough

	// default:
	// 	err = cv.TxValidatorV1_2.Validate(block, namespace, txPosition, actionPosition, serializedPolicy.Bytes())
	// }
	err = cv.CustomTxValidator.Validate(block, namespace, txPosition, actionPosition, serializedPolicy.Bytes())

	logger.Debugf("block %d, namespace: %s, tx %d validation results is: %v", block.Header.Number, namespace, txPosition, err)
	return convertErrorTypeOrPanic(err)
}

func convertErrorTypeOrPanic(err error) error {
	if err == nil {
		return nil
	}
	if err, isExecutionError := err.(*commonerrors.VSCCExecutionFailureError); isExecutionError {
		return &validation.ExecutionFailureError{
			Reason: err.Error(),
		}
	}
	if err, isEndorsementError := err.(*commonerrors.VSCCEndorsementPolicyError); isEndorsementError {
		return err
	}
	logger.Panicf("Programming error: The error is %v, of type %v but expected to be either ExecutionFailureError or VSCCEndorsementPolicyError", err, reflect.TypeOf(err))
	return &validation.ExecutionFailureError{Reason: fmt.Sprintf("error of type %v returned from VSCC", reflect.TypeOf(err))}
}

func (cv *CustomValidation) Init(dependencies ...validation.Dependency) error {
	var (
		d vi.IdentityDeserializer
		c vc.Capabilities
		s vs.StateFetcher
		p vp.PolicyEvaluator
		cor plugindispatcher.CollectionResources
	)
	for _, dependency := range dependencies {
		if deserializer, isIdentityDeserializer := dependency.(vi.IdentityDeserializer); isIdentityDeserializer {
			d = deserializer
		}
		if capabilities, isCapabilities := dependency.(vc.Capabilities); isCapabilities {
			c = capabilities
		}
		if stateFetcher, isStateFetcher := dependency.(vs.StateFetcher); isStateFetcher {
			s = stateFetcher
		}
		if policyEvaluator, isPolicyEvaluator := dependency.(vp.PolicyEvaluator); isPolicyEvaluator {
			p = policyEvaluator
		}
	}

	if d == nil {
		return errors.New("CustomValidate: identity deserializer not provided")
	}
	if c == nil {
		return errors.New("CustomValidate: capabilities not provided")
	}
	if s == nil {
		return errors.New("CustomValidate: state fetcher not provided")
	}
	if p == nil {
		return errors.New("CustomValidate: policy evaluator not provided")
	}

	cv.Capabilities = c
	// cv.CustomTxValidator = cv.New(c, s, d, p)
	cv.CustomTxValidator = customvalidator.New(c, s, d, p, cor)
	cv.TxValidatorV1_2 = v12.New(c, s, d, p)
	cv.TxValidatorV1_3 = v13.New(c, s, d, p)
	cv.TxValidatorV2_0 = v20.New(c, s, d, p, cor)

	return nil
}

// func (cv *CustomValidation) Validate(block *common.Block, namespace string, txPosition int, actionPosition int, contextData ...ContextDatum) error {
// 	// Get tx and proposal
// 	env, err := protoutil.GetEnvelopeFromBlock(block.Data.Data[txPosition])
// 	if err != nil {
// 		return fmt.Errorf("CustomValidate: failed to get envelope from block: %v", err)
// 	}

// 	tx, err := protoutil.UnmarshalTransaction(env.Payload)
// 	if err != nil {
// 		return fmt.Errorf("CustomValidate: failed to get transaction from envelope: %v", err)
// 	}

// 	ccActionPayload, err := protoutil.UnmarshalChaincodeActionPayload(tx.Actions[actionPosition].Payload)
// 	if err != nil {
// 		return fmt.Errorf("CustomValidate: failed to get chaincode action payload: %v", err)
// 	}

// 	proposal, err := protoutil.UnmarshalProposal(ccActionPayload.ChaincodeProposalPayload.Input)
// 	if err != nil {
// 		return fmt.Errorf("CustomValidate: failed to get proposal: %v", err)
// 	}

// 	// Time based validation
// 	elapsedTime := time.Since(time.Unix((proposal.Header.GetTimestamp().Seconds), 0))
// 	threshold := 10 * time.Millisecond
// 	if elapsedTime > threshold {
// 		// Revert to leader-based validation
// 		return fmt.Errorf("CustomValidate: leader-based validation should kick here")
// 	}

// 	policyBytes := contextData[0].byte
// 	// Validate tx
// 	return t.policyEvaluator.Evaluate(policyBytes, protoutil.SignedDataArray{
//         {
//             Data:      env.Payload,
//             Identity:  chaincodeActionPayload.Action.Endorsements[0].Endorser,
//             Signature: chaincodeActionPayload.Action.Endorsements[0].Signature,
//         },
//     })
// }
	