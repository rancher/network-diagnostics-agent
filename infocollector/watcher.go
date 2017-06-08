package infocollector

import (
	"fmt"
	"os"
	"os/exec"
	"time"

	"github.com/Sirupsen/logrus"
)

var (
	// DefaultInterval specifies the default value for network info collection
	// interval in milliseconds
	DefaultInterval = 10 * 60 * 1000 // Every 10 minutes

	// DefaultHistoryLength specifies the default value for the number of
	// historical information to keep.
	DefaultHistoryLength = 1000
)

// InfoCollector collects various networking info
type InfoCollector struct {
	interval      time.Duration
	historyLength int
	backend       string
	lastApplied   time.Time
}

// Start ...
func Start(interval, historyLength int, backend string) error {
	logrus.Infof("infocollector: Starting with interval: %v milliseconds history: %v", interval, historyLength)
	ic := &InfoCollector{
		interval:      time.Duration(interval) * time.Millisecond,
		historyLength: historyLength,
		backend:       backend,
	}

	go ic.doWork()

	return nil
}

func (ic *InfoCollector) doWork() {
	for {
		if err := ic.collect(); err != nil {
			logrus.Errorf("infocollector: error collecting logs: %v", err)
		}
		time.Sleep(ic.interval)
	}
}

func (ic *InfoCollector) collect() error {
	logrus.Debugf("infocollector: collecting information")

	cmd := exec.Command(
		fmt.Sprintf("collect-info-%v.sh", ic.backend),
		"/logs",
		fmt.Sprintf("%v", ic.historyLength),
	)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	return cmd.Run()
}
