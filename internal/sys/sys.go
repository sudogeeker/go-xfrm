package sys

import (
	"bytes"
	"fmt"
	"os"
	"os/exec"
)

func IsRoot() bool {
	return os.Geteuid() == 0
}

func LookPath(name string) bool {
	_, err := exec.LookPath(name)
	return err == nil
}

func Output(name string, args ...string) (string, error) {
	cmd := exec.Command(name, args...)
	var out bytes.Buffer
	cmd.Stdout = &out
	cmd.Stderr = &out
	if err := cmd.Run(); err != nil {
		return out.String(), fmt.Errorf("%s: %w", out.String(), err)
	}
	return out.String(), nil
}

func Run(name string, args ...string) error {
	cmd := exec.Command(name, args...)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	cmd.Stdin = os.Stdin
	return cmd.Run()
}
