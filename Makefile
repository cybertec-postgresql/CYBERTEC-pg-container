
# Define Default if Values not exist
BASE_IMAGE ?= rockylinux:9.1-minimal
BASEOS ?= rocky9
IMAGE_REPOSITORY ?= docker.io
IMAGE_PATH ?= cybertec-pg-container
PGVERSION ?= 16
PGVERSION_FULL ?= 16.1
OLD_PG_VERSIONS ?= 13 14 15
PATRONI_VERSION ?= 3.2.1
PGBACKREST_VERSION ?= 2.44
POSTGIS_VERSION ?= 33
PACKAGER ?= dnf
BUILD ?= 1
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
postgres-gis: base postgres-gis
postgres-oracle: base postgres-oracle
exporter: exporter
#--no-cache
base-build:
		docker build $(ROOTPATH) 							\
			--file $(ROOTPATH)/docker/base/Dockerfile 	\
			--tag cybertec-pg-container/base:$(BASEOS)-$(BUILD) 		\
			--build-arg BASE_IMAGE							\
			--build-arg IMAGE_REPOSITORY 					\
			--build-arg BASEOS 								\
			--build-arg PACKAGER 							\
			--build-arg CONTAINERSUITE 						
base: base-build;		

pgbackrest-build:
		docker build $(ROOTPATH)							\
			--file $(ROOTPATH)/docker/pgbackrest/Dockerfile 	\
			--tag cybertec-pg-container/pgbackrest:$(IMAGE_TAG)-$(BUILD) 		\
			--build-arg BASE_IMAGE							\
			--build-arg IMAGE_REPOSITORY 					\
			--build-arg BASEOS 								\
			--build-arg PACKAGER 							\
			--build-arg CONTAINERSUITE 						\
			--build-arg BUILD 								\
			--build-arg PGBACKREST_VERSION 					\
			--build-arg OLD_PG_VERSIONS						\
			--build-arg PGVERSION 												

pgbackrest: pgbackrest-build;
			
postgres-build:
		docker build $(ROOTPATH)								\
			--file $(ROOTPATH)/docker/postgres/Dockerfile 		\
			--tag cybertec-pg-container/postgres:$(IMAGE_TAG)-$(BETA)$(BUILD)	\
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

postgres-gis-build:
		docker build $(ROOTPATH)								\
			--file $(ROOTPATH)/docker/postgres-gis/Dockerfile 		\
			--tag cybertec-pg-container/postgres-gis:$(IMAGE_TAG)-$(BETA)$(BUILD)	\
			--build-arg BASE_IMAGE								\
			--build-arg IMAGE_REPOSITORY 						\
			--build-arg BASEOS 									\
			--build-arg PACKAGER 								\
			--build-arg CONTAINERSUITE 							\
			--build-arg BUILD 									\
			--build-arg PATRONI_VERSION 						\
			--build-arg PGBACKREST_VERSION 						\
			--build-arg OLD_PG_VERSIONS							\
			--build-arg PGVERSION								\
			--build-arg POSTGIS_VERSION							

postgres-gis: postgres-gis-build

postgres-oracle-build:
		docker build $(ROOTPATH)								\
			--file $(ROOTPATH)/docker/postgres-oracle/Dockerfile 		\
			--tag cybertec-pg-container/postgres-oracle:$(IMAGE_TAG)-$(BETA)$(BUILD)	\
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

postgres-oracle: postgres-oracle-build

exporter-build:
		docker build $(ROOTPATH)								\
			--file $(ROOTPATH)/docker/exporter/Dockerfile 		\
			--tag cybertec-pg-container/exporter:$(IMAGE_TAG)-$(BETA)$(BUILD)	\
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