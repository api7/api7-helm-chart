#!/bin/sh

# import docker images
registry=$1
# api7-gateway
docker load -i ./images/*
docker tag apisixacr.azurecr.cn/api7-gateway:2.3 $registry/api7/api7-gateway:2.3
docker push $registry/api7/api7-gateway:2.3

# api7-dashboard
docker tag apisixacr.azurecr.cn/api7-dashboard:2.3 $registry/api7/api7-dashboard:2.3
docker push $registry/api7/api7-dashboard:2.3

# prometheus
docker tag prom/prometheus:v2.25.0 $registry/prom/prometheus:v2.25.0
docker push $registry/prom/prometheus:v2.25.0

# api7-ingress
docker tag api7/api7-ingress-controller:poc $registry/api7/api7-ingress:1.1
docker push $registry/api7/api7-ingress:1.1

# httpbin
docker tag kennethreitz/httpbin $registry/kennethreitz/httpbin
docker push $registry/kennethreitz/httpbin

# helm install

# api7-geteway
helm dependency update ./chart/api7
sed -i -e "s%#localhost:5000#%`echo $registry`%g" ./chart/api7/api7.yaml
helm install api7 ./chart/api7 -n api7 --values ./chart/api7/api7.yaml

# api7-dashboard
helm dependency update ./chart/api7-dashboard
sed -i -e "s%#localhost:5000#%`echo $registry`%g" ./chart/api7-dashboard/api7-dashboard.yaml
helm install api7-dashboard ./chart/api7-dashboard -n api7 --values ./chart/api7-dashboard/api7-dashboard.yaml

# api7-ingress
sed -i -e "s%#localhost:5000#%`echo $registry`%g" ./chart/api7-ingress/api7-ingress.yaml
helm install api7-ingress ./chart/api7-ingress -n api7  --values ./chart/api7-ingress/api7-ingress.yaml
helm uninstall api7-ingress -n api7
