## AISIX AI Gateway

AISIX is an open-source, high-performance AI Gateway and LLM proxy.

This chart bootstraps AISIX on a Kubernetes cluster using [Helm](https://helm.sh).

## Prerequisites

* Kubernetes 1.21+
* Helm 3.7+

## Install

```sh
helm repo add api7 https://charts.api7.ai
helm repo update

helm install [RELEASE_NAME] api7/aisix
```

## Uninstall

```sh
helm delete [RELEASE_NAME]
```

## Connecting to API7 EE Control Plane

When using AISIX with an API7 EE control plane, you need to provide mTLS credentials
via environment variables: `API7_CONTROL_PLANE_ENDPOINTS`, `API7_GATEWAY_GROUP_ID`,
`API7_CONTROL_PLANE_CA`, `API7_CONTROL_PLANE_CERT`, and `API7_CONTROL_PLANE_KEY`.

> **Note:** The CA, cert, and key values are multi-line PEM strings. Use `--from-file`
> when creating the Secret to preserve line breaks correctly.

**Step 1: Save your certificates to files**

```sh
# Save CA certificate
cat > ca.pem << 'EOF'
-----BEGIN CERTIFICATE-----
<your-ca-certificate>
-----END CERTIFICATE-----
EOF

# Save client certificate
cat > cert.pem << 'EOF'
-----BEGIN CERTIFICATE-----
<your-client-certificate>
-----END CERTIFICATE-----
EOF

# Save client private key
cat > key.pem << 'EOF'
-----BEGIN PRIVATE KEY-----
<your-private-key>
-----END PRIVATE KEY-----
EOF
```

**Step 2: Create a Kubernetes Secret from the certificate files**

```sh
kubectl create secret generic aisix-cp-creds \
  --from-file=API7_CONTROL_PLANE_CA=ca.pem \
  --from-file=API7_CONTROL_PLANE_CERT=cert.pem \
  --from-file=API7_CONTROL_PLANE_KEY=key.pem
```

**Step 3: Install the chart**

```sh
helm install my-aisix api7/aisix \
  --set extraEnvVarsSecret=aisix-cp-creds \
  --set extraEnvVars[0].name=API7_CONTROL_PLANE_ENDPOINTS \
  --set 'extraEnvVars[0].value=["https://<dp-manager-host>:<port>"]' \
  --set extraEnvVars[1].name=API7_GATEWAY_GROUP_ID \
  --set extraEnvVars[1].value=<gateway-group-id> \
  --set etcd.enabled=false
```

Replace `<dp-manager-host>:<port>` and `<gateway-group-id>` with the values from
your API7 EE console under **Gateway Group → Connection Info**.

## Parameters

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| admin | object | `{"annotations":{},"containerPort":3001,"enabled":true,"ingress":{"annotations":{},"enabled":false,"hosts":[{"host":"aisix-admin.local","paths":["/ui","/aisix/admin"]}],"tls":[]},"ip":"0.0.0.0","servicePort":3001,"type":"ClusterIP"}` | AISIX admin service settings (port 3001) — Admin API and UI |
| admin.containerPort | int | `3001` | Container port |
| admin.enabled | bool | `true` | Enable admin service |
| admin.ingress | object | `{"annotations":{},"enabled":false,"hosts":[{"host":"aisix-admin.local","paths":["/ui","/aisix/admin"]}],"tls":[]}` | Using ingress access AISIX admin service |
| admin.ingress.annotations | object | `{}` | Ingress annotations |
| admin.ip | string | `"0.0.0.0"` | which ip to listen on for the admin service |
| admin.servicePort | int | `3001` | Service port |
| admin.type | string | `"ClusterIP"` | admin service type |
| affinity | object | `{}` | Set affinity for deploy |
| autoscaling.enabled | bool | `false` |  |
| autoscaling.maxReplicas | int | `10` |  |
| autoscaling.minReplicas | int | `1` |  |
| autoscaling.targetCPUUtilizationPercentage | int | `80` |  |
| autoscaling.targetMemoryUtilizationPercentage | int | `80` |  |
| autoscaling.version | string | `"v2"` | HPA version, the value is "v2" or "v2beta1", default "v2" |
| deployment.admin.adminKey | list | `[{"key":"changeme"}]` | Admin API key. Used to create an internal Secret when existingSecret is not set. WARNING: change this before deploying to production. |
| deployment.admin.existingSecret | string | `""` | Name of an existing Secret that contains an admin key field. If set, adminKey above is ignored and the key is read from the Secret. |
| deployment.admin.existingSecretKey | string | `"admin-key"` | Key inside the existing Secret that holds the admin key value |
| deployment.etcd.host | list | `["http://etcd.host:2379"]` | List of etcd hosts. Ignored when etcd.enabled is true (auto-constructed). |
| deployment.etcd.prefix | string | `"/aisix"` | Key prefix used by aisix in etcd |
| deployment.etcd.timeout | int | `30` | etcd request timeout in seconds |
| etcd | object | `{"auth":{"rbac":{"create":false,"rootPassword":""},"tls":{"certFilename":"","certKeyFilename":"","enabled":false,"existingSecret":"","sni":"","verify":false}},"enabled":false,"image":{"repository":"api7/etcd"},"replicaCount":3,"service":{"port":2379}}` | etcd subchart (bitnami/etcd) |
| etcd.auth.rbac.create | bool | `false` | No authentication by default. Enable RBAC (set create: true and configure rootPassword) for production or multi-tenant clusters to prevent unauthenticated etcd access. |
| etcd.auth.rbac.rootPassword | string | `""` | root password for etcd. Requires etcd.auth.rbac.create to be true. |
| etcd.auth.tls.certFilename | string | `""` | etcd client cert filename using in etcd.auth.tls.existingSecret |
| etcd.auth.tls.certKeyFilename | string | `""` | etcd client cert key filename using in etcd.auth.tls.existingSecret |
| etcd.auth.tls.enabled | bool | `false` | enable etcd client certificate |
| etcd.auth.tls.existingSecret | string | `""` | name of the secret contains etcd client cert |
| etcd.auth.tls.sni | string | `""` | specify the TLS Server Name Indication extension, the ETCD endpoint hostname will be used when this setting is unset. |
| etcd.auth.tls.verify | bool | `false` | whether to verify the etcd endpoint certificate when setup a TLS connection to etcd |
| etcd.enabled | bool | `false` | Install etcd as a subchart. Set false to use an external etcd. |
| extraEnvVars | list | `[]` | Additional environment variables |
| extraEnvVarsCM | string | `""` |  |
| extraEnvVarsSecret | string | `""` |  |
| extraInitContainers | list | `[]` | Additional init containers |
| extraVolumeMounts | list | `[]` | Additional volume mounts |
| extraVolumes | list | `[]` | Additional volumes |
| fullnameOverride | string | `""` |  |
| gateway | object | `{"annotations":{},"containerPort":3000,"externalIPs":[],"externalTrafficPolicy":"Cluster","ingress":{"annotations":{},"enabled":false,"hosts":[{"host":"aisix.local","paths":["/"]}],"tls":[]},"ip":"0.0.0.0","nodePort":"","servicePort":3000,"type":"NodePort"}` | AISIX proxy service settings (port 3000) — user traffic |
| gateway.containerPort | int | `3000` | Container port |
| gateway.externalIPs | list | `[]` | IPs for which nodes in the cluster will also accept traffic for the service |
| gateway.externalTrafficPolicy | string | `"Cluster"` | Setting how the Service route external traffic |
| gateway.ingress | object | `{"annotations":{},"enabled":false,"hosts":[{"host":"aisix.local","paths":["/"]}],"tls":[]}` | Using ingress access AISIX proxy service |
| gateway.ingress.annotations | object | `{}` | Ingress annotations |
| gateway.ip | string | `"0.0.0.0"` | which ip to listen on for the proxy service |
| gateway.nodePort | string | `""` | Optional static nodePort (only relevant when type is NodePort) |
| gateway.servicePort | int | `3000` | Service port |
| gateway.type | string | `"NodePort"` | proxy service type |
| global.imagePullSecrets | list | `[]` | Global Docker registry secret names as an array |
| image.pullPolicy | string | `"IfNotPresent"` | AISIX image pull policy |
| image.repository | string | `"ghcr.io/api7/aisix"` | AISIX image repository |
| image.tag | string | `"0.1.0"` | AISIX image tag; overrides the chart appVersion |
| livenessProbe | object | `{}` | Kubernetes liveness probe override |
| nameOverride | string | `""` |  |
| nodeSelector | object | `{}` | Node labels for pod assignment |
| podAnnotations | object | `{}` | Annotations to add to the pod |
| podLabels | object | `{}` | Labels to add to the pod |
| podSecurityContext | object | `{}` | Set the securityContext for AISIX pods |
| readinessProbe | object | `{}` | Kubernetes readiness probe override |
| replicaCount | int | `1` | Number of AISIX replicas |
| resources | object | `{}` | Set pod resource requests & limits |
| securityContext | object | `{}` | Set the securityContext for AISIX container |
| serviceAccount.annotations | object | `{}` | Annotations to add to the service account |
| serviceAccount.create | bool | `false` | Specifies whether a service account should be created |
| serviceAccount.name | string | `""` | The name of the service account to use. |
| timezone | string | `""` | timezone for the container, e.g. "UTC" or "Asia/Shanghai" |
| tolerations | list | `[]` | List of node taints to tolerate |
| updateStrategy | object | `{}` |  |
