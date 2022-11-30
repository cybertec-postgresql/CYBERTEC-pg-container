# CYBERTEC-OS-Container: PostgreSQL-HA-Cluster based on Rocky-Linux

<p>CYBERTEC-OS-Container is a Docker suite that combines PostgreSQL, Patroni and etcd to create HA-PostgreSQL clusters based on containers. This suite is also the imagebase for the CYBERTEC-OS operator.</p>

## Documentation

<p>See the documentation for some examples of how to run this suite in Docker, Kubernetes or Kubernetes-based environments.</p>

## Operational area
<p>These images can run locally on Docker, Kubernetes or on Kubernetes-based environments such as Openshift or Rancher.
On Kubernetes and Kubernetes-based environments, the image uses the k8-etcd, otherwise etcd is included locally in the image</p>

## Build Images

<p>To create the images via Makefile, you need the following environment variables and Go on your system.</p>
```
export GOPATH=$HOME/cdev
export GOBIN=$GOPATH/bin
export PATH=$PATH:$GOBIN
export BASE_IMAGE=rockylinux:9
export IMAGE_REPOSITORY=docker.io
export BASEOS=rocky9
export PACKAGER=dnf
export CONTAINERSUITE=cybertec-os-container
export PGBACKREST_VERSION=2.41
export PATRONI_VERSION=2.1.4
export PG_MAJOR=14
export PG_VERSION=14.6
export OLD_PG_VERSIONS="10 11 12 13"
export BUILD=1
```
<p>You can build all images with make
- make all
- make base/postgres/pgbackrest</p>
<p><>Run Images locally:</p>
```docker run -it IMAGEPATH:IMAGETAG```

<p><>Take a look inside:</p>
```docker exec -it CONTAINERID /bin/bash```