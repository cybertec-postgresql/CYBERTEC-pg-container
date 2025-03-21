
# Define Default if Values not exist
BASE_IMAGE ?= rockylinux:9
BASEOS ?= rocky9
CONTAINERIMAGE ?= rockylinux/rockylinux:9-ubi-micro
IMAGE_REPOSITORY ?= docker.io
IMAGE_PATH ?= cybertec-pg-container
PGVERSION ?= 17
PGVERSION_FULL ?= 17.4
OLD_PG_VERSIONS ?= 13 14 15 16
PATRONI_VERSION ?= multisite-4.0.2.1
PGBACKREST_VERSION ?= 2.54.2
POSTGIS_VERSION ?= 34
ETCD_VERSION ?= 3.5.18
PGBOUNCER_VERSION ?= 1.24
PGVECTOR ?= v0.8.0
PACKAGER ?= dnf
BUILD ?= 1
ARCH ?= amd64
IMAGE_TAG ?= $(BASEOS)-$(PGVERSION_FULL)-$(BUILD)
POSTGIS_IMAGE_TAG ?= $(BASEOS)-$(PGVERSION_FULL)-$(POSTGIS_VERSION)-$(BUILD)

# Public-Beta
PUBLICBETA ?= 2
BETAVERSION ?= 17

# Settings for the Build-Process
BUILDWITH ?= docker
ROOTPATH ?= $(GOPATH)/src/github.com/cybertec/cybertec-pg-container

# Build Images

all: base pgbackrest postgres
base: base
pgbackrest: pgbackrest
postgres: base postgres
postgres-stage: base postgres-stage
postgres-gis: base postgres-gis
postgres-oracle: base postgres-oracle
pgbouncer: pgbouncer
exporter: exporter
publicbeta: publicbeta-pg publicbeta-pgbackrest

base-build:
		docker build $(ROOTPATH)								\
			--file $(ROOTPATH)/docker/base/Dockerfile 		 	\
			--tag cybertec-pg-container/base:$(BASEOS)-$(BUILD) \
			--build-arg BASE_IMAGE=$(BASE_IMAGE)				\
			--build-arg IMAGE_REPOSITORY=$(IMAGE_REPOSITORY)	\
			--build-arg BASEOS=$(BASEOS) 						\
			--build-arg PACKAGER=$(PACKAGER) 					\
			--build-arg IMAGE_PATH=$(IMAGE_PATH) 		

base: base-build;		

pgbackrest-build:
		docker build $(ROOTPATH)											\
			--file $(ROOTPATH)/docker/pgbackrest/Dockerfile 				\
			--tag cybertec-pg-container/pgbackrest:$(IMAGE_TAG) 			\
			--build-arg BASE_IMAGE=$(BASE_IMAGE)							\
			--build-arg CONTAINERIMAGE=${CONTAINERIMAGE} 					\
			--build-arg IMAGE_REPOSITORY=$(IMAGE_REPOSITORY)				\
			--build-arg BASEOS=$(BASEOS)									\
			--build-arg PACKAGER=$(PACKAGER)								\
			--build-arg IMAGE_PATH=$(IMAGE_PATH)							\
			--build-arg BUILD=$(BUILD)										\
			--build-arg PGBACKREST_VERSION=$(PGBACKREST_VERSION)			\
			--build-arg OLD_PG_VERSIONS="$(OLD_PG_VERSIONS)"				\
			--build-arg PGVERSION=$(PGVERSION)								\
			--build-arg ARCH=$(ARCH)

pgbackrest: pgbackrest-build;
			
postgres-build:
		docker build $(ROOTPATH)												\
			--file $(ROOTPATH)/docker/postgres/Dockerfile 						\
			--tag cybertec-pg-container/postgres:$(IMAGE_TAG)	\
			--build-arg BASE_IMAGE=$(BASE_IMAGE)								\
			--build-arg CONTAINERIMAGE=${CONTAINERIMAGE} 						\
			--build-arg IMAGE_REPOSITORY=$(IMAGE_REPOSITORY)					\
			--build-arg BASEOS=$(BASEOS) 										\
			--build-arg PACKAGER=$(PACKAGER) 									\
			--build-arg IMAGE_PATH=$(IMAGE_PATH) 								\
			--build-arg BUILD=$(BUILD) 											\
			--build-arg PGBACKREST_VERSION=$(PGBACKREST_VERSION) 				\
			--build-arg PATRONI_VERSION=$(PATRONI_VERSION) 						\
			--build-arg OLD_PG_VERSIONS="$(OLD_PG_VERSIONS)"					\
			--build-arg PGVERSION=$(PGVERSION)									\
			--build-arg ETCD_VERSION=$(ETCD_VERSION)							\
			--build-arg PGVERSION=$(PGVERSION) 									\
			--build-arg PGVECTOR=$(PGVECTOR)									\
			--build-arg ARCH=$(ARCH) 											

postgres: postgres-build

postgres-gis-build:
		docker build $(ROOTPATH)													\
			--file $(ROOTPATH)/docker/postgres-gis/Dockerfile 						\
			--tag cybertec-pg-container/postgres-gis:$(IMAGE_TAG)					\
			--build-arg BASE_IMAGE=$(BASE_IMAGE)									\
			--build-arg CONTAINERIMAGE=${CONTAINERIMAGE} 							\
			--build-arg IMAGE_REPOSITORY=$(IMAGE_REPOSITORY)						\
			--build-arg BASEOS=$(BASEOS) 											\
			--build-arg PACKAGER=$(PACKAGER) 										\
			--build-arg IMAGE_PATH=$(IMAGE_PATH) 									\
			--build-arg BUILD=$(BUILD) 												\
			--build-arg PGBACKREST_VERSION=$(PGBACKREST_VERSION) 					\
			--build-arg PATRONI_VERSION=$(PATRONI_VERSION) 							\
			--build-arg OLD_PG_VERSIONS="$(OLD_PG_VERSIONS)"						\
			--build-arg PGVERSION=$(PGVERSION)										\
			--build-arg POSTGIS_VERSION=$(POSTGIS_VERSION)							\
			--build-arg ETCD_VERSION=$(ETCD_VERSION)								\
			--build-arg PGVECTOR=$(PGVECTOR)										\
			--build-arg ARCH=$(ARCH)	

postgres-gis: postgres-gis-build

postgres-oracle-build:
		docker build $(ROOTPATH)														\
			--file $(ROOTPATH)/docker/postgres-oracle/Dockerfile 						\
			--tag cybertec-pg-container/postgres-oracle:$(IMAGE_TAG)					\
			--build-arg BASE_IMAGE=$(BASE_IMAGE)										\
			--build-arg CONTAINERIMAGE=${CONTAINERIMAGE} 								\
			--build-arg IMAGE_REPOSITORY=$(IMAGE_REPOSITORY)							\
			--build-arg BASEOS=$(BASEOS) 												\
			--build-arg PACKAGER=$(PACKAGER) 											\
			--build-arg IMAGE_PATH=$(IMAGE_PATH) 										\
			--build-arg BUILD=$(BUILD) 													\
			--build-arg PGBACKREST_VERSION=$(PGBACKREST_VERSION) 						\
			--build-arg PATRONI_VERSION=$(PATRONI_VERSION) 								\
			--build-arg OLD_PG_VERSIONS="$(OLD_PG_VERSIONS)"							\
			--build-arg PGVERSION=$(PGVERSION)											\
			--build-arg ETCD_VERSION=$(ETCD_VERSION)									\
			--build-arg ARCH=$(ARCH)

postgres-oracle: postgres-oracle-build

pgbouncer-build:
		docker build $(ROOTPATH)														\
			--file $(ROOTPATH)/docker/pgbouncer/Dockerfile 								\
			--tag cybertec-pg-container/pgbouncer:$(IMAGE_TAG)							\
			--build-arg BASE_IMAGE=$(BASE_IMAGE)										\
			--build-arg CONTAINERIMAGE=${CONTAINERIMAGE} 								\
			--build-arg IMAGE_REPOSITORY=$(IMAGE_REPOSITORY)							\
			--build-arg BASEOS=$(BASEOS) 												\
			--build-arg PACKAGER=$(PACKAGER) 											\
			--build-arg IMAGE_PATH=$(IMAGE_PATH) 										\
			--build-arg BUILD=$(BUILD) 													\
			--build-arg PGBOUNCER_VERSION=${PGBOUNCER_VERSION}							\
			--build-arg PGVERSION=$(PGVERSION)

pgbouncer: pgbouncer-build

exporter-build:
		docker build $(ROOTPATH)	 --no-cache											\
			--file $(ROOTPATH)/docker/exporter/Dockerfile 								\
			--tag cybertec-pg-container/exporter:$(IMAGE_TAG)							\
			--build-arg BASE_IMAGE=$(BASE_IMAGE)										\
			--build-arg CONTAINERIMAGE=${CONTAINERIMAGE} 								\
			--build-arg IMAGE_REPOSITORY=$(IMAGE_REPOSITORY)							\
			--build-arg BASEOS=$(BASEOS) 												\
			--build-arg PACKAGER=$(PACKAGER) 											\
			--build-arg IMAGE_PATH=$(IMAGE_PATH) 										\
			--build-arg BUILD=$(BUILD) 													\
			--build-arg PGBACKREST_VERSION=$(PGBACKREST_VERSION) 						\
			--build-arg PGVERSION=$(PGVERSION)

exporter: exporter-build

publicbeta-pg-build:
		docker build $(ROOTPATH)													\
			--file $(ROOTPATH)/docker/pg-public-beta/Dockerfile 					\
			--tag cybertec-pg-container/postgres:$(IMAGE_TAG)-beta${PUBLICBETA}		\
			--build-arg BASE_IMAGE=$(BASE_IMAGE)									\
			--build-arg CONTAINERIMAGE=${CONTAINERIMAGE} 							\
			--build-arg IMAGE_REPOSITORY=$(IMAGE_REPOSITORY)						\
			--build-arg BASEOS=$(BASEOS) 											\
			--build-arg PACKAGER=$(PACKAGER) 										\
			--build-arg IMAGE_PATH=$(IMAGE_PATH) 									\
			--build-arg BUILD=$(BUILD) 												\
			--build-arg PGBACKREST_VERSION=$(PGBACKREST_VERSION) 					\
			--build-arg PATRONI_VERSION=$(PATRONI_VERSION) 							\
			--build-arg OLD_PG_VERSIONS="$(OLD_PG_VERSIONS)"						\
			--build-arg PGVERSION=$(BETAVERSION)									\
			--build-arg ETCD_VERSION=$(ETCD_VERSION)								\
			--build-arg ARCH=$(ARCH)	

publicbeta-pg: publicbeta-pg-build

publicbeta-pgbackrest-build:
		docker build $(ROOTPATH)													\
			--file $(ROOTPATH)/docker/pgbackrest-public-beta/Dockerfile 			\
			--tag cybertec-pg-container/pgbackrest:$(IMAGE_TAG)-beta${PUBLICBETA} 	\
			--build-arg BASE_IMAGE=$(BASE_IMAGE)									\
			--build-arg CONTAINERIMAGE=${CONTAINERIMAGE} 							\
			--build-arg IMAGE_REPOSITORY=$(IMAGE_REPOSITORY)						\
			--build-arg BASEOS=$(BASEOS)											\
			--build-arg PACKAGER=$(PACKAGER)										\
			--build-arg IMAGE_PATH=$(IMAGE_PATH)									\
			--build-arg BUILD=$(BUILD)												\
			--build-arg PGBACKREST_VERSION=$(PGBACKREST_VERSION)					\
			--build-arg OLD_PG_VERSIONS="$(OLD_PG_VERSIONS)"						\
			--build-arg PGVERSION=$(BETAVERSION)									\
			--build-arg ARCH=$(ARCH)	

publicbeta-pgbackrest: publicbeta-pgbackrest-build;
