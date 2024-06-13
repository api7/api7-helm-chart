# api7-ingress-controller

![Version: 0.0.1](https://img.shields.io/badge/Version-0.0.1-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 2.0.0](https://img.shields.io/badge/AppVersion-2.0.0-informational?style=flat-square)

Ingress Controller for API7

## Source Code

* <https://github.com/api7/api7-helm-chart>

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` |  |
| annotations | object | `{}` | Add annotations to Apache APISIX ingress controller resource |
| autoscaling.enabled | bool | `false` |  |
| autoscaling.maxReplicas | int | `100` |  |
| autoscaling.minReplicas | int | `1` |  |
| autoscaling.targetCPUUtilizationPercentage | int | `80` |  |
| autoscaling.version | string | `"v2"` | HPA version, the value is "v2" or "v2beta1", default "v2" |
| clusterDomain | string | `"cluster.local"` |  |
| config.apisixResourceSyncInterval | string | `"1h"` | Default interval for synchronizing Kubernetes resources to APISIX |
| config.certFile | string | `"/etc/webhook/certs/cert.pem"` | the TLS certificate file path. |
| config.dashboard | object | `{"adminAPIVersion":"v3","adminKey":"a7adm-dMx6MQ0NvEbr1V1oC109ovU9r3AZ80966HDx83M48chS1951P0788e4029ef18499999f421c6aea370ae","baseURL":"http://dashboard:7080","clusterName":"default","existingSecret":"","existingSecretAdminKeyKey":""}` | APISIX related configurations. |
| config.dashboard.adminAPIVersion | string | `"v3"` | the APISIX admin API version. can be "v2" or "v3", default is "v2". |
| config.dashboard.baseURL | string | `"http://dashboard:7080"` | Enabling this value, overrides serviceName and serviceNamespace. |
| config.dashboard.existingSecret | string | `""` | The APISIX Helm chart supports storing user credentials in a secret. The secret needs to contain a single key for admin token with key adminKey by default. |
| config.dashboard.existingSecretAdminKeyKey | string | `""` | Name of the admin token key in the secret, overrides the default key name "adminKey" |
| config.enableProfiling | bool | `true` | enable profiling via web interfaces host:port/debug/pprof, default is true. |
| config.httpListen | string | `":8080"` | the HTTP Server listen address, default is ":8080" |
| config.httpsListen | string | `":8443"` | the HTTPS Server listen address, default is ":8443" |
| config.ingressPublishService | string | `""` | the controller will use the Endpoint of this Service to update the status information of the Ingress resource. The format is "namespace/svc-name" to solve the situation that the data plane and the controller are not deployed in the same namespace. |
| config.ingressStatusAddress | list | `[]` |  |
| config.keyFile | string | `"/etc/webhook/certs/key.pem"` | the TLS key file path. |
| config.kubernetes | object | `{"apiVersion":"apisix.apache.org/v2","apisixRouteVersion":"apisix.apache.org/v2","electionId":"ingress-apisix-leader","enableGatewayAPI":false,"ingressClass":"apisix","ingressVersion":"networking/v1","kubeconfig":"","namespaceSelector":[""],"resyncInterval":"6h","watchEndpointSlices":false}` | Kubernetes related configurations. |
| config.kubernetes.apiVersion | string | `"apisix.apache.org/v2"` | the resource API version, support "apisix.apache.org/v2beta3" and "apisix.apache.org/v2". default is "apisix.apache.org/v2" |
| config.kubernetes.apisixRouteVersion | string | `"apisix.apache.org/v2"` | the supported apisixroute api group version, can be "apisix.apache.org/v2" "apisix.apache.org/v2beta3" or "apisix.apache.org/v2beta2" |
| config.kubernetes.electionId | string | `"ingress-apisix-leader"` | the election id for the controller leader campaign, only the leader will watch and delivery resource changes, other instances (as candidates) stand by. |
| config.kubernetes.enableGatewayAPI | bool | `false` | whether to enable support for Gateway API. Note: This feature is currently under development and may not work as expected. It is not recommended to use it in a production environment. Before we announce support for it to reach Beta level or GA. |
| config.kubernetes.ingressClass | string | `"apisix"` | The class of an Ingress object is set using the field IngressClassName in Kubernetes clusters version v1.18.0 or higher or the annotation "kubernetes.io/ingress.class" (deprecated). |
| config.kubernetes.ingressVersion | string | `"networking/v1"` | the supported ingress api group version, can be "networking/v1beta1", "networking/v1" (for Kubernetes version v1.19.0 or higher), and "extensions/v1beta1", default is "networking/v1". |
| config.kubernetes.kubeconfig | string | `""` | the Kubernetes configuration file path, default is "", so the in-cluster configuration will be used. |
| config.kubernetes.namespaceSelector | list | `[""]` | namespace_selector represent basis for selecting managed namespaces. the field is support since version 1.4.0 For example, "apisix.ingress=watching", so ingress will watching the namespaces which labels "apisix.ingress=watching" |
| config.kubernetes.resyncInterval | string | `"6h"` | how long should api7-ingress-controller re-synchronizes with Kubernetes, default is 6h, |
| config.kubernetes.watchEndpointSlices | bool | `false` | whether to watch EndpointSlices rather than Endpoints. |
| config.logLevel | string | `"info"` | the error log level, default is info, optional values are: debug, info, warn, error, panic, fatal |
| config.logOutput | string | `"stderr"` | the output file path of error log, default is stderr, when the file path is "stderr" or "stdout", logs are marshalled plainly, which is more readable for human; otherwise logs are marshalled in JSON format, which can be parsed by programs easily. |
| config.pluginMetadataCM | string | `""` | Pluginmetadata in APISIX can be controlled through ConfigMap. default is "" |
| fullnameOverride | string | `""` |  |
| gateway.externalIPs | list | `[]` | load balancer ips |
| gateway.externalTrafficPolicy | string | `"Cluster"` |  |
| gateway.nginx.errorLog | string | `"stderr"` | Nginx error logs path |
| gateway.nginx.errorLogLevel | string | `"warn"` | Nginx error logs level |
| gateway.nginx.workerConnections | string | `"10620"` | Nginx worker connections |
| gateway.nginx.workerProcesses | string | `"auto"` | Nginx worker processes |
| gateway.nginx.workerRlimitNofile | string | `"20480"` | Nginx workerRlimitNoFile |
| gateway.resources | object | `{}` |  |
| gateway.securityContext | object | `{}` |  |
| gateway.tls.additionalContainerPorts | list | `[]` | Support multiple https ports, See [Configuration](https://github.com/apache/apisix/blob/0bc65ea9acd726f79f80ae0abd8f50b7eb172e3d/conf/config-default.yaml#L99) |
| gateway.tls.certCAFilename | string | `""` | Filename be used in the gateway.tls.existingCASecret |
| gateway.tls.containerPort | int | `9443` |  |
| gateway.tls.enabled | bool | `false` |  |
| gateway.tls.existingCASecret | string | `""` | Specifies the name of Secret contains trusted CA certificates in the PEM format used to verify the certificate when APISIX needs to do SSL/TLS handshaking with external services (e.g. etcd) |
| gateway.tls.fallbackSNI | string | `""` | Define SNI to fallback if none is presented by client |
| gateway.tls.http2.enabled | bool | `true` |  |
| gateway.tls.servicePort | int | `443` |  |
| gateway.tls.sslProtocols | string | `"TLSv1.2 TLSv1.3"` | TLS protocols allowed to use. |
| gateway.type | string | `"NodePort"` | Apache APISIX service type for user access itself |
| image.pullPolicy | string | `"Always"` |  |
| image.repository | string | `"api7/api7-ingress-controller"` |  |
| image.tag | string | `"2.0.0"` |  |
| imagePullSecrets | list | `[]` |  |
| labelsOverride | object | `{}` | Override default labels assigned to Apache APISIX ingress controller resource |
| nameOverride | string | `""` |  |
| nodeSelector | object | `{}` |  |
| podAnnotations | object | `{}` |  |
| podDisruptionBudget | object | `{"enabled":false,"maxUnavailable":1,"minAvailable":"90%"}` | See https://kubernetes.io/docs/tasks/run-application/configure-pdb/ for more details |
| podDisruptionBudget.enabled | bool | `false` | Enable or disable podDisruptionBudget |
| podDisruptionBudget.maxUnavailable | int | `1` | Set the maxUnavailable of podDisruptionBudget |
| podDisruptionBudget.minAvailable | string | `"90%"` | Set the `minAvailable` of podDisruptionBudget. You can specify only one of `maxUnavailable` and `minAvailable` in a single PodDisruptionBudget. See [Specifying a Disruption Budget for your Application](https://kubernetes.io/docs/tasks/run-application/configure-pdb/#specifying-a-poddisruptionbudget) for more details |
| podSecurityContext | object | `{}` |  |
| priorityClassName | string | `""` |  |
| rbac.create | bool | `true` | Specifies whether RBAC resources should be created |
| replicaCount | int | `1` |  |
| resources | object | `{}` |  |
| securityContext | object | `{}` |  |
| service.port | int | `80` |  |
| serviceAccount.automountServiceAccountToken | bool | `true` | Whether automounting API credentials for a service account |
| serviceAccount.create | bool | `true` | Specifies whether a ServiceAccount should be created |
| serviceAccount.name | string | `""` | The name of the ServiceAccount to use. If not set and create is true, a name is generated using the fullname template |
| serviceMonitor | object | `{"annotations":{},"enabled":false,"interval":"15s","labels":{},"metricRelabelings":{},"namespace":"monitoring"}` | Enable creating ServiceMonitor objects for Prometheus operator. Requires Prometheus operator v0.38.0 or higher. |
| serviceMonitor.annotations | object | `{}` | @param serviceMonitor.annotations ServiceMonitor annotations |
| serviceMonitor.labels | object | `{}` | @param serviceMonitor.labels ServiceMonitor extra labels |
| serviceMonitor.metricRelabelings | object | `{}` | @param serviceMonitor.metricRelabelings MetricRelabelConfigs to apply to samples before ingestion. ref: https://prometheus.io/docs/prometheus/latest/configuration/configuration/#metric_relabel_configs |
| tolerations | list | `[]` |  |
| topologySpreadConstraints | list | `[]` | Topology Spread Constraints for pod assignment spread across your cluster among failure-domains ref: https://kubernetes.io/docs/concepts/workloads/pods/pod-topology-spread-constraints/#spread-constraints-for-pods |
| updateStrategy | object | `{}` | Update strategy for apisix ingress controller deployment |

