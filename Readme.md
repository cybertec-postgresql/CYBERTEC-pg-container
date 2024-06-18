# CYBERTEC-pg-container: PostgreSQL-HA-Cluster based on Rocky-Linux

<p>CYBERTEC-pg-container is a Docker suite that combines PostgreSQL, Patroni and etcd to create HA-PostgreSQL clusters based on containers. This suite is also the imagebase for the CYBERTEC-pg-operator(cpo).</p>

## Documentation

<p>See the documentation for some examples of how to run this suite in Docker, Kubernetes or Kubernetes-based environments.</p>

## Operational area
<p>These images can run locally on Docker, Kubernetes or on Kubernetes-based environments such as Openshift or Rancher.
On Kubernetes and Kubernetes-based environments, the image uses the k8-etcd, otherwise etcd is included locally in the image</p>

## Build Images

<p>To create the images via Makefile, you need the following environment variables and Go on your system.</p>

    export GOPATH=$HOME/cdev
    export GOBIN=$GOPATH/bin
    export PATH=$PATH:$GOBIN
    export BASE_IMAGE=rockylinux:9
    export CONTAINERIMAGE=rockylinux/rockylinux:9-ubi-micro
    export IMAGE_REPOSITORY=docker.io
    export BASEOS=rocky9
    export PACKAGER=dnf
    export CONTAINERSUITE=cybertec-pg-container
    export PGBACKREST_VERSION=2.51
    export CCPROOT=$GOPATH/src/github.com/cybertec/cybertec-pg-container
    export PATRONI_VERSION=3.3.1
    export POSTGIS_VERSION=34
    export PGVERSION=16
    export PGVERSION_FULL=16.3
    export OLD_PG_VERSIONS="13 14 15"
    export BUILD=1
    export ARCH=amd64

<p>You can build all images with make
- make all
- make base/postgres/pgbackrest</p>
<p>Run Images locally:</p>

    docker run -it IMAGEPATH:IMAGETAG
<p>Take a look inside:</p>

    docker exec -it CONTAINERID /bin/bash
