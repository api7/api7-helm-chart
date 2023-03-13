Helm Chart for API7 Dashboard
==============================

This is the helm chart for the refactoring [api7-dashboard](https://github.com/api7/dashboard).

Prerequisites
-------------

Before you go ahead, please make sure that you have installed [helm](https://helm.sh) in the environment that you'll operate the Kubernetes cluster.

Next, since we don't have a private online repository for these enterprise-edition projects, you should clone/downlod this project to that environment.

Quick Start
-----------

```sh
cd /path/to/api7-helm-chart/charts/dashboard
helm dependency update .
```

Images for API7 Dashboard is private and never should be uploaded to public image registries like [dockerhub](https://hub.docker.com), so make sure the image for API7 Dashboard was stashed in a registry that can be accessed from the Kubernetes cluster.

```sh
helm install dashboard-release . -n api7ee \
  --set image.registry=api7ee.azurecr.io \
  --set image.repository=dashboard \
  --set service.type=NodePort \
  --set image.tag=dev \
  --create-namespace
```

When you execute the above command, change the registry, repository and tag according to your situation.

Checking the running status of api7-dashboard.

```sh
kubectl get deploy,service -n api7ee
NAME                                                     READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/api7-dashboard                           0/1     1            0           55m


NAME                                              TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE
service/api7-dashboard                            ClusterIP   10.96.172.234   <none>        9000/TCP                     55m
```

By default it also installed Prometheus components.


Cleanup
-------

```sh
helm uninstall dashboard-release -n api7ee
```

Customization
-------------

See [values.yaml](./values.yaml) to learn all the config items. Here the most common scenarios will be illustrated.

### How to control the desired replica count for api7 deployment?

Use `replicaCount` item.

```sh
helm install api7-dashboard -n api7ee --set replicaCount=N
```

### Command for kind
Import api7-dashboard image:
```shell
kind load docker-image --nodes kind-control-plane --name kind api7ee.azurecr.io/dashboard:dev
```

Expose service
```shell
kubectl port-forward service/api7-dashboard 9000:9000 -n api7ee
```
