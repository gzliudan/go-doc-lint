package main

import "example.com/go-doc-lint-sample/pkg/greeter"

// Main is the entry point
func Main() {
	greeter.Hello("world")
}

func main() {
	Main()
}
