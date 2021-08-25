Helm Chart for satellite
====================

This is the helm chart for satellite project. It helps you to install satellite on Kubernetes easily.

Prerequisites
-------------

Before you go ahead, please make sure you have installed [helm](https://helm.sh) in the environment that you'll operate the Kubernetes cluster.

Next, since we don't have a private online repository for these enterprise-edition projects, you should clone/download this project to that project.

Quick Start
------------

```sh
cd /path/to/api7-helm-chart/chart/satellite
helm dependency update .
```

Firstly we should update the dependency in your local. Now we will try to install satellite to Kubernetes cluster, we assume the target namespace is `api7`.
```sh
kubectl create namespace api7
```

Images for satellite is private and never should be uploaded to public image registries like [dockerhub](https://hub.docker.com), so make sure the image for satellite was stashed in a registry that can be accessed from the Kubernetes cluster.

Satellite will send data to OAP server, so an correct oap domain is needed.

```sh
helm install satellite . -n api7 \
  --set image.registry=localhost:5000 \
  --set image.repository=api7/satellite \
  --set image.tag=v2.1ee
  --set satellite.oap.domain=oap.com
```

When you execute the above command, change the registry, repository, tag and oap server domain according to your situation.

Check the running status of satellite.


```sh
kubectl get deploy,svc,sts -n api7
NAME                   READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/api7   1/1     1            1           3m47s

NAME                         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE
service/api7-satellite            ClusterIP   10.96.198.211   <none>        11800/TCP,12800/TCP            3m01s
```

Now satellite will try to find the api7-gateway in Kubernetes cluster and fetch Prometheus metrics then sending meter data to the OAP server.

Cleanup
-------

```sh
helm uninstall satellite -n api7
```
