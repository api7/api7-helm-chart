package framework

import (
	"bufio"
	"context"
	"net/url"
	"strings"
	"sync"
	"time"

	"github.com/gruntwork-io/terratest/modules/k8s"
	"github.com/onsi/ginkgo/v2"
	"github.com/onsi/gomega"
	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/kubernetes"
	restclient "k8s.io/client-go/rest"
	"k8s.io/client-go/tools/clientcmd"
)

var (
	_globalFramework *Framework
	_globalOnce      sync.Once
)

// Framework is the framework for e2e tests.
type Framework struct {
	GomegaT *gomega.GomegaWithT
	GinkgoT ginkgo.GinkgoTInterface

	Render *rendering
	config *Config

	clientset   *kubernetes.Clientset
	clientCfg   *restclient.Config
	KubectlOpts *k8s.KubectlOptions
	tunnels     map[string]*k8s.Tunnel
	tunnelMutex sync.Mutex
}

type rendering struct {
	Config *Config
}

// Config return the config of framework.
type Config struct {
	Namespace  string `json:"namespace"`
	KubeConfig string `json:"kubeconfig"`
}

var config = &Config{}

// GetGlobalFramework get a global framework with default settings.
func GetGlobalFramework() *Framework {
	if _globalFramework == nil {
		_globalOnce.Do(func() {
			_globalFramework = InitGlobalFramework(config)
		})
	}

	return _globalFramework
}

// InitGlobalFramework init a global framework with default settings.
func InitGlobalFramework(config *Config) *Framework {
	f := &Framework{
		GomegaT: gomega.NewWithT(ginkgo.GinkgoT(4)),
		GinkgoT: ginkgo.GinkgoT(),
		Render: &rendering{
			Config: config,
		},
		config:  config,
		tunnels: make(map[string]*k8s.Tunnel),
	}
	f.config.Namespace = getNamespace()

	// use the current context in kubeconfig
	cfg, err := clientcmd.BuildConfigFromFlags("", getKubeconfig())
	f.clientCfg = cfg
	f.GomegaT.Expect(err).ShouldNot(gomega.HaveOccurred(), "creating kubeconfig")

	f.KubectlOpts = k8s.NewKubectlOptions("", "", f.config.Namespace)
	// create the clientset
	clientset, err := kubernetes.NewForConfig(cfg)
	f.GomegaT.Expect(err).ShouldNot(gomega.HaveOccurred(), "creating clientset")

	f.clientset = clientset
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	_, err = f.clientset.CoreV1().Namespaces().Create(ctx, &corev1.Namespace{
		ObjectMeta: metav1.ObjectMeta{
			Name: config.Namespace,
		},
	}, metav1.CreateOptions{})
	f.GomegaT.Expect(err).ShouldNot(gomega.HaveOccurred(), "creating namespace")

	ginkgo.AfterEach(f.dumpErrorLogs)
	return f
}

// CloseTunnels close tunnels for the framework.
func (f *Framework) CloseTunnels() {
	for _, tunnel := range f.tunnels {
		tunnel.Close()
	}
}

// CleanUp clean up the resources that create by framework.
func (f *Framework) CleanUp() {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	f.CloseTunnels()
	err := f.clientset.CoreV1().Namespaces().Delete(ctx, f.config.Namespace, metav1.DeleteOptions{})
	f.GomegaT.Expect(err).ShouldNot(gomega.HaveOccurred(), "deleting namespace")
}

// dumpErrorLogs dump the error logs of the test.
func (f *Framework) dumpErrorLogs() {
	if ginkgo.CurrentSpecReport().Failed() {
		ginkgo.GinkgoWriter.Println("dump component logs")
		logs := f.LogPodBySelector("logdump=True", -1, true)
		scanner := bufio.NewScanner(strings.NewReader(logs))
		for scanner.Scan() {
			line := scanner.Text()
			ginkgo.GinkgoWriter.Println(line)
		}
	}
}

// GetPodEndpoint returns an url.URL object which contains accessible
// the pod listen address.
func (f *Framework) GetPodEndpoint(name string) *url.URL {
	return &url.URL{
		Scheme: "http",
		Host:   f.tunnels[name].Endpoint(),
	}
}
