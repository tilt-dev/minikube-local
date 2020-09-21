#!/bin/bash
#
# Starts a Minikube cluster and runs a command against it.
#
# Usage:
#   with-minikube-cluster.sh kubectl cluster-info
#
# Adapted from:
# https://github.com/kubernetes-sigs/kind/commits/master/site/static/examples/kind-with-registry.sh
#
# Copyright 2020 The Kubernetes Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -oe errexit

# desired profile name; default is ""
MINIKUBE_PROFILE_NAME="${MINIKUBE_PROFILE_NAME:-minikube}"

# default registry name and port
reg_name='minikube-registry'
reg_port='5000'

echo "> initializing Docker registry"

# create registry container unless it already exists
running="$(docker inspect -f '{{.State.Running}}' "${reg_name}" 2>/dev/null || true)"
if [ "${running}" != 'true' ]; then
  docker run \
    -d --restart=always -p "${reg_port}:5000" --name "${reg_name}" \
    registry:2
fi

# create a cluster
reg_host="$(docker inspect -f '{{.NetworkSettings.IPAddress}}' "${reg_name}")"


sudo socat UNIX-LISTEN:/var/run/docker.sock,user=root,fork "TCP:$DOCKER_HOST" &

echo "> initializing Minikube cluster: ${MINIKUBE_PROFILE_NAME} with registry ${reg_name}"


minikube start -p "$MINIKUBE_PROFILE_NAME" --driver=docker --container-runtime=containerd

# patch the container runtime
# this is the most annoying sed expression i've ever had to write
minikube ssh sudo sed "\-i" "s,\\\[plugins.cri.registry.mirrors\\\],[plugins.cri.registry.mirrors]\\\n\ \ \ \ \ \ \ \ [plugins.cri.registry.mirrors.\\\"localhost:${reg_port}\\\"]\\\n\ \ \ \ \ \ \ \ \ \ endpoint\ =\ [\\\"http://${reg_host}:${reg_port}\\\"]," /etc/containerd/config.toml

# restart the container runtime
minikube ssh sudo systemctl restart containerd

echo "> port-forwarding k8s API server"
/usr/local/bin/start-portforward-service.sh start

APISERVER_PORT=$(kubectl config view -o jsonpath='{.clusters[].cluster.server}' | cut -d: -f 3 -)
/usr/local/bin/portforward.sh $APISERVER_PORT
kubectl get nodes # make sure it worked

echo "> port-forwarding local registry"
/usr/local/bin/portforward.sh $reg_port

echo "> applying local-registry docs"

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: local-registry-hosting
  namespace: kube-public
data:
  localRegistryHosting.v1: |
    host: "localhost:${reg_port}"
    help: "https://github.com/tilt-dev/minikube-local"
EOF

echo "> waiting for kubernetes node(s) become ready"
kubectl wait --for=condition=ready node --all --timeout=60s

echo "> with-minikube-cluster.sh setup complete! Running user script: $@"
exec "$@"
