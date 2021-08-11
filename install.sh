#!/bin/sh

# $1 registry
registry=$1

# import docker images
for file in ./images/*
do
    docker load -i $file
done

# api7-gateway
docker tag api7/api7-gateway:poc $registry/api7/api7-gateway:poc
docker push $registry/api7/api7-gateway:poc

# api7-dashboard
docker tag api7/api7-dashboard:poc $registry/api7/api7-dashboard:poc
docker push $registry/api7/api7-dashboard:poc

# api7-ingress
docker tag api7/api7-ingress-controller:poc $registry/api7/api7-ingress:poc
docker push $registry/api7/api7-ingress:poc

# httpbin
docker pull kennethreitz/httpbin
docker tag kennethreitz/httpbin $registry/kennethreitz/httpbin
docker push $registry/kennethreitz/httpbin

# helm install
kubectl create ns api7

# api7-geteway
echo "install api7-gateway"
helm dependency update ./chart/api7
sed -i -e "s%#localhost:5000#%`echo $registry`%g" ./chart/api7/api7.yaml
helm install api7 ./chart/api7 -n api7 --values ./chart/api7/api7.yaml

# api7-dashboard
echo "install api7-dashboard"
sed -i -e "s%#localhost:5000#%`echo $registry`%g" ./chart/api7-dashboard/api7-dashboard.yaml
helm install api7-dashboard ./chart/api7-dashboard -n api7 --values ./chart/api7-dashboard/api7-dashboard.yaml

# api7-ingress
echo "install api7-ingress"
sed -i -e "s%#localhost:5000#%`echo $registry`%g" ./chart/api7-ingress/api7-ingress.yaml
helm install api7-ingress ./chart/api7-ingress -n api7  --values ./chart/api7-ingress/api7-ingress.yaml
