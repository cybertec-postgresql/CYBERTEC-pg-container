
# Define Default if Values not exist
BASE_IMAGE ?= rockylinux:9-minimal
BASEOS ?= rocky9
IMAGE_REPOSITORY ?= docker.io
IMAGE_PATH ?= cybertec-os-container
PG_MAJOR ?= 15
PG_VERSION ?= 15.0
OLD_PG_VERSIONS ?= 10 11 12 13 14
PATRONI_VERSION ?= 2.1.4
PGBACKREST_VERSION ?= 2.41
POSTGIS_VERSION ?= 3.2
PACKAGER ?= dnf
BUILD ?= 0
IMAGE_TAG ?= $(BASEOS)-$(PG_VERSION)-$(BUILD)
POSTGIS_IMAGE_TAG ?= $(BASEOS)-$(PG_VERSION)-$(POSTGIS_VERSION)-$(BUILD)

# Settings for the Build-Process
BUILDWITH ?= docker
ROOTPATH = $(GOPATH)/src/github.com/cybertec/cybertec-os-container
ifndef ROOTPATH
	export ROOTPATH=$(GOPATH)/src/github.com/cybertec/cybertec-os-container
endif

# Build Images

all: base pgbackrest postgres
base: base
postgres: postgres
postgres-stage: postgres-stage

base-build:
		docker build $(ROOTPATH)							\
			--file $(ROOTPATH)/docker/base/Dockerfile 	\
			--tag cybertec-os-container/base:0.0.$(BUILD) 		\
			--build-arg BASE_IMAGE							\
			--build-arg IMAGE_REPOSITORY 					\
			--build-arg BASEOS 								\
			--build-arg PACKAGER 							\
			--build-arg CONTAINERSUITE 						
base: base-build;	

pgbackrest-build:
		docker build $(ROOTPATH)							\
			--file $(ROOTPATH)/docker/pgbackrest/Dockerfile 	\
			--tag cybertec-os-container/pgbackrest:0.0.$(BUILD) 		\
			--build-arg BASE_IMAGE							\
			--build-arg IMAGE_REPOSITORY 					\
			--build-arg BASEOS 								\
			--build-arg PACKAGER 							\
			--build-arg CONTAINERSUITE 						\
			--build-arg BUILD 								\
			--build-arg PGBACKREST_VERSION 					\
			--build-arg PG_MAJOR 												

pgbackrest: pgbackrest-build;	
			
postgres-build:
		docker build $(ROOTPATH)								\
			--file $(ROOTPATH)/docker/postgres/Dockerfile 		\
			--tag cybertec-os-container/postgres:$(PG_MAJOR).0.$(BUILD)	\
			--build-arg BASE_IMAGE								\
			--build-arg IMAGE_REPOSITORY 						\
			--build-arg BASEOS 									\
			--build-arg PACKAGER 								\
			--build-arg CONTAINERSUITE 							\
			--build-arg BUILD 									\
			--build-arg PATRONI_VERSION 						\
			--build-arg PGBACKREST_VERSION 						\
			--build-arg PG_VERSION 								\
			--build-arg OLD_PG_VERSIONS							\
			--build-arg PG_MAJOR 							

postgres: postgres-build

postgres-stage-build:
		docker build $(ROOTPATH)								\
			--file $(ROOTPATH)/docker/postgres_stage/Dockerfile 		\
			--tag cybertec-os-container/postgres-stage:$(PG_MAJOR).0.$(BUILD)	\
			--build-arg BASE_IMAGE								\
			--build-arg IMAGE_REPOSITORY 						\
			--build-arg BASEOS 									\
			--build-arg PACKAGER 								\
			--build-arg CONTAINERSUITE 							\
			--build-arg BUILD 									\
			--build-arg PATRONI_VERSION 						\
			--build-arg PGBACKREST_VERSION 						\
			--build-arg PG_VERSION 								\
			--build-arg OLD_PG_VERSION 							\
			--build-arg PG_MAJOR 							

postgres-stage: postgres-stage-build