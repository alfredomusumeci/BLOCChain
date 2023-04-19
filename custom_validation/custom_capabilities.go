type CustomCapabilities interface {
	// The standard capabilities interface
	vc.Capabilities

	// VCust returns true if this channel supports custom validation for endorsement policy updates
	VCust() bool
}
