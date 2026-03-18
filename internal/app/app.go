package app

import (
	"errors"
	"flag"
	"os"

	"github.com/sudogeeker/tunnel-helper/internal/sys"
	"github.com/sudogeeker/tunnel-helper/internal/ui"
)

func Run(args []string) error {
	fs := flag.NewFlagSet("tunnel-helper", flag.ContinueOnError)
	confDir := fs.String("confdir", "/etc/swanctl/conf.d", "swanctl config directory")
	if err := fs.Parse(args); err != nil {
		return err
	}

	uiOut := ui.New(os.Stdout, os.Stderr, os.Stdin)
	prompter := ui.NewPrompter(uiOut)

	if runtimeWarn := runtimeCheck(); runtimeWarn != nil {
		uiOut.Warn(runtimeWarn.Error())
	}

	if !sys.IsRoot() {
		return errors.New("run as root (sudo -i)")
	}

	if err := requireCommands(uiOut, "ip"); err != nil {
		return err
	}

	tunnelType := "1"
	options := []ui.Option{
		{Label: "1) XFRM (IPsec/IKEv2 via strongSwan)", Value: "1"},
		{Label: "2) WireGuard", Value: "2"},
		{Label: "3) AmneziaWG", Value: "3"},
		{Label: "4) VXLAN", Value: "4"},
		{Label: "5) GRE", Value: "5"},
		{Label: "6) Manage existing tunnels", Value: "6"},
	}

	uiOut.HR()
	uiOut.Title("tunnel-helper - VPN / Tunnel Generator")
	uiOut.HR()
	if err := askSelectRaw(prompter, "Tunnel type", options, &tunnelType); err != nil {
		return wrapAbort(err)
	}

	switch tunnelType {
	case "1":
		return runXFRM(uiOut, prompter, *confDir)
	case "2":
		return runWireguard(uiOut, prompter)
	case "3":
		return runAmneziaWG(uiOut, prompter)
	case "4":
		return runVXLAN(uiOut, prompter)
	case "5":
		return runGRE(uiOut, prompter)
	case "6":
		return runManager(uiOut, prompter, *confDir)
	}

	return nil
}
