Helm Chart for API7 Devportal
==============================

This is the helm chart for the refactoring [api7-dashboard](https://github.com/api7/dashboard).

Prerequisites
-------------

Before you go ahead, please make sure that you have installed [helm](https://helm.sh) in the environment that you'll operate the Kubernetes cluster.

Next, since we don't have a private online repository for these enterprise-edition projects, you should clone/downlod this project to that environment.

Quick Start
-----------

```sh
cd /path/to/api7-helm-chart/charts/devportal
helm dependency update .
```

Images for API7 Devportal is private and never should be uploaded to public image registries like [dockerhub](https://hub.docker.com), so make sure the image for API7 Devportal was stashed in a registry that can be accessed from the Kubernetes cluster.

```sh
helm install devportal-release . -n api7ee \
  --set image.registry=api7ee.azurecr.io \
  --set image.repository=devportal \
  --set service.type=NodePort \
  --set image.tag=dev \
  --create-namespace
```

When you execute the above command, change the registry, repository and tag according to your situation.

Checking the running status of devportal.

```sh
$ kubectl get deploy,service -n api7ee                     
NAME                                READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/devportal-release   1/1     1            1           2m50s

NAME                                      TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)             AGE
service/devportal-release                 NodePort    10.96.75.12   <none>        9100:31870/TCP      2m50s
service/devportal-release-etcd            ClusterIP   10.96.19.76   <none>        2379/TCP,2380/TCP   2m50s
service/devportal-release-etcd-headless   ClusterIP   None          <none>        2379/TCP,2380/TCP   2m50s
```


Cleanup
-------

```sh
helm uninstall devportal-release -n api7ee
```

Customization
-------------

See [values.yaml](./values.yaml) to learn all the config items. Here the most common scenarios will be illustrated.

### How to control the desired replica count for api7 deployment?

Use `replicaCount` item.

```sh
helm install devportal -n api7ee --set replicaCount=N
```

### Command for kind
Import devportal image:
```shell
kind load docker-image --nodes kind-control-plane --name kind api7ee.azurecr.io/devportal:dev
```

Expose service
```shell
kubectl port-forward service/devportal-release 9100:9100 -n api7ee
```
