package invalid

import "testing"

// test reads data
func TestReadData(t *testing.T) {
	_, err := ReadData("test")
	if err != nil {
		t.Fail()
	}
}

// Wrong comment here
func TestWriteData(t *testing.T) {
	err := WriteData("test", []byte("data"))
	if err != nil {
		t.Fail()
	}
}
