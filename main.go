package main

import (
	"fmt"
	"os"

	"github.com/Sirupsen/logrus"
	"github.com/rancher/network-diagnostics-agent/infocollector"
	"github.com/urfave/cli"
)

// VERSION of the binary, that can be changed during build
var VERSION = "v0.0.0-dev"

func main() {
	app := cli.NewApp()
	app.Name = "network-diagnostics-agent"
	app.Version = VERSION
	app.Flags = []cli.Flag{
		cli.StringFlag{
			Name:  "metadata-url",
			Value: "http://rancher-metadata/2016-07-29",
		},
		cli.StringFlag{
			Name:  "backend",
			Value: "ipsec",
		},
		//cli.StringFlag{
		//	Name:  "ping-interval",
		//	Usage: fmt.Sprintf("Customize the interval between ping checks in milliseconds (default: %v)", ping.DefaultInterval),
		//	Value: "",
		//},
		cli.IntFlag{
			Name:  "info-collection-interval",
			Usage: fmt.Sprintf("Customize the interval of network info collection in milliseconds (default: %v)", infocollector.DefaultInterval),
			Value: infocollector.DefaultInterval,
		},
		cli.IntFlag{
			Name:  "info-history-length",
			Usage: fmt.Sprintf("number of infos to keep (default: %v)", infocollector.DefaultHistoryLength),
			Value: infocollector.DefaultHistoryLength,
		},
		cli.BoolFlag{
			Name:  "debug",
			Usage: "Turn on debug logging",
		},
	}
	app.Action = run
	app.Run(os.Args)
}

func run(c *cli.Context) error {
	if c.Bool("debug") {
		logrus.SetLevel(logrus.DebugLevel)
	}

	if err := infocollector.Start(c.Int("info-collection-interval"), c.Int("info-history-length"), c.String("backend")); err != nil {
		logrus.Errorf("Failed to start info collector: %v", err)
		return err
	}

	<-make(chan struct{})
	return nil
}
