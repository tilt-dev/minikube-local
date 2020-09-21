# minikube-local

The best way to set minikube up for local development

[![Build Status](https://circleci.com/gh/tilt-dev/minikube-local/tree/master.svg?style=shield)](https://circleci.com/gh/tilt-dev/minikube-local)

When using Tilt with a [Minikube](https://minikube.sigs.k8s.io/docs/) cluster, 
we recommend using a local registry for faster image pushing and pulling.

This repo documents the best way to set it up.

## Why use Minikube with a local registry?

When developing locally, you want to push images to the cluster as fast as possible.

Pushing to a local image registry skips a lot of overhead:

- Unlike with a remote registry, the image stays local to your machine, with no network traffic

- Unlike with loading into the container runtime, docker will skip pushing any layers that already exist in the registry

- Unlike with in-cluster build daemons, there's no additional auth configuration in-cluster.

- Unlike with an in-cluster registry, you can reset the cluster without deleting the image cache.

This makes it a great solution for iterative local development. But setting it up is awkward and fiddly. This script makes it easy.

## How to Try It

1) Install [Minikube](https://minikube.sigs.k8s.io/docs/)

2) Copy the [minikube-with-registry.sh](minikube-with-registry.sh) somewhere on your path.

3) Create a cluster with `minikube-with-registry.sh`. Currently it creates the registry at port 5000.

```
minikube-with-registry.sh
```

4) Try pushing an image.

```
docker tag alpine localhost:5000/alpine
docker push localhost:5000/alpine
```

You can now use the image name `localhost:5000/alpine` in any resources you deploy to the cluster.

[Tilt](https://tilt.dev) will automatically detect the local registry created by this script.

## How to Use it in CI

We also have instructions for setting Minikube up with a local registry in

- [.circleci](.circleci) 

## Thanks to

High five to [MicroK8s](https://github.com/ubuntu/microk8s) for the initial local registry feature
that inspired a lot of this work.

The Kind team ran with this, writing up documentation and hooks for how to [set up a local registry](https://kind.sigs.k8s.io/docs/user/local-registry/) with Kind.

This repo adapts the Kind team's approach and applies the local registry configmap, so that tools
like Tilt can discover the local-registry. This protocol is a [Kubernetes Enhancement Proposal](https://github.com/kubernetes/enhancements/issues/1755).

## License

Copyright 2020 Windmill Engineering

Licensed under [the Apache License, Version 2.0](LICENSE)
