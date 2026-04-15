# AISIX Helm Chart

A Helm chart for [AISIX](https://github.com/api7/aisix) — an open source, high-performance AI Gateway and LLM proxy built in Rust.

## Prerequisites

- Kubernetes 1.21+
- Helm 3.7+

## Installing the Chart

```bash
helm repo add api7 https://charts.api7.ai
helm repo update

helm install my-aisix api7/aisix \
  --set deployment.admin.adminKey[0].key=<your-admin-key>
```

## Uninstalling the Chart

```bash
helm uninstall my-aisix
```

## Configuration

The following table lists the key configurable parameters. See `values.yaml` for the full list.

| Parameter | Description | Default |
|-----------|-------------|---------|
| `image.repository` | AISIX image repository | `ghcr.io/api7/aisix` |
| `image.tag` | AISIX image tag | `0.1` |
| `replicaCount` | Number of replicas | `1` |
| `deployment.admin.adminKey` | Admin API key list | `[{key: "changeme"}]` |
| `deployment.admin.existingSecret` | Existing Secret for admin key | `""` |
| `deployment.etcd.host` | External etcd hosts (when `etcd.enabled=false`) | `["http://etcd.host:2379"]` |
| `deployment.etcd.prefix` | etcd key prefix | `/aisix` |
| `server.proxy.listen` | Proxy API listen address | `0.0.0.0:3000` |
| `server.admin.listen` | Admin API listen address | `0.0.0.0:3001` |
| `proxyService.type` | Proxy Service type | `NodePort` |
| `adminService.type` | Admin Service type | `ClusterIP` |
| `etcd.enabled` | Install bundled etcd | `true` |
| `ingress.enabled` | Enable Ingress for proxy | `false` |
| `adminIngress.enabled` | Enable Ingress for admin | `false` |
| `autoscaling.enabled` | Enable HPA | `false` |

## Using an Existing Secret for the Admin Key

```bash
kubectl create secret generic aisix-admin-secret \
  --from-literal=admin-key=<your-strong-key>

helm install my-aisix api7/aisix \
  --set deployment.admin.existingSecret=aisix-admin-secret
```

## Using an External etcd

```bash
helm install my-aisix api7/aisix \
  --set etcd.enabled=false \
  --set deployment.etcd.host[0]="http://my-etcd:2379" \
  --set deployment.admin.adminKey[0].key=<your-admin-key>
```
