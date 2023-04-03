# minikube-local

## UPDATE(2023-04-03)

As of Minikube 1.26, this script no longer works, due to [upstream breaking API changes](https://github.com/tilt-dev/ctlptl/issues/239).

Please migrate to [ctlptl](http://github.com/tilt-dev/ctlptl), which checks
the version of Minikube and uses the right config.

This repo will be archived for posterity.

---

The best way to set minikube up for local development

[![Build Status](https://circleci.com/gh/tilt-dev/minikube-local/tree/master.svg?style=shield)](https://circleci.com/gh/tilt-dev/minikube-local)

When using Tilt with a [Minikube](https://minikube.sigs.k8s.io/docs/) cluster, 
we recommend using a local registry for faster image pushing and pulling.

This repo documents the best way to set it up.

## Why use Minikube with a local registry?

Minikube offers many different ways to get your app into the cluster.

Using a local registry is the best method for iterative app development.

- Unlike with a remote registry, the image stays local to your machine, with no
  network traffic to wait on or credentials to setup.

- Unlike with an in-cluster builder, you can reset the cluster without deleting
  the image cache.

- Unlike with loading into the container runtime, docker will skip pushing any
  layers that already exist in the registry.

Over all these approaches, a local registry has good speed, incremental caching,
and few footguns. But setting it up is awkward and fiddly. This script makes it
easy.

## How to Try It

1) Install [Minikube](https://minikube.sigs.k8s.io/docs/)

2) Copy the [minikube-with-registry.sh](minikube-with-registry.sh) script somewhere on your path.

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

## Thanks to

High five to [MicroK8s](https://github.com/ubuntu/microk8s) for the initial local registry feature
that inspired a lot of this work.

The Kind team ran with this, writing up documentation and hooks for how to [set up a local registry](https://kind.sigs.k8s.io/docs/user/local-registry/) with Kind.

This repo adapts the Kind team's approach and applies the local registry configmap, so that tools
like Tilt can discover the local-registry. This protocol is a [Kubernetes Enhancement Proposal](https://github.com/kubernetes/enhancements/issues/1755).

## License

Copyright 2020 Windmill Engineering

Licensed under [the Apache License, Version 2.0](LICENSE)
