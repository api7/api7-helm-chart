#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# desired cluster name; default is "api7-test"
KIND_CLUSTER_NAME="${KIND_CLUSTER_NAME:-api7-test}"

if kind get clusters | grep -q ^api7-test$ ; then
  echo "cluster already exists, moving on"
  exit 0
fi

# create the cluster
cat <<EOF | kind create cluster --name "${KIND_CLUSTER_NAME}" --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
- role: worker
EOF
