<!--
#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
-->

# Apache APISIX Helm Charts

## Dependencies

Need 4 docker images at least:

```log
docker.io/bitnami/etcd:3.4.14-debian-10-r0
api7/api7:dev
api7/api7-dashboard:dev
busybox:1.28
```

If `--set volumePermissions.enable=true`, we also need image blow:

```log
docker.io/bitnami/minideb:buster
```

## Install

Please use custome image info, such as:

```shell
$ helm install api7 ./chart/apisix -n default \
	--set image.registry=docker.io \
	--set image.repository=api7/api7 \
	--set image.tag=dev \
	--set etcd.image.registry=docker.io \
	--set etcd.image.repository=bitnami/etcd \
	--set etcd.image.tag=3.4.14-debian-10-r0 \
	--set dashboard.image.registry=docker.io \
	--set dashboard.image.repository=api7/api7-dashboard \
	--set dashboard.image.tag=dev
```

## Uninstall

```shell
helm uninstall api7 ./chart/apisix -n default
```

## FAQ

1. How to install APISIX only?

The Charts will install etcd 3.4.14 by default. If you want to install Apache APISIX only, please set `etcd.enabled=false` and set `etcd.host={http://your_etcd_address:2379}`.

Please use the FQDN address or the IP of the etcd.

```shell
# if etcd export by kubernetes service need spell fully qualified name
$ helm install apisix ./chart/apisix -n default \
    --set etcd.enabled=false \
    --set etcd.host={http://etcd_node_1:2379\,http://etcd_node_2:2379}
```

2. Why get 403 when I access Apache APISIX admin api?

We can define `allow.ipList` in CIDR.

```shell
$ helm install apisix ./chart/apisix -n default \
    --set allow.ipList="10.22.100.12/8" \
    --set allow.ipList="172.0.0.0/24"
```

If you want to allow all IPs for a quick test, just set `allow.ipList=""`

```shell
$ helm install apisix ./chart/apisix -n default \
    --set allow.ipList=""
```

