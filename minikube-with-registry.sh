#!/bin/sh
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

set -o errexit

# desired profile name; default is ""
MINIKUBE_PROFILE_NAME="${MINIKUBE_PROFILE_NAME:-minikube}"

reg_name='minikube-registry'
reg_port='5000'

# create registry container unless it already exists
running="$(docker inspect -f '{{.State.Running}}' "${reg_name}" 2>/dev/null || true)"
if [ "${running}" != 'true' ]; then
  docker run \
    -d --restart=always -p "${reg_port}:5000" --name "${reg_name}" \
    registry:2
fi

reg_host="$(docker inspect -f '{{.NetworkSettings.IPAddress}}' "${reg_name}")"
echo "Registry Host: ${reg_host}"

# create a cluster
minikube start -p "$MINIKUBE_PROFILE_NAME" --driver=docker --container-runtime=containerd

# patch the container runtime
# this is the most annoying sed expression i've ever had to write
minikube ssh sudo sed "\-i" "s,\\\[plugins.cri.registry.mirrors\\\],[plugins.cri.registry.mirrors]\\\n\ \ \ \ \ \ \ \ [plugins.cri.registry.mirrors.\\\"localhost:${reg_port}\\\"]\\\n\ \ \ \ \ \ \ \ \ \ endpoint\ =\ [\\\"http://${reg_host}:${reg_port}\\\"]," /etc/containerd/config.toml

# restart the container runtime
minikube ssh sudo systemctl restart containerd

# document the registry
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
