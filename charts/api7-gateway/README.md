Helm Chart for API7 Gateway
====================

This is the helm chart for [api7-gateway](https://github.com/api7/api7-gateway) project. It helps you to install API7 Gateway on Kubernetes easily.

Prerequisites
-------------

Before you go ahead, please make sure you have installed [helm](https://helm.sh) in the environment that you'll operate the Kubernetes cluster.

Next, since we don't have a private online repository for these enterprise-edition projects, you should clone/download this project to that project.

Quick Start
------------

```sh
cd /path/to/api7-helm-chart/charts/api7-gateway
helm dependency update .
```

Images for api7 is private and never should be uploaded to public image registries like [dockerhub](https://hub.docker.com), so make sure the image for api7 was stashed in a registry that can be accessed from the Kubernetes cluster.

```sh
helm install api7-gateway . -n api7 \
  --set image.repository=api7-gateway \
  --set image.tag=2.8.2206 \
  --set etcd.prefix=/api7/417061816636539665 \
  --set etcd.hosts={http://api7-dashboard-etcd.api7.svc.cluster.local:2379} \
  --create-namespace
```

When you execute the above command, change the registry, repository and image according to your situation.

Check the running status of API7 Gateway.

```sh
kubectl get deploy,svc,sts -n api7
NAME                   READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/api7   1/1     1            1           3m47s

NAME                         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE
service/api7-gateway         NodePort    10.96.202.73    <none>        80:32443/TCP,443:32728/TCP   3m47s
```

Now sending requests to the `api7-gateway` service to verify whether it's really up.

Cleanup
-------

```sh
helm uninstall api7 -n api7
```

Customization
-------------

See [values.yaml](./values.yaml) to learn all the config items. Here the most common scenarios will be illustrated.

### How to control the desired replica count for api7 deployment?

Use `replicaCount` item.

```sh
helm install api7 . -n api7 --set replicaCount=N
```

### I'd like to create a LoadBalancer api7 service so that my gateway can be accessed through SLB

Use `gateway.type` item, candidate value can be all the supported Kubernetes [Service type](https://kubernetes.io/docs/concepts/services-networking/service/#publishing-services-service-types).

```sh
helm install api7 -n api7 --set gateway.type=LoadBalancer
```
