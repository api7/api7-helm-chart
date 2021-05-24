#!/usr/bin/env sh

echo 'Checking the running of Manager API...'

until nc -zw 1 127.0.0.1 9000; do
    echo 'Waiting for Manager API'
    sleep 1
done

token=`curl -s localhost:9000/apisix/admin/user/login -d '{"username":"admin", "password":"admin"}' | grep -o '"token":"[^\"]*"' | awk -F : '{print $2}' | tr -d '"'`

echo $token


echo '
{
  "name": "api7-dashboard",
  "uris": ["/*"],
  "hosts": ["a.com"],
  "upstream": {
    "type": "roundrobin",
    "nodes": {
        "127.0.0.1:9000": 1
    }
  }
}' | curl http://127.0.0.1:9000/apisix/admin/routes/E08D6599-EF67-408A-8006-17D2B592C3D4?cluster_id=cluster_1 -XPUT -H "Authorization: $token" -v -d @-
