#!/bin/bash
#
# Make sure the local registry works as expected.

set -ex

cd $(dirname $0)

docker pull busybox
docker tag busybox localhost:5000/busybox
docker push localhost:5000/busybox

set +e

kubectl get serviceaccount default

while [ $? -ne 0 ]; do
    echo "Waiting for service account"
    sleep 3
    kubectl get serviceaccount default
done

set -e

kubectl delete -f pod.yaml --ignore-not-found
kubectl create -f pod.yaml
kubectl wait --for=condition=ready pod/minikube-test --timeout=60s
