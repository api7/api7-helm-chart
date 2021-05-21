Helm Chart for API7
====================

This is the helm chart for [api7](https://github.com/api7/api7) project. It helps you to install api7 on Kubernetes easily.

Prerequisites
-------------

Before you go ahead, please make sure you have installed [helm](https://helm.sh) in the environment that you'll operate the Kubernetes cluster.

Next, since we don't have a private online repository for these enterprise-edition projects, you should clone/download this project to that project.

Quick Start
------------

```sh
cd /path/to/api7-helm-chart/chart/api7
helm dependency update .
```

Firstly we should update the dependency in your local. Now we will try to install api7 to Kubernetes cluster, we assume the target namespace is `api7`.
```sh
kubectl create namespace api7
```

Images for api7 is private and never should be uploaded to public image registries like [dockerhub](https://hub.docker.com), so make sure the image for api7 was stashed in a registry that can be accessed from the Kubernetes cluster.

```sh
helm install api7 . -n api7 \
  --set image.registry=localhost:5000 \
  --set image.repository=api7/api7 \
  --set image.tag=v2.1ee
```

When you execute the above command, change the registry, repository and image according to your situation.

Check the running status of api7.


```sh
kubectl get deploy,svc,sts -n api7
NAME                   READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/api7   1/1     1            1           3m47s

NAME                         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE
service/api7-etcd            ClusterIP   10.96.198.213   <none>        2379/TCP,2380/TCP            3m47s
service/api7-etcd-headless   ClusterIP   None            <none>        2379/TCP,2380/TCP            3m47s
service/api7-gateway         NodePort    10.96.202.73    <none>        80:32443/TCP,443:32728/TCP   3m47s
```

By default the above command install an ETCD cluster in the same namespace.

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

### I don't like to install the builtin ETCD cluster, because I already have an existing one.

Disable the `etcd.builtin` option and specify your existing ETCD enpoints.

```sh
helm install api7 -n api7 \
  --set etcd.builtin=false \
  --set etcd.hosts={https://etcd-host1:2379,https://etcd-host2:2379,https://etcd-host3:2379}
```

Note if you use an existing cluster, `initContainers` will not be set to the api7 pod, so there is no such a step to wait until ETCD cluster is ready.
