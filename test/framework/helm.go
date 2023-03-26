package framework

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
)

func (f *Framework) GetWorkingDir() (string, error) {
	pwd, err := os.Getwd()
	if err != nil {
		return "", fmt.Errorf("failed to get working directory: %v", err)
	}

	return filepath.Abs(pwd + "/../../")
}

func (f *Framework) InstallChart(dir, name string, args ...string) error {
	pwd, err := f.GetWorkingDir()
	if err != nil {
		return err
	}

	args = append([]string{"install", name, ".", "-n", f.config.Namespace}, args...)
	cmd := exec.Command("helm", args...)
	cmd.Dir = pwd + "/charts/" + dir
	output, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("failed to install %s release: %v, output: %s", name, err, string(output))
	}

	return nil
}

func (f *Framework) UninstallChart(name string) error {
	cmd := exec.Command("helm", "uninstall", name, "-n", f.config.Namespace)
	output, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("failed to uninstall %s release: %v, output: %s", name, err, string(output))
	}

	return nil
}
