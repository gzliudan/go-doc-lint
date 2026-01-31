package mixed

// ValidFunc does something valid
func ValidFunc() string {
	return "valid"
}

// invalid comment for CorrectFunc
func CorrectFunc() string {
	return "invalid comment"
}

// TODO: optimize this function
func OptimizeMe() {
	// This function has a TODO comment which should be ignored
}
