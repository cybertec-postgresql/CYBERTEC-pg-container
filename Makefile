
# Define Default if Values not exist
BASE_IMAGE ?= rockylinux:9.1-minimal
BASEOS ?= rocky9
IMAGE_REPOSITORY ?= docker.io
IMAGE_PATH ?= cybertec-proventa-container
PGVERSION ?= 15
PGVERSION_FULL ?= 15.2
OLD_PG_VERSIONS ?= 11 12 13 14
PATRONI_VERSION ?= 3.0.1
PGBACKREST_VERSION ?= 2.44
POSTGIS_VERSION ?= 33
PACKAGER ?= dnf
BUILD ?= 1
ETCDVERSION ?= v3.5.0
IMAGE_TAG ?= $(BASEOS)-$(PGVERSION_FULL)-$(BUILD)
POSTGIS_IMAGE_TAG ?= $(BASEOS)-$(PGVERSION_FULL)-$(POSTGIS_VERSION)-$(BUILD)
PGEXPORTER_VERSION ?= v0.13.2

# Settings for the Build-Process
BUILDWITH ?= docker
ROOTPATH = $(GOPATH)/src/github.com/cybertec/cybertec-proventa-container
ifndef ROOTPATH
	export ROOTPATH=$(GOPATH)/src/github.com/cybertec/cybertec-proventa-container
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
etcd: etcd
pgbouncer: pgbouncer
pg_timetable: pg_timetable
proventa: base proventa

base-build:
		${BUILDWITH} build $(ROOTPATH)							\
			--file $(ROOTPATH)/docker/base/Dockerfile 	\
			--tag $(IMAGE_PATH)/base:$(BASEOS)-$(BUILD) 		\
			--build-arg BASE_IMAGE							\
			--build-arg IMAGE_REPOSITORY 					\
			--build-arg BASEOS 								\
			--build-arg PACKAGER 							\
			--build-arg CONTAINERSUITE 	
base: base-build;	

pgbackrest-build:
		${BUILDWITH} build $(ROOTPATH)							\
			--file $(ROOTPATH)/docker/pgbackrest/Dockerfile 	\
			--tag $(IMAGE_PATH)/pgbackrest:$(IMAGE_TAG)-$(BUILD) 		\
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
		${BUILDWITH} build $(ROOTPATH)								\
			--file $(ROOTPATH)/docker/postgres/Dockerfile 		\
			--tag $(IMAGE_PATH)/postgres:$(IMAGE_TAG)-$(BETA)$(BUILD)	\
			--build-arg BASE_IMAGE								\
			--build-arg IMAGE_REPOSITORY 						\
			--build-arg BASEOS 									\
			--build-arg PACKAGER 								\
			--build-arg CONTAINERSUITE 							\
			--build-arg BUILD 									\
			--build-arg PATRONI_VERSION 						\
			--build-arg PGBACKREST_VERSION  					\
			--build-arg OLD_PG_VERSIONS							\
			--build-arg PGVERSION 								\

postgres: postgres-build

postgres-stage-build:
		${BUILDWITH} build $(ROOTPATH)								\
			--file $(ROOTPATH)/docker/postgres-stage/Dockerfile 		\
			--tag $(IMAGE_PATH)/postgres-stage:$(PGVERSION_FULL)-$(BETA)$(BUILD)	\
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
		${BUILDWITH} build $(ROOTPATH)								\
			--file $(ROOTPATH)/docker/postgres-gis/Dockerfile 		\
			--tag $(IMAGE_PATH)/postgres-gis:$(IMAGE_TAG)-$(BETA)$(BUILD)	\
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
		${BUILDWITH} build $(ROOTPATH)								\
			--file $(ROOTPATH)/docker/postgres-oracle/Dockerfile 		\
			--tag $(IMAGE_PATH)/postgres-oracle:$(IMAGE_TAG)-$(BETA)$(BUILD)	\
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
		echo ${PGEXPORTER_VERSION} 
		${BUILDWITH} build $(ROOTPATH)								\
			--file $(ROOTPATH)/docker/exporter/Dockerfile 		\
			--tag $(IMAGE_PATH)/exporter:0.1.$(BUILD)	\
			--build-arg BASEOS 									\
			--build-arg PACKAGER 								\
			--build-arg CONTAINERSUITE 							\
			--build-arg BUILD 									\
			--build-arg PGEXPORTER_VERSION=$(PGEXPORTER_VERSION)

exporter: exporter-build

etcd-build:
		${BUILDWITH} build $(ROOTPATH)								\
			--file $(ROOTPATH)/docker/etcd/Dockerfile 		\
			--tag $(IMAGE_PATH)/etcd:0.1.$(BUILD)	\
			--build-arg BASE_IMAGE								\
			--build-arg IMAGE_REPOSITORY 						\
			--build-arg BASEOS 									\
			--build-arg PACKAGER 								\
			--build-arg CONTAINERSUITE 							\
			--build-arg BUILD 									\
			--build-arg ETCDVERSION 							

etcd: etcd-build

pgbouncer-build:
		${BUILDWITH} build $(ROOTPATH)								\
			--file $(ROOTPATH)/docker/pgbouncer/Dockerfile 		\
			--tag $(IMAGE_PATH)/pgbouncer:0.1.$(BUILD)	\
			--build-arg BASE_IMAGE								\
			--build-arg IMAGE_REPOSITORY 						\
			--build-arg BASEOS 									\
			--build-arg PACKAGER 								\
			--build-arg CONTAINERSUITE 							\
			--build-arg BUILD 							

pgbouncer: pgbouncer-build

pg_timetable-build:
		${BUILDWITH} build $(ROOTPATH)								\
			--file $(ROOTPATH)/docker/pg_timetable/Dockerfile 		\
			--tag $(IMAGE_PATH)/pg_timetable:0.1.$(BUILD)	\
			--build-arg BASE_IMAGE								\
			--build-arg IMAGE_REPOSITORY 						\
			--build-arg BASEOS 									\
			--build-arg PACKAGER 								\
			--build-arg CONTAINERSUITE 							\
			--build-arg BUILD 							

pg_timetable: pg_timetable-build

proventa-build:
		${BUILDWITH} build $(ROOTPATH)								\
			--file $(ROOTPATH)/docker/proventa/Dockerfile 		\
			--tag $(IMAGE_PATH)/proventa:$(IMAGE_TAG)-$(BETA)$(BUILD)	\
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

proventa: proventa-build