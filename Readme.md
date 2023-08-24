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
    export BASE_IMAGE=ubi8/ubi
    export IMAGE_REPOSITORY=registry.access.redhat.com
    export BASEOS=ubi8
    export PACKAGER=yum
    export CONTAINERSUITE=cybertec-pg-container
    export PGBACKREST_VERSION=2.45
    export PATRONI_VERSION=2.1.4
    export PGVERSION=15 
    export PG_MAJOR=15
    export PG_VERSION=15.2
    export OLD_PG_VERSIONS=""
    export BUILD=1

<p>You can build all images with make
- make all
- make base/postgres/pgbackrest</p>
<p>Run Images locally:</p>

    docker run -it IMAGEPATH:IMAGETAG
<p>Take a look inside:</p>

    docker exec -it CONTAINERID /bin/bash
