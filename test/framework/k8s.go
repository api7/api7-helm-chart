package framework

import (
	"context"
	"fmt"
	"io"
	"os"
	"os/user"
	"path/filepath"
	"strconv"
	"strings"
	"time"

	"github.com/gruntwork-io/terratest/modules/k8s"
	"github.com/onsi/gomega"
	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/util/wait"
)

// getKubeconfig returns the kubeconfig file path.
// Order:
// env KUBECONFIG;
// ~/.kube/config;
// "" (in case in-cluster configuration will be used).
func getKubeconfig() string {
	kubeconfig := os.Getenv("KUBECONFIG")
	if kubeconfig == "" {
		u, err := user.Current()
		if err != nil {
			panic(err)
		}
		kubeconfig = filepath.Join(u.HomeDir, ".kube", "config")
		if _, err := os.Stat(kubeconfig); err != nil && !os.IsNotExist(err) {
			kubeconfig = ""
		}
	}
	return kubeconfig
}

func getNamespace() string {
	return fmt.Sprintf("api7-dashboard-%d", time.Now().Nanosecond())
}

// CreateConfigMap creates a config map.
func (f *Framework) CreateConfigMap(name string, data map[string]string) {
	_, err := f.clientset.CoreV1().ConfigMaps(f.config.Namespace).Create(context.Background(), &corev1.ConfigMap{
		ObjectMeta: metav1.ObjectMeta{
			Name:      name,
			Namespace: f.config.Namespace,
		},
		Data: data,
	}, metav1.CreateOptions{})
	f.GomegaT.Expect(err).To(gomega.BeNil(), "check configmap create")

	return
}

func (f *Framework) waitPodsRestart(namespace, name string, restart int32) error {
	backoff := wait.Backoff{
		Duration: 6 * time.Second,
		Factor:   1,
		Steps:    6,
	}
	var lastErr error
	condFunc := func() (bool, error) {
		pod, err := f.clientset.CoreV1().Pods(namespace).Get(context.TODO(), name, metav1.GetOptions{})
		if err != nil {
			lastErr = err
			return false, nil
		}

		for _, status := range pod.Status.ContainerStatuses {
			if status.RestartCount >= restart {
				return true, nil
			}
		}

		return false, nil
	}

	err := wait.ExponentialBackoff(backoff, condFunc)
	if err != nil {
		return lastErr
	}
	return nil
}

func (f *Framework) WaitAllPodsAvailable(selector string) error {
	backoff := wait.Backoff{
		Duration: 6 * time.Second,
		Factor:   1,
		Steps:    6,
	}
	var lastErr error
	condFunc := func() (bool, error) {
		pods, err := f.clientset.CoreV1().Pods(f.config.Namespace).List(context.TODO(), metav1.ListOptions{
			LabelSelector: selector,
		})
		if err != nil {
			lastErr = err
			return false, nil
		}
		for _, pod := range pods.Items {
			foundPodReady := false
			for _, cond := range pod.Status.Conditions {
				if cond.Type != corev1.PodReady {
					continue
				}
				foundPodReady = true
				if cond.Status != "True" {
					return false, nil
				}
			}
			if !foundPodReady {
				return false, nil
			}
		}
		return true, nil
	}

	err := wait.ExponentialBackoff(backoff, condFunc)
	if err != nil {
		return lastErr
	}
	return nil
}

func (f *Framework) EnsureService(name string, desiredEndpoints int) error {
	backoff := wait.Backoff{
		Duration: 20 * time.Second,
		Factor:   1,
		Steps:    20,
	}

	var lastErr error
	condFunc := func() (bool, error) {
		ep, err := f.clientset.CoreV1().Endpoints(f.config.Namespace).Get(context.TODO(), name, metav1.GetOptions{})
		if err != nil {
			lastErr = err
			return false, nil
		}
		count := 0
		for _, ss := range ep.Subsets {
			count += len(ss.Addresses)
		}
		if count == desiredEndpoints {
			return true, nil
		}

		lastErr = fmt.Errorf("expected endpoints: %d but seen %d", desiredEndpoints, count)
		return false, nil
	}

	err := wait.ExponentialBackoff(backoff, condFunc)
	if err != nil {
		return lastErr
	}
	return nil
}

// GetPodLog get the logs of a pod
func (f *Framework) GetPodLog(name string, previous bool) []byte {
	reader, err := f.clientset.CoreV1().Pods(f.config.Namespace).GetLogs(name, &corev1.PodLogOptions{
		Previous: previous,
	}).Stream(context.Background())

	f.GomegaT.Expect(err).ShouldNot(gomega.HaveOccurred(), "check log get")
	logs, err := io.ReadAll(reader)
	f.GomegaT.Expect(err).ShouldNot(gomega.HaveOccurred(), "read all logs")

	return logs
}

// LogPodBySelector logs the pods by selector
func (f *Framework) LogPodBySelector(selector string, tailLines int, withHeader bool) string {
	pods, err := f.clientset.CoreV1().Pods(f.config.Namespace).List(context.TODO(), metav1.ListOptions{
		LabelSelector: selector,
	})
	if err != nil {
		return ""
	}
	var buf strings.Builder
	for _, pod := range pods.Items {
		var container string
		if len(pod.Spec.Containers) > 1 {
			if defaultContainer, ok := pod.Annotations["kubectl.kubernetes.io/default-container"]; ok {
				container = defaultContainer
			} else {
				container = pod.Spec.Containers[0].Name
			}
		}
		if withHeader {
			buf.WriteString(fmt.Sprintf("=== pod: %s ===\n", pod.Name))
		}
		var (
			logs []byte
			err  error
		)

		if tailLines == -1 {
			logs, err = f.clientset.CoreV1().RESTClient().Get().
				Resource("pods").
				Namespace(f.config.Namespace).
				Name(pod.Name).SubResource("log").
				Param("container", container).
				Do(context.TODO()).
				Raw()
		} else {
			logs, err = f.clientset.CoreV1().RESTClient().Get().
				Resource("pods").
				Namespace(f.config.Namespace).
				Name(pod.Name).SubResource("log").
				Param("container", container).
				Param("tailLines", strconv.Itoa(tailLines)).
				Do(context.TODO()).
				Raw()
		}
		if err == nil {
			buf.Write(logs)
		}
		buf.WriteByte('\n')
	}
	return buf.String()
}

// GetPodByNamePrefix get pod by name prefix
func (f *Framework) GetPodByNamePrefix(prefix string) (*corev1.Pod, error) {
	pods, err := f.clientset.CoreV1().Pods(f.config.Namespace).List(context.TODO(), metav1.ListOptions{})
	if err != nil {
		return nil, err
	}
	for _, pod := range pods.Items {
		if strings.HasPrefix(pod.Name, prefix) {
			return &pod, nil
		}
	}

	return nil, fmt.Errorf("not found pod with prefix %s", prefix)
}

// CreateTunnelForService creates a tunnel for a service.
func (f *Framework) CreateTunnelForService(name string, resourceName string, remotePort int) {
	tunnel := k8s.NewTunnel(f.KubectlOpts, k8s.ResourceTypeService, resourceName, 0, remotePort)
	f.tunnelMutex.Lock()
	f.tunnels[name] = tunnel
	f.tunnelMutex.Unlock()
	err := tunnel.ForwardPortE(f.GinkgoT)
	f.GomegaT.Expect(err).ShouldNot(gomega.HaveOccurred(), "forwarding "+name)
}
