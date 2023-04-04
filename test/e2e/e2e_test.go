package e2e

import (
	"testing"

	"github.com/onsi/ginkgo/v2"
	"github.com/onsi/gomega"

	"github.com/api7/api7-helm-chart/test/framework"
	"github.com/api7/api7-helm-chart/test/setup"
)

// TestHelmChart is the entry point for the E2E test.
func TestHelmChart(t *testing.T) {
	gomega.RegisterFailHandler(ginkgo.Fail)
	f := framework.GetGlobalFramework()

	ginkgo.BeforeSuite(func() {
		// deploy Dashboard
		err := setup.DeployDashboard(f)
		gomega.Expect(err).Should(gomega.BeNil())
		err = setup.EnsureDashboardReady(f)
		gomega.Expect(err).Should(gomega.BeNil())
		setup.CreateTunnelForDashboard(f)

		// admin login
		token := setup.LoginDashboard(f)
		// import license
		setup.ImportLicense(f, token)
		// create default cluster
		setup.CreateDefaultCluster(f, token)
		// create default workspace
		setup.CreateDefaultWorkspace(f, token)
	})

	ginkgo.AfterSuite(func() {
		err := setup.UninstallDashboard(f)
		gomega.Expect(err).Should(gomega.BeNil())

		f.CleanUp()
	})

	ginkgo.RunSpecs(t, "E2E test suites")
}
