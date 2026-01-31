package valid

import "testing"

// TestReadData tests the ReadData function
func TestReadData(t *testing.T) {
	_, err := ReadData("test")
	if err != nil {
		t.Fail()
	}
}

// TestWriteData tests the WriteData function
func TestWriteData(t *testing.T) {
	err := WriteData("test", []byte("data"))
	if err != nil {
		t.Fail()
	}
}
