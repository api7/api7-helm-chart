# AISIX Helm Chart

A Helm chart for [AISIX](https://github.com/api7/aisix) — an open-source, high-performance AI Gateway and LLM proxy built in Rust.

## Prerequisites

- Kubernetes 1.21+
- Helm 3.7+

## Installing the Chart

```bash
helm repo add api7 https://charts.api7.ai
helm repo update

# Recommended: use an existing Secret for the admin key
kubectl create secret generic aisix-admin-secret \
  --from-literal=admin-key=<your-strong-key>

helm install my-aisix api7/aisix \
  --set deployment.admin.existingSecret=aisix-admin-secret
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
| `image.tag` | AISIX image tag | `0.1.0` |
| `replicaCount` | Number of replicas | `1` |
| `deployment.admin.adminKey` | Admin API key (used to create an internal Secret) | `[{key: "changeme"}]` |
| `deployment.admin.existingSecret` | Existing Secret for admin key (overrides adminKey) | `""` |
| `deployment.etcd.host` | External etcd hosts (when `etcd.enabled=false`) | `["http://etcd.host:2379"]` |
| `deployment.etcd.prefix` | etcd key prefix | `/aisix` |
| `gateway.type` | Proxy Service type | `NodePort` |
| `gateway.servicePort` | Proxy Service port | `3000` |
| `gateway.ingress.enabled` | Enable Ingress for proxy | `false` |
| `admin.enabled` | Enable admin Service and port | `true` |
| `admin.type` | Admin Service type | `ClusterIP` |
| `admin.servicePort` | Admin Service port | `3001` |
| `admin.ingress.enabled` | Enable Ingress for admin | `false` |
| `etcd.enabled` | Install bundled etcd | `false` |
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
  --set "deployment.etcd.host[0]=http://my-etcd:2379" \
  --set deployment.admin.existingSecret=aisix-admin-secret
```
