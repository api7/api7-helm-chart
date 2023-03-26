package setup

import (
	"bytes"
	"fmt"
	"io"
	"mime/multipart"
	"net/http"
	"net/url"
	"os"

	"github.com/bitly/go-simplejson"
	"github.com/onsi/gomega"

	"github.com/api7/api7-helm-chart/test/framework"
)

var (
	dashboardToken     string
	dashboardPodName   string
	dashboardChartName = "api7-dashboard"
)

func DeployDashboard(f *framework.Framework) error {
	pwd, err := f.GetWorkingDir()
	if err != nil {
		return err
	}

	return f.InstallChart(dashboardChartName, dashboardChartName,
		"--set", "image.registry=api7ee.azurecr.io",
		"--set", "image.repository=api7-dashboard",
		"--set", "image.tag=2.13.2302",
		"--post-renderer", pwd+"/charts/api7-dashboard/kustomize/kustomize")
}

func UninstallDashboard(f *framework.Framework) error {
	return f.UninstallChart(dashboardChartName)
}

func EnsureDashboardReady(f *framework.Framework) error {
	pod, err := f.GetPodByNamePrefix(dashboardChartName)
	if err != nil {
		return err
	}
	dashboardPodName = pod.Name

	err = f.WaitAllPodsAvailable(fmt.Sprintf("name=%s", dashboardPodName))
	if err != nil {
		return err
	}

	err = f.EnsureService(dashboardChartName, 1)
	if err != nil {
		return err
	}

	return nil
}

func CreateTunnelForDashboard(f *framework.Framework) {
	f.CreateTunnelForService(dashboardChartName, dashboardChartName, 9000)
}

func GetDashboardEndpoint(f *framework.Framework) *url.URL {
	return f.GetPodEndpoint(dashboardChartName)
}

func LoginDashboard(f *framework.Framework) string {
	if dashboardToken != "" {
		return dashboardToken
	}

	requestBody := `{
		"username": "admin",
		"password": "admin"
	}`

	epUrl := GetDashboardEndpoint(f)
	epUrl.Path = "/apisix/admin/user/login"
	req, err := http.NewRequest(http.MethodPost, epUrl.String(), bytes.NewBufferString(requestBody))
	gomega.Expect(err).To(gomega.BeNil())

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		panic(err)
	}
	defer resp.Body.Close()
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		panic(err)
	}

	js, err := simplejson.NewJson(body)
	if err != nil {
		panic(err)
	}

	dashboardToken = js.Get("data").Get("token").MustString()

	return dashboardToken
}

func ImportLicense(f *framework.Framework, token string) {
	bodyBuffer := &bytes.Buffer{}
	bodyWriter := multipart.NewWriter(bodyBuffer)
	fileWriter, err := bodyWriter.CreateFormFile("file", "license")
	gomega.Expect(err).To(gomega.BeNil())

	file, err := os.Open("testdata/certs/license")
	gomega.Expect(err).To(gomega.BeNil())
	defer file.Close()
	io.Copy(fileWriter, file)

	contentType := bodyWriter.FormDataContentType()
	bodyWriter.Close()

	epUrl := GetDashboardEndpoint(f)
	epUrl.Path = "/apisix/admin/license"
	req, err := http.NewRequest(http.MethodPut, epUrl.String(), bodyBuffer)
	gomega.Expect(err).To(gomega.BeNil())

	req.Header.Add("Authorization", token)
	req.Header.Set("Content-Type", contentType)

	client := &http.Client{}
	resp, err := client.Do(req)
	gomega.Expect(err).To(gomega.BeNil())
	gomega.Expect(resp.StatusCode).Should(gomega.Equal(http.StatusOK))
}

func CreateDefaultCluster(f *framework.Framework, token string) {
	epUrl := GetDashboardEndpoint(f)
	epUrl.Path = "/apisix/admin/clusters"
	body := []byte(`{
		"id": "cluster1",
		"name": "cluster1",
		"etcd_cluster_id": "system-default-etcd-cluster"
	}`)
	req, err := http.NewRequest(http.MethodPost, epUrl.String(), bytes.NewBuffer(body))
	gomega.Expect(err).To(gomega.BeNil())

	req.Header.Add("Authorization", token)
	req.Header.Set("Content-Type", "application/json")
	client := &http.Client{}
	resp, err := client.Do(req)
	gomega.Expect(err).To(gomega.BeNil())
	gomega.Expect(resp.StatusCode).Should(gomega.Equal(http.StatusOK))
}

func CreateDefaultWorkspace(f *framework.Framework, token string) {
	epUrl := GetDashboardEndpoint(f)
	epUrl.Path = "/apisix/admin/workspaces"
	epUrl.RawQuery = "cluster_id=cluster1"
	body := []byte(`{
		"id": "workspace1",
		"name": "workspace1",
		"hosts": ["foo.com"]
	}`)

	req, err := http.NewRequest(http.MethodPost, epUrl.String(), bytes.NewBuffer(body))
	gomega.Expect(err).To(gomega.BeNil())

	req.Header.Add("Authorization", token)
	req.Header.Set("Content-Type", "application/json")
	client := &http.Client{}
	resp, err := client.Do(req)
	gomega.Expect(err).To(gomega.BeNil())
	gomega.Expect(resp.StatusCode).Should(gomega.Equal(http.StatusOK))
}
