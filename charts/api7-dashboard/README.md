Helm Chart for API7-Dashboard
==============================

This is the helm chart for [api7-dashboard](https://github.com/api7/api7-dashboard).

Prerequisites
-------------

Before you go ahead, please make sure that you have installed [helm](https://helm.sh) in the environment that you'll operate the Kubernetes cluster.

Next, since we don't have a private online repository for these enterprise-edition projects, you should clone/downlod this project to that environment.

Quick Start
-----------

```sh
cd /path/to/api7-helm-chart/chart/api7-dashboard
helm dependency update .
```

Images for api7-dashboard is private and never should be uploaded to public image registries like [dockerhub](https://hub.docker.com), so make sure the image for api7-dashboard was stashed in a registry that can be accessed from the Kubernetes cluster.

```sh
helm install api7-dashboard . -n api7 \
  --set image.repository=api7-dashboard \
  --set service.type=NodePort \
  --set image.tag=2.8.2206 \
  --post-renderer /path/to/api7-helm-chart/charts/api7-dashboard/kustomize/kustomize \
  --create-namespace
```

When you execute the above command, change the registry, repository and tag according to your situation.

Checking the running status of api7-dashboard.

```sh
kubectl get deploy,service -n api7
NAME                                                     READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/api7                                     1/1     1            1           19h
deployment.apps/api7-dashboard                           0/1     1            0           55m
deployment.apps/api7-dashboard-kube-state-metrics        1/1     1            1           55m
deployment.apps/api7-dashboard-prometheus-alertmanager   0/1     1            0           55m
deployment.apps/api7-dashboard-prometheus-pushgateway    1/1     1            1           55m
deployment.apps/api7-dashboard-prometheus-server         0/1     1            0           55m

NAME                                              TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE
service/api7-dashboard                            ClusterIP   10.96.172.234   <none>        9000/TCP                     55m
service/api7-dashboard-kube-state-metrics         ClusterIP   10.96.114.79    <none>        8080/TCP                     55m
service/api7-dashboard-prometheus-alertmanager    ClusterIP   10.96.190.9     <none>        80/TCP                       55m
service/api7-dashboard-prometheus-node-exporter   ClusterIP   None            <none>        9100/TCP                     55m
service/api7-dashboard-prometheus-pushgateway     ClusterIP   10.96.131.137   <none>        9091/TCP                     55m
service/api7-dashboard-prometheus-server          ClusterIP   10.96.91.4      <none>        80/TCP                       55m
service/api7-etcd                                 ClusterIP   10.96.198.213   <none>        2379/TCP,2380/TCP            19h
service/api7-etcd-headless                        ClusterIP   None            <none>        2379/TCP,2380/TCP            19h
service/api7-gateway                              NodePort    10.96.202.73    <none>        80:32443/TCP,443:32728/TCP   19h
```

By default it also installed Prometheus components.


Cleanup
-------

```sh
helm uninstall api7-dashboard -n api7
```

Customization
-------------

See [values.yaml](./values.yaml) to learn all the config items. Here the most common scenarios will be illustrated.

### How to control the desired replica count for api7 deployment?

Use `replicaCount` item.

```sh
helm install api7-dashboard -n api7 --set replicaCount=N
```

### I don't like to install the prometheus servers, becuase I already have an existing one.

Disable the `promethues.builtin` and specify your existing Prometheus server addresses.

```sh
helm install api7-dashboard -n api7 \
	--set prometheus.builtin=false \
	--set prometheus.clusters={https://prometheus-0,https://prometheus-1,https://promtheus-2}
```

### Command for kind
Import api7-dashboard image:
```shell
kind load docker-image --nodes kind-control-plane --name kind api7-dashboard:2.8.2206
```

Expose service
```shell
kubectl port-forward service/api7-dashboard 9000:9000 -n api7
```
