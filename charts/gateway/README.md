## API7 Gateway for Kubernetes

API7 Gateway is a dynamic, real-time, high-performance API gateway.

API7 Gateway provides rich traffic management features such as load balancing, dynamic upstream, canary release, circuit breaking, authentication, observability, and more.

You can use API7 Gateway to handle traditional north-south traffic, as well as east-west traffic between services.

This chart bootstraps all the components needed to run API7 Gateway on a Kubernetes Cluster using [Helm](https://helm.sh).

## Prerequisites

* Kubernetes v1.14+
* Helm v3+

## Install

```sh
helm repo add api7 https://charts.api7.ai
helm repo update

helm install [RELEASE_NAME] api7/gateway --namespace api7 --create-namespace
```

## Uninstall

 ```sh
helm delete [RELEASE_NAME] --namespace api7
 ```

The command removes all the Kubernetes components associated with the chart and deletes the release.

## Parameters

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| admin.allow.ipList | list | `["127.0.0.1/24"]` | The client IP CIDR allowed to access API7 Gateway Admin API service. |
| admin.cors | bool | `true` | Admin API support CORS response headers |
| admin.credentials | object | `{"admin":"edd1c9f034335f136f87ad84b625c8f1","secretName":"","viewer":"4054f7cf07e344346cd3f287985e76a2"}` | Admin API credentials |
| admin.credentials.admin | string | `"edd1c9f034335f136f87ad84b625c8f1"` | API7 Gateway admin API admin role credentials |
| admin.credentials.secretName | string | `""` | The APISIX Helm chart supports storing user credentials in a secret. The secret needs to contain two keys, admin and viewer, with their respective values set. |
| admin.credentials.viewer | string | `"4054f7cf07e344346cd3f287985e76a2"` | API7 Gateway admin API viewer role credentials |
| admin.enabled | bool | `false` | Enable Admin API |
| admin.externalIPs | list | `[]` | IPs for which nodes in the cluster will also accept traffic for the servic |
| admin.ingress | object | `{"annotations":{},"enabled":false,"hosts":[{"host":"apisix-admin.local","paths":["/apisix"]}],"tls":[]}` | Using ingress access API7 Gateway admin service |
| admin.ingress.annotations | object | `{}` | Ingress annotations |
| admin.ingress.enabled | bool | `false` | Enable an Ingress resource in front of the Admin API service |
| admin.ingress.hosts | list | `[{"host":"apisix-admin.local","paths":["/apisix"]}]` | Ingress host and path rules |
| admin.ingress.tls | list | `[]` | Ingress TLS settings |
| admin.ip | string | `"0.0.0.0"` | which ip to listen on for API7 Gateway admin API. Set to `"[::]"` when on IPv6 single stack |
| admin.port | int | `9180` | which port to use for API7 Gateway admin API |
| admin.servicePort | int | `9180` | Service port to use for API7 Gateway admin API |
| admin.type | string | `"ClusterIP"` | admin service type |
| api7ee.disable_upstream_healthcheck | bool | `false` | A global switch for healthcheck. Defaults to false. When set to true, it overrides all upstream healthcheck configurations and globally disabling healthchecks. |
| api7ee.healthcheck_report_interval | int | `120` | Interval in seconds at which the gateway reports upstream healthcheck data to the control plane |
| api7ee.http_timeout | string | `"30s"` | HTTP timeout used while sending healthcheck and telemetry data to the control plane |
| api7ee.raw_api_calls_upload_interval | int | `3600` | Interval in seconds at which raw API call data (used by the API usage feature) is uploaded to the control plane |
| api7ee.status_endpoint.enabled | bool | `false` | When enabled, APISIX will provide `/status` and `/status/ready` endpoints, /status endpoint will return 200 status code if APISIX has successfully started and running correctly, /status/ready endpoint will return 503 status code if none of the configured etcd (dp_manager) are available. |
| api7ee.status_endpoint.ip | string | `"0.0.0.0"` | The IP address and port on which the status endpoint will listen. |
| api7ee.status_endpoint.port | int | `7085` | The port on which the status endpoint will listen. |
| apisix.affinity | object | `{}` | Set affinity for API7 Gateway deploy |
| apisix.customLuaSharedDicts | list | `[{"name":"kubernetes","size":"64m"},{"name":"nacos","size":"64m"},{"name":"consul","size":"64m"}]` | Add custom [lua_shared_dict](https://github.com/openresty/lua-nginx-module#toc88) settings, click [here](https://github.com/apache/apisix-helm-chart/blob/master/charts/apisix/values.yaml#L27-L30) to learn the format of a shared dict |
| apisix.customizedConfig | object | `{}` | If apisix.enableCustomizedConfig is true, full customized config.yaml. Please note that other settings about APISIX config will be ignored |
| apisix.deleteURITailSlash | bool | `false` | Delete the '/' at the end of the URI |
| apisix.dnsConfig | object | `{}` | Custom DNS settings for the APISIX pods |
| apisix.enableCustomizedConfig | bool | `false` | Enable full customized config.yaml |
| apisix.enableIPv6 | bool | `true` | Enable nginx IPv6 resolver |
| apisix.enableServerTokens | bool | `true` | Whether the APISIX version number should be shown in Server header |
| apisix.enabled | bool | `true` | Enable or disable API7 Gateway itself |
| apisix.extraEnvVars | list | `[]` | extraEnvVars An array to add extra env vars e.g: extraEnvVars:   - name: FOO     value: "bar"   - name: FOO2     valueFrom:       secretKeyRef:         name: SECRET_NAME         key: KEY |
| apisix.extraEnvVarsCM | string | `""` | Name of existing ConfigMap containing extra env vars |
| apisix.extraEnvVarsSecret | string | `""` | Name of existing Secret containing extra env vars |
| apisix.extraLuaCPath | string | `""` | Extend lua_package_cpath to load third party Lua C libraries |
| apisix.extraLuaPath | string | `""` | Extend lua_package_path to load third party Lua code |
| apisix.hostNetwork | bool | `false` | Use the host's network namespace |
| apisix.http.luaSharedDict | object | `{"access-tokens":"1m","api-calls-for-portal":"64m","balancer-ewma":"10m","balancer-ewma-last-touched-at":"10m","balancer-ewma-locks":"10m","cas-auth":"10m","discovery":"1m","etcd-cluster-health-check":"10m","internal-status":"10m","introspection":"10m","jwks":"1m","lrucache-lock":"10m","plugin-ai-rate-limiting":"10m","plugin-ai-rate-limiting-reset-header":"10m","plugin-api-breaker":"10m","plugin-graphql-limit-count":"10m","plugin-graphql-limit-count-reset-header":"10m","plugin-limit-conn":"10m","plugin-limit-conn-redis-cluster-slot-lock":"1m","plugin-limit-count":"10m","plugin-limit-count-advanced":"10m","plugin-limit-count-advanced-redis-cluster-slot-lock":"1m","plugin-limit-count-redis-cluster-slot-lock":"1m","plugin-limit-req":"10m","plugin-limit-req-redis-cluster-slot-lock":"1m","status_report":"1m","tars":"1m","tracing_buffer":"32m","upstream-healthcheck":"10m","worker-events":"10m"}` | Shared dict settings for the HTTP subsystem |
| apisix.httpRouter | string | `"radixtree_host_uri"` | Defines how apisix handles routing: - radixtree_uri: match route by uri(base on radixtree) - radixtree_host_uri: match route by host + uri(base on radixtree) - radixtree_uri_with_parameter: match route by uri with parameters |
| apisix.image.pullPolicy | string | `"Always"` | API7 Gateway image pull policy |
| apisix.image.repository | string | `"api7/api7-ee-3-gateway"` | API7 Gateway image repository |
| apisix.image.tag | string | `"3.10.2"` | API7 Gateway image tag Overrides the image tag whose default is the chart appVersion. |
| apisix.kind | string | `"Deployment"` | Use a `DaemonSet` or `Deployment` |
| apisix.lru | object | `{"secret":{"count":512,"neg_count":512,"neg_ttl":60,"ttl":300}}` | fine tune the parameters of LRU cache for some features like secret |
| apisix.lru.secret.count | int | `512` | Maximum number of cached secret values |
| apisix.lru.secret.neg_count | int | `512` | Maximum number of cached negative (failed lookup) results |
| apisix.lru.secret.neg_ttl | int | `60` | TTL in seconds for cached negative (failed lookup) results |
| apisix.lru.secret.ttl | int | `300` | TTL in seconds for cached secret values |
| apisix.maxPostArgsReadableSize | int | `64` | Cap (in MB) on the request body read when matching `post_arg.*` route predicates for JSON and multipart requests. Set to 0 to disable the limit. |
| apisix.meta.luaSharedDict | object | `{"prometheus-metrics":"256m"}` | Shared dict settings for the `meta` context (used by both HTTP and stream subsystems) |
| apisix.nodeSelector | object | `{}` | Node labels for API7 Gateway pod assignment |
| apisix.normalizeURILikeServlet | bool | `false` | The URI normalization in servlet is a little different from the RFC's. See https://github.com/jakartaee/servlet/blob/master/spec/src/main/asciidoc/servlet-spec-body.adoc#352-uri-path-canonicalization, which is used under Tomcat. Turn this option on if you want to be compatible with servlet when matching URI path. |
| apisix.podAnnotations | object | `{}` | Annotations to add to each pod |
| apisix.podDisruptionBudget | object | `{"enabled":false,"maxUnavailable":1,"minAvailable":"90%"}` | See https://kubernetes.io/docs/tasks/run-application/configure-pdb/ for more details |
| apisix.podDisruptionBudget.enabled | bool | `false` | Enable or disable podDisruptionBudget |
| apisix.podDisruptionBudget.maxUnavailable | int | `1` | Set the maxUnavailable of podDisruptionBudget |
| apisix.podDisruptionBudget.minAvailable | string | `"90%"` | Set the `minAvailable` of podDisruptionBudget. You can specify only one of `maxUnavailable` and `minAvailable` in a single PodDisruptionBudget. See [Specifying a Disruption Budget for your Application](https://kubernetes.io/docs/tasks/run-application/configure-pdb/#specifying-a-poddisruptionbudget) for more details |
| apisix.podLabels | object | `{}` | Labels to add to each pod |
| apisix.podSecurityContext | object | `{}` | Set the securityContext for API7 Gateway pods |
| apisix.priorityClassName | string | `""` | Set [priorityClassName](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/#pod-priority) for API7 Gateway pods |
| apisix.proxyCache | object | `{"cacheTtl":"10s","zones":[{"cache_levels":"1:2","disk_path":"/tmp/disk_cache_one","disk_size":"1G","memory_size":"50m","name":"disk_cache_one"},{"memory_size":"50m","name":"memory_cache"}]}` | Proxy caching configuration used by the proxy-cache plugin. |
| apisix.proxyCache.cacheTtl | string | `"10s"` | The default caching time in disk if the upstream does not specify the cache time |
| apisix.proxyCache.zones | list | `[{"cache_levels":"1:2","disk_path":"/tmp/disk_cache_one","disk_size":"1G","memory_size":"50m","name":"disk_cache_one"},{"memory_size":"50m","name":"memory_cache"}]` | The parameters of a cache. The `memory_size` field stores the cache index for the disk strategy and the cache content for the memory strategy; `disk_size`, `disk_path` and `cache_levels` only apply to the disk strategy. |
| apisix.proxyProtocol | object | `{"enableTcpPP":false,"enableTcpPPToUpstream":false,"listenHttpNodePort":null,"listenHttpPort":null,"listenHttpsNodePort":null,"listenHttpsPort":null}` | PROXY Protocol configuration. |
| apisix.proxyProtocol.enableTcpPP | bool | `false` | Accept the PROXY Protocol on every gateway.stream.tcp port. Acts as the default; override per port with the `proxy_protocol` field on a gateway.stream.tcp entry. |
| apisix.proxyProtocol.enableTcpPPToUpstream | bool | `false` | Send the PROXY Protocol to the upstream server on every gateway.stream.tcp port. Acts as the default; override per port with the `proxy_protocol_to_upstream` field on a gateway.stream.tcp entry. |
| apisix.proxyProtocol.listenHttpNodePort | int | `nil` | The nodePort of the PROXY Protocol HTTP port, only used if gateway.type is NodePort. If not set, a random port will be assigned by Kubernetes. |
| apisix.proxyProtocol.listenHttpPort | int | `nil` | The HTTP port that accepts the PROXY Protocol. It differs from `gateway.http` ports and `admin` port: this port only accepts HTTP requests carrying the PROXY Protocol, while the other ports only accept plain HTTP requests. If you enable the PROXY Protocol, you must use this port to receive HTTP requests with it. When set, the port is also exposed on the gateway Service. |
| apisix.proxyProtocol.listenHttpsNodePort | int | `nil` | The nodePort of the PROXY Protocol HTTPS port, only used if gateway.type is NodePort. If not set, a random port will be assigned by Kubernetes. |
| apisix.proxyProtocol.listenHttpsPort | int | `nil` | The HTTPS port that accepts the PROXY Protocol. When set, the port is also exposed on the gateway Service. |
| apisix.replicaCount | int | `1` | kind is DaemonSet, replicaCount not become effective |
| apisix.resources | object | `{}` | Set pod resource requests & limits |
| apisix.securityContext | object | `{}` | Set the securityContext for API7 Gateway container |
| apisix.setIDFromPodUID | bool | `false` | Use Pod metadata.uid as the APISIX id. |
| apisix.showUpstreamStatusInResponseHeader | bool | `false` | When true, the upstream status is always written to the `X-APISIX-Upstream-Status` response header; when false, it is written only for 5xx responses |
| apisix.stream.luaSharedDict | object | `{"config-stream":"5m","etcd-cluster-health-check-stream":"10m","lrucache-lock-stream":"10m","nacos-stream":"20m","plugin-limit-conn-stream":"10m","tars-stream":"1m","worker-events-stream":"10m"}` | Shared dict settings for the stream (L4 proxy) subsystem |
| apisix.terminationGracePeriodSeconds | int | `30` | termination grace period for API7 Gateway pods |
| apisix.timezone | string | `""` | timezone is the timezone where apisix uses. For example: "UTC" or "Asia/Shanghai" This value will be set on apisix container's environment variable TZ. You may need to set the timezone to be consistent with your local time zone, otherwise the apisix's logs may used to retrieve event maybe in wrong timezone. |
| apisix.tolerations | list | `[]` | List of node taints to tolerate |
| apisix.topologySpreadConstraints | list | `[]` | Topology Spread Constraints for pod assignment https://kubernetes.io/docs/concepts/workloads/pods/pod-topology-spread-constraints/ The value is evaluated as a template |
| apisix.tracing | bool | `false` | Enable comprehensive request lifecycle tracing (SSL/SNI, rewrite, access, header_filter, body_filter, and log). When disabled, OpenTelemetry collects only a single span per request. |
| apisix.trustedAddresses | list | `[]` | List of IPs/CIDRs from which the gateway trusts the `X-Forwarded-*` headers passed in requests. CAUTION: when not configured, or when the request comes from an untrusted address, the gateway overrides `X-Forwarded-Proto/Host/Port` with trusted values and clears the `Forwarded` header. For `X-Forwarded-For`: when this list is configured and the request comes from an untrusted address, the header is reset so the upstream only sees the connection IP observed by the gateway; when not configured, it is preserved and the connection IP is appended (compatible default). |
| autoscaling.enabled | bool | `false` | Enable HorizontalPodAutoscaler for the gateway (only when apisix.kind is Deployment) |
| autoscaling.maxReplicas | int | `100` | Maximum number of gateway replicas |
| autoscaling.minReplicas | int | `1` | Minimum number of gateway replicas |
| autoscaling.targetCPUUtilizationPercentage | int | `80` | Target average CPU utilization percentage that triggers scaling |
| autoscaling.targetMemoryUtilizationPercentage | int | `80` | Target average memory utilization percentage that triggers scaling |
| autoscaling.version | string | `"v2"` | HPA version, the value is "v2" or "v2beta1", default "v2" |
| configurationSnippet | object | `{"httpAdmin":"","httpEnd":"","httpSrv":"","httpSrvLocation":"","httpStart":"","main":"","stream":""}` | Custom nginx configuration snippets injected into the generated nginx.conf. As arbitrary configuration can be added here, it is your responsibility to make sure the snippets don't conflict with the configuration generated by the gateway. |
| configurationSnippet.httpAdmin | string | `""` | Snippet added to the nginx `server` block that serves the Admin API |
| configurationSnippet.httpEnd | string | `""` | Snippet added to the end of the nginx `http` block |
| configurationSnippet.httpSrv | string | `""` | Snippet added to the nginx `server` block that proxies regular traffic |
| configurationSnippet.httpSrvLocation | string | `""` | Snippet added to the `location` block of the nginx `server` block that proxies regular traffic |
| configurationSnippet.httpStart | string | `""` | Snippet added to the beginning of the nginx `http` block |
| configurationSnippet.main | string | `""` | Snippet added to the nginx `main` (top-level) block |
| configurationSnippet.stream | string | `""` | Snippet added to the nginx `stream` block |
| control.enabled | bool | `true` | Enable Control API |
| control.ip | string | `"127.0.0.1"` | which ip to listen on for Control API |
| control.port | int | `9090` | which port to use for Control API |
| deployment.certs | object | `{"cert":"","cert_key":"","certsSecret":"","mTLSCACert":"","mTLSCACertSecret":""}` | certs used for certificates in decoupled mode |
| deployment.certs.cert | string | `""` | cert name in certsSecret |
| deployment.certs.cert_key | string | `""` | cert key in certsSecret |
| deployment.certs.certsSecret | string | `""` | secret name used for decoupled mode |
| deployment.certs.mTLSCACert | string | `""` | mTLS CA cert filename in mTLSCACertSecret |
| deployment.certs.mTLSCACertSecret | string | `""` | trusted_ca_cert name in certsSecret |
| deployment.fallback_cp | object | `{}` | use cloud storage as the fallback control plane |
| discovery.enabled | bool | `false` | Enable or disable API7 Gateway integration service discovery |
| discovery.registry | object | `{}` | Registry is the same to the one in APISIX [config-default.yaml](https://github.com/apache/apisix/blob/master/conf/config-default.yaml#L281), and refer to such file for more setting details. also refer to [this documentation for integration service discovery](https://apisix.apache.org/docs/apisix/discovery) |
| dns.enableResolvSearchOpt | bool | `true` | Honor the `search` option in `/etc/resolv.conf` when resolving domain names |
| dns.resolvers | list | `[]` | Nameservers used by the gateway to resolve upstream domain names. When empty (default), nameservers are read from `/etc/resolv.conf`, which is usually what you want inside Kubernetes |
| dns.timeout | int | `5` | DNS resolver timeout in seconds |
| dns.validity | int | `30` | Override the TTL in seconds of valid DNS records |
| etcd | object | `{"auth":{"rbac":{"create":false,"rootPassword":""},"tls":{"certFilename":"","certKeyFilename":"","enabled":false,"existingSecret":"","sni":"","verify":false}},"enabled":false,"host":["http://etcd.host:2379"],"image":{"repository":"api7/etcd"},"password":"","prefix":"/apisix","replicaCount":3,"service":{"port":2379},"startupRetry":2,"timeout":30,"user":"","watchTimeout":50}` | etcd configuration use the FQDN address or the IP of the etcd |
| etcd.auth | object | `{"rbac":{"create":false,"rootPassword":""},"tls":{"certFilename":"","certKeyFilename":"","enabled":false,"existingSecret":"","sni":"","verify":false}}` | if etcd.enabled is true, set more values of bitnami/etcd helm chart |
| etcd.auth.rbac.create | bool | `false` | No authentication by default. Switch to enable RBAC authentication |
| etcd.auth.rbac.rootPassword | string | `""` | root password for etcd. Requires etcd.auth.rbac.create to be true. |
| etcd.auth.tls.certFilename | string | `""` | etcd client cert filename using in etcd.auth.tls.existingSecret |
| etcd.auth.tls.certKeyFilename | string | `""` | etcd client cert key filename using in etcd.auth.tls.existingSecret |
| etcd.auth.tls.enabled | bool | `false` | enable etcd client certificate |
| etcd.auth.tls.existingSecret | string | `""` | name of the secret contains etcd client cert |
| etcd.auth.tls.sni | string | `""` | specify the TLS Server Name Indication extension, the ETCD endpoint hostname will be used when this setting is unset. |
| etcd.auth.tls.verify | bool | `false` | whether to verify the etcd endpoint certificate when setup a TLS connection to etcd |
| etcd.enabled | bool | `false` | install etcd(v3) by default, set false if do not want to install etcd(v3) together |
| etcd.host | list | `["http://etcd.host:2379"]` | if etcd.enabled is false, use external etcd, support multiple address, if your etcd cluster enables TLS, please use https scheme, e.g. https://127.0.0.1:2379. |
| etcd.image.repository | string | `"api7/etcd"` | etcd image repository, only used when etcd.enabled is true |
| etcd.password | string | `""` | if etcd.enabled is false, password for external etcd. If etcd.enabled is true, use etcd.auth.rbac.rootPassword instead. |
| etcd.prefix | string | `"/apisix"` | apisix configurations prefix |
| etcd.replicaCount | int | `3` | Number of etcd replicas, only used when etcd.enabled is true |
| etcd.service.port | int | `2379` | etcd client service port |
| etcd.startupRetry | int | `2` | The number of retries to etcd during startup |
| etcd.timeout | int | `30` | Set the timeout value in seconds for subsequent socket operations from apisix to etcd cluster |
| etcd.user | string | `""` | if etcd.enabled is false, username for external etcd. If etcd.enabled is true, use etcd.auth.rbac.rootPassword instead. |
| etcd.watchTimeout | int | `50` | Set the timeout value in seconds for watching etcd |
| extraInitContainers | list | `[]` | Additional `initContainers`, See [Kubernetes initContainers](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/) for the detail. |
| extraVolumeMounts | list | `[]` | Additional `volumeMounts` for the gateway container, See [Kubernetes Volumes](https://kubernetes.io/docs/concepts/storage/volumes/) for the detail. |
| extraVolumes | list | `[]` | Additional `volume`, See [Kubernetes Volumes](https://kubernetes.io/docs/concepts/storage/volumes/) for the detail. |
| fullnameOverride | string | `""` | String to fully override the chart fullname |
| gateway.externalIPs | list | `[]` | IPs for which nodes in the cluster will also accept traffic for the servic annotations:   service.beta.kubernetes.io/aws-load-balancer-type: nlb |
| gateway.externalTrafficPolicy | string | `"Cluster"` | Setting how the Service route external traffic. If you want to keep the client source IP, you can set this to Local, ref: https://kubernetes.io/docs/tasks/access-application-cluster/create-external-load-balancer/#preserving-the-client-source-ip |
| gateway.http | object | `{"additionalContainerPorts":[],"containerPort":9080,"enabled":true,"ip":"0.0.0.0","nodePort":null,"servicePort":80}` | API7 Gateway service settings for http |
| gateway.http.additionalContainerPorts | list | `[]` | Support multiple http ports, See [Configuration](https://github.com/apache/apisix/blob/0bc65ea9acd726f79f80ae0abd8f50b7eb172e3d/conf/config-default.yaml#L24) |
| gateway.http.containerPort | int | `9080` | Container port the gateway listens on for HTTP traffic |
| gateway.http.enabled | bool | `true` | Enable plain HTTP listeners |
| gateway.http.ip | string | `"0.0.0.0"` | which ip to listen on for API7 Gateway http service. |
| gateway.http.nodePort | int | `nil` | The nodePort of kubernetes service, only used if gateway.type is NodePort. If not set, a random port will be assigned by Kubernetes. |
| gateway.http.servicePort | int | `80` | Kubernetes service port for HTTP traffic |
| gateway.ingress | object | `{"annotations":{},"enabled":false,"hosts":[{"host":"apisix.local","paths":[]}],"tls":[]}` | Using ingress access API7 Gateway service |
| gateway.ingress.annotations | object | `{}` | Ingress annotations |
| gateway.ingress.enabled | bool | `false` | Enable an Ingress resource in front of the gateway service |
| gateway.ingress.hosts | list | `[{"host":"apisix.local","paths":[]}]` | Ingress host and path rules |
| gateway.ingress.tls | list | `[]` | Ingress TLS settings |
| gateway.labelsOverride | object | `{}` | Override default labels assigned to API7 Gateway gateway resources |
| gateway.livenessProbe | object | `{}` | kubernetes liveness probe. |
| gateway.readinessProbe | object | `{}` | kubernetes readiness probe, we will provide a probe based on tcpSocket to gateway's HTTP port by default. |
| gateway.stream | object | `{"autoAssignNodePort":false,"enabled":false,"only":false,"tcp":[],"udp":[]}` | API7 Gateway service settings for stream. L4 proxy (TCP/UDP) |
| gateway.stream.autoAssignNodePort | bool | `false` | Whether to set nodePort to the same value as the TCP/UDP port when gateway.type is NodePort, make sure the nodePort to be in the valid NodePort range of kubernetes service. |
| gateway.stream.enabled | bool | `false` | Enable the stream (L4 proxy) subsystem |
| gateway.stream.only | bool | `false` | Use the stream proxy only, without enabling the HTTP subsystem |
| gateway.tls | object | `{"additionalContainerPorts":[],"certCAFilename":"","containerPort":9443,"enabled":true,"existingCASecret":"","fallbackSNI":"","http2":{"enabled":true},"ip":"0.0.0.0","nodePort":null,"servicePort":443,"sslCiphers":"ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:DHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA:ECDHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES256-SHA256:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:DES-CBC3-SHA","sslProtocols":"TLSv1.2 TLSv1.3","sslSessionTickets":false}` | API7 Gateway service settings for tls |
| gateway.tls.additionalContainerPorts | list | `[]` | Support multiple https ports, See [Configuration](https://github.com/apache/apisix/blob/0bc65ea9acd726f79f80ae0abd8f50b7eb172e3d/conf/config-default.yaml#L99) |
| gateway.tls.certCAFilename | string | `""` | Filename be used in the gateway.tls.existingCASecret |
| gateway.tls.containerPort | int | `9443` | Container port the gateway listens on for HTTPS traffic |
| gateway.tls.enabled | bool | `true` | Enable HTTPS listeners |
| gateway.tls.existingCASecret | string | `""` | Specifies the name of Secret contains trusted CA certificates in the PEM format used to verify the certificate when APISIX needs to do SSL/TLS handshaking with external services (e.g. etcd) |
| gateway.tls.fallbackSNI | string | `""` | If set this, when the client doesn't send SNI during handshake, the fallback SNI will be used instead |
| gateway.tls.http2.enabled | bool | `true` | Enable HTTP/2 on the HTTPS listeners |
| gateway.tls.ip | string | `"0.0.0.0"` | which ip to listen on for API7 Gateway https service. |
| gateway.tls.nodePort | int | `nil` | The nodePort of kubernetes service, only used if gateway.type is NodePort. If not set, a random port will be assigned by Kubernetes. |
| gateway.tls.servicePort | int | `443` | Kubernetes service port for HTTPS traffic |
| gateway.tls.sslCiphers | string | `"ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:DHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA:ECDHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES256-SHA256:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:DES-CBC3-SHA"` | TLS cipher suites allowed to use, in OpenSSL cipher list format |
| gateway.tls.sslProtocols | string | `"TLSv1.2 TLSv1.3"` | TLS protocols allowed to use. |
| gateway.tls.sslSessionTickets | bool | `false` | Enable or disable TLS session tickets. Disabled by default because session tickets defeat Perfect Forward Secrecy (see https://github.com/mozilla/server-side-tls/issues/135) |
| gateway.type | string | `"NodePort"` | API7 Gateway service type for user access itself |
| global.imagePullSecrets | list | `[]` | Global Docker registry secret names as an array |
| graphql.maxSize | int | `1048576` | The maximum size in bytes of GraphQL queries the gateway parses when matching routes by GraphQL attributes (default 1MiB) |
| initContainer.image | string | `"busybox"` | Init container image |
| initContainer.tag | float | `1.28` | Init container tag |
| logs.accessLog | string | `"/dev/stdout"` | Access log path |
| logs.accessLogFormat | string | `"$remote_addr - $remote_user [$time_local] $http_host \\\"$request\\\" $status $body_bytes_sent $request_time \\\"$http_referer\\\" \\\"$http_user_agent\\\" $upstream_addr $upstream_status $upstream_response_time \\\"$upstream_scheme://$upstream_host$upstream_uri\\\""` | Access log format |
| logs.accessLogFormatEscape | string | `"default"` | Allows setting json or default characters escaping in variables |
| logs.enableAccessLog | bool | `true` | Enable access log or not, default true |
| logs.errorLog | string | `"/dev/stderr"` | Error log path |
| logs.errorLogLevel | string | `"warn"` | Error log level, Allowed values: `debug`, `info`, `notice`, `warn`, `error`, `crit`, `alert`, `or` `emerg` |
| logs.stream | object | `{"accessLog":"logs/access_stream.log","accessLogFormat":"$remote_addr [$time_local] $protocol $status $bytes_sent $bytes_received $session_time","accessLogFormatEscape":"default","enableAccessLog":false}` | Stream access log and error log configuration |
| logs.stream.accessLog | string | `"logs/access_stream.log"` | Stream access log path |
| logs.stream.accessLogFormat | string | `"$remote_addr [$time_local] $protocol $status $bytes_sent $bytes_received $session_time"` | Stream access log format |
| logs.stream.accessLogFormatEscape | string | `"default"` | Allows setting json or default characters escaping in variables for stream |
| logs.stream.enableAccessLog | bool | `false` | Enable stream access log or not, default false |
| nameOverride | string | `""` | String to partially override the chart fullname |
| nginx.enableCPUAffinity | bool | `true` | Bind nginx worker processes to CPUs |
| nginx.envs | list | `[]` | List of environment variable names allowed to be accessed within nginx (rendered as nginx `env` directives) |
| nginx.http | object | `{"charset":"utf-8","clientBodyTimeout":"60s","clientHeaderTimeout":"60s","clientMaxBodySize":0,"keepaliveTimeout":"60s","proxySslServerName":true,"realIpFrom":["127.0.0.1","unix:"],"realIpHeader":"X-Real-IP","realIpRecursive":"off","sendTimeout":"10s","underscoresInHeaders":"on","upstream":{"keepalive":320,"keepaliveRequests":1000,"keepaliveTimeout":"60s"},"variablesHashMaxSize":2048}` | Nginx HTTP subsystem configurations |
| nginx.http.charset | string | `"utf-8"` | The charset added to the "Content-Type" response header field, see [charset](http://nginx.org/en/docs/http/ngx_http_charset_module.html#charset) |
| nginx.http.clientBodyTimeout | string | `"60s"` | timeout for reading client request body, then 408 (Request Time-out) error is returned to the client |
| nginx.http.clientHeaderTimeout | string | `"60s"` | timeout for reading client request header, then 408 (Request Time-out) error is returned to the client |
| nginx.http.clientMaxBodySize | int | `0` | The maximum allowed size of the client request body. If exceeded, the 413 (Request Entity Too Large) error is returned to the client. Note that unlike Nginx, we don't limit the body size by default (0 means no limit). |
| nginx.http.keepaliveTimeout | string | `"60s"` | timeout during which a keep-alive client connection will stay open on the server side |
| nginx.http.proxySslServerName | bool | `true` | Enables or disables passing of the server name through TLS Server Name Indication extension (SNI, RFC 6066) when establishing a connection with the proxied HTTPS server |
| nginx.http.realIpFrom | list | `["127.0.0.1","unix:"]` | Trusted addresses from which the real IP header is honored, see [set_real_ip_from](http://nginx.org/en/docs/http/ngx_http_realip_module.html#set_real_ip_from) |
| nginx.http.realIpHeader | string | `"X-Real-IP"` | The request header used to determine the client's real IP address, see [real_ip_header](http://nginx.org/en/docs/http/ngx_http_realip_module.html#real_ip_header) |
| nginx.http.realIpRecursive | string | `"off"` | Whether to search for the real IP recursively when the header set in nginx.http.realIpHeader contains multiple addresses, see [real_ip_recursive](http://nginx.org/en/docs/http/ngx_http_realip_module.html#real_ip_recursive) |
| nginx.http.sendTimeout | string | `"10s"` | timeout for transmitting a response to the client, then the connection is closed |
| nginx.http.underscoresInHeaders | string | `"on"` | Enable the use of underscores in client request header fields |
| nginx.http.upstream | object | `{"keepalive":320,"keepaliveRequests":1000,"keepaliveTimeout":"60s"}` | Keepalive settings for connections from the gateway to upstream servers |
| nginx.http.upstream.keepalive | int | `320` | Maximum number of idle keepalive connections to upstream servers that are preserved in the cache of each worker process. When this number is exceeded, the least recently used connections are closed |
| nginx.http.upstream.keepaliveRequests | int | `1000` | Maximum number of requests that can be served through one keepalive connection. After the maximum number of requests is made, the connection is closed |
| nginx.http.upstream.keepaliveTimeout | string | `"60s"` | Timeout during which an idle keepalive connection to an upstream server will stay open |
| nginx.http.variablesHashMaxSize | int | `2048` | The maximum size of the nginx variables hash table |
| nginx.maxPendingTimers | int | `16384` | Maximum number of pending timers. Increase it if you see "too many pending timers" error |
| nginx.maxRunningTimers | int | `4096` | Maximum number of running timers. Increase it if you see "lua_max_running_timers are not enough" error |
| nginx.workerConnections | string | `"10620"` | The maximum number of connections that each worker process can open |
| nginx.workerProcesses | string | `"auto"` | The number of nginx worker processes. `auto` means the number of CPU cores |
| nginx.workerRlimitNofile | string | `"20480"` | The number of files a worker process can open, should be larger than nginx.workerConnections |
| nginx.workerShutdownTimeout | string | `"240s"` | Timeout for a graceful shutdown of worker processes |
| openapiToMcp.enabled | bool | `false` | Enable or disable the OpenAPI-to-MCP sidecar. Required when using the `openapi-to-mcp` or `mcp-tools-acl` plugins. The container runs alongside the gateway in the same pod and is reached on 127.0.0.1. |
| openapiToMcp.image.pullPolicy | string | `"IfNotPresent"` | OpenAPI-to-MCP image pull policy |
| openapiToMcp.image.repository | string | `"api7/openapi-to-mcp"` | OpenAPI-to-MCP image repository |
| openapiToMcp.image.tag | string | `"1.0.2"` | OpenAPI-to-MCP image tag |
| openapiToMcp.port | int | `3000` | Port that the sidecar listens on. Must match the `port` configured under `plugin_attr.openapi-to-mcp` in the gateway config (defaults to 3000). |
| openapiToMcp.resources | object | `{}` | Resources for the OpenAPI-to-MCP sidecar container. |
| pluginAttrs | object | `{}` | Set APISIX plugin attributes, see [config-default.yaml](https://github.com/apache/apisix/blob/master/conf/config-default.yaml#L376) for more details |
| rbac.create | bool | `false` | Whether RBAC resources (ClusterRole and ClusterRoleBinding) should be created |
| serviceAccount.annotations | object | `{}` | Annotations to add to the ServiceAccount |
| serviceAccount.create | bool | `false` | Whether a ServiceAccount should be created for the gateway pods |
| serviceAccount.name | string | `""` | Name of the ServiceAccount to use. If not set and create is true, a name is generated from the chart fullname |
| serviceMonitor | object | `{"annotations":{},"containerPort":9091,"enabled":false,"interval":"15s","labels":{},"metricPrefix":"apisix_","name":"","namespace":"","nodePort":null,"path":"/apisix/prometheus/metrics"}` | Observability configuration. ref: https://apisix.apache.org/docs/apisix/plugins/prometheus/ |
| serviceMonitor.annotations | object | `{}` | @param serviceMonitor.annotations ServiceMonitor annotations |
| serviceMonitor.containerPort | int | `9091` | container port where the metrics are exposed |
| serviceMonitor.enabled | bool | `false` | Enable or disable API7 Gateway serviceMonitor |
| serviceMonitor.interval | string | `"15s"` | interval at which metrics should be scraped |
| serviceMonitor.labels | object | `{}` | @param serviceMonitor.labels ServiceMonitor extra labels |
| serviceMonitor.metricPrefix | string | `"apisix_"` | prefix of the metrics |
| serviceMonitor.name | string | `""` | name of the serviceMonitor, by default, it is the same as the apisix fullname |
| serviceMonitor.namespace | string | `""` | namespace where the serviceMonitor is deployed, by default, it is the same as the namespace of the apisix |
| serviceMonitor.nodePort | int | `nil` | The nodePort of kubernetes service, only used if gateway.type is NodePort. If not set, a random port will be assigned by Kubernetes. |
| serviceMonitor.path | string | `"/apisix/prometheus/metrics"` | path of the metrics endpoint |
| soapProxy.enabled | bool | `false` | Enable or disable the SOAP proxy, this component is disabled by default, when use soap-proxy plugin in API7, you need to enable this component. |
| soapProxy.image.pullPolicy | string | `"IfNotPresent"` | SOAP proxy image pull policy |
| soapProxy.image.repository | string | `"api7/soap-proxy"` | SOAP proxy image repository |
| soapProxy.image.tag | string | `"1.0.0"` | SOAP proxy image tag |
| updateStrategy | object | `{}` | Update strategy of the workload (Deployment or DaemonSet), e.g. `type: RollingUpdate` |
| vault.enabled | bool | `false` | Enable or disable the vault integration |
| vault.host | string | `""` | The host address where the vault server is running. |
| vault.prefix | string | `""` | Prefix allows you to better enforcement of policies. |
| vault.timeout | int | `10` | HTTP timeout for each request. |
| vault.token | string | `""` | The generated token from vault instance that can grant access to read data from the vault. |

## Upgrading

### To 0.1.11

Remove configuration items such as `plugins`, `stream_plugins`, and `custom_plugins` that are no longer needed in API7 EE.

**This version of the helm chart needs to be used with API7 EE gateway version 3.2.16.3 or above.**
