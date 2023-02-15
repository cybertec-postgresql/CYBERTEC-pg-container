
# Define Default if Values not exist
BASE_IMAGE ?= rockylinux:9.1-minimal
BASEOS ?= rocky9
IMAGE_REPOSITORY ?= docker.io
IMAGE_PATH ?= cybertec-pg-container
PGVERSION ?= 15
PGVERSION_FULL ?= 15.2
OLD_PG_VERSIONS ?= 10 11 12 13 14
PATRONI_VERSION ?= 2.1.4
PGBACKREST_VERSION ?= 2.41
POSTGIS_VERSION ?= 3.2
PACKAGER ?= dnf
BUILD ?= 0
IMAGE_TAG ?= $(BASEOS)-$(PGVERSION_FULL)-$(BUILD)
POSTGIS_IMAGE_TAG ?= $(BASEOS)-$(PGVERSION_FULL)-$(POSTGIS_VERSION)-$(BUILD)

# Settings for the Build-Process
BUILDWITH ?= docker
ROOTPATH = $(GOPATH)/src/github.com/cybertec/cybertec-pg-container
ifndef ROOTPATH
	export ROOTPATH=$(GOPATH)/src/github.com/cybertec/cybertec-pg-container
endif

# Build Images

all: base pgbackrest postgres
base: base
pgbackrest: pgbackrest
postgres: base postgres
postgres-stage: base postgres-stage
exporter: exporter

base-build:
		docker build $(ROOTPATH)							\
			--file $(ROOTPATH)/docker/base/Dockerfile 	\
			--tag cybertec-pg-container/base:0.0.$(BUILD) 		\
			--build-arg BASE_IMAGE							\
			--build-arg IMAGE_REPOSITORY 					\
			--build-arg BASEOS 								\
			--build-arg PACKAGER 							\
			--build-arg CONTAINERSUITE 						
base: base-build;	

pgbackrest-build:
		docker build $(ROOTPATH)							\
			--file $(ROOTPATH)/docker/pgbackrest/Dockerfile 	\
			--tag cybertec-pg-container/pgbackrest:0.0.$(BUILD) 		\
			--build-arg BASE_IMAGE							\
			--build-arg IMAGE_REPOSITORY 					\
			--build-arg BASEOS 								\
			--build-arg PACKAGER 							\
			--build-arg CONTAINERSUITE 						\
			--build-arg BUILD 								\
			--build-arg PGBACKREST_VERSION 					\
			--build-arg PGVERSION 												

pgbackrest: pgbackrest-build;	
			
postgres-build:
		docker build $(ROOTPATH)								\
			--file $(ROOTPATH)/docker/postgres/Dockerfile 		\
			--tag cybertec-pg-container/postgres:$(PGVERSION_FULL)-$(BETA)$(BUILD)	\
			--build-arg BASE_IMAGE								\
			--build-arg IMAGE_REPOSITORY 						\
			--build-arg BASEOS 									\
			--build-arg PACKAGER 								\
			--build-arg CONTAINERSUITE 							\
			--build-arg BUILD 									\
			--build-arg PATRONI_VERSION 						\
			--build-arg PGBACKREST_VERSION 						\
			--build-arg OLD_PG_VERSIONS							\
			--build-arg PGVERSION 							

postgres: postgres-build

postgres-stage-build:
		docker build $(ROOTPATH)								\
			--file $(ROOTPATH)/docker/postgres-stage/Dockerfile 		\
			--tag cybertec-pg-container/postgres-stage:$(PGVERSION_FULL)-$(BETA)$(BUILD)	\
			--build-arg BASE_IMAGE								\
			--build-arg IMAGE_REPOSITORY 						\
			--build-arg BASEOS 									\
			--build-arg PACKAGER 								\
			--build-arg CONTAINERSUITE 							\
			--build-arg BUILD 									\
			--build-arg PATRONI_VERSION 						\
			--build-arg PGBACKREST_VERSION 						\
			--build-arg OLD_PG_VERSIONS							\
			--build-arg PGVERSION 							

postgres-stage: postgres-stage-build

exporter-build:
		docker build $(ROOTPATH)								\
			--file $(ROOTPATH)/docker/exporter/Dockerfile 		\
			--tag cybertec-pg-container/exporter:0.1.$(BUILD)	\
			--build-arg BASE_IMAGE								\
			--build-arg IMAGE_REPOSITORY 						\
			--build-arg BASEOS 									\
			--build-arg PACKAGER 								\
			--build-arg CONTAINERSUITE 							\
			--build-arg BUILD 									\
			--build-arg PATRONI_VERSION 						\
			--build-arg PGBACKREST_VERSION 						\
			--build-arg OLD_PG_VERSION 							\
			--build-arg PGVERSION 							

exporter: exporter-build