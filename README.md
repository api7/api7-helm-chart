# APISEVEN Helm Charts

This project collects related chart of projects in [api7.ai](https://api7.ai).

Detailed instructions are enrolled in the README of each chart.

## Projects

* [api7](./chart/api7/README.md)
* [api7-dashboard](./chart/api7-dashboard/README.md)
* [api7-ingress](./chart/api7-ingress/README.md)

## Install

```shell
sh install.sh [docker registry]
```

## Check if all pods are running

```shell
kubectl get pod,svc -n api7
```

## Use `ApisixRoute` Resource

```shell
kubectl apply -f - <<EOF
apiVersion: apisix.apache.org/v2beta1
kind: ApisixRoute
metadata:
  name: httpbin-route
  namespace: api7
spec:
  http:
  - name: rule1
    match:
      hosts:
      - httpbin.com
      paths:
      - /ip
    backend:
      serviceName: httpbin-service
      servicePort: 80
EOF
```

And query the route list in dashboard.

Get Node Port of Dashboard, In this example, the Node Port is `31151`.

```
kubectl get svc -n api7
api7-dashboard-apisix-dashboard          NodePort    10.96.196.66    <none>        80:31151/TCP                 20m

```

Visit Dashboard in browser.

```
http://node_ip:31151
```
