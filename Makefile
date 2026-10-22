
# Define Default if Values not exist
BASE_IMAGE ?= rockylinux/rockylinux:9
BASEOS ?= rocky9
CONTAINERIMAGE ?= rockylinux/rockylinux:9-ubi-micro
IMAGE_REPOSITORY ?= containers.cybertec.at
IMAGE_PATH ?= cybertec-pg-container
PGVERSION ?= 18
PGVERSION_FULL ?= 18.6
OLD_PG_VERSIONS ?= 14 15 16 17
PATRONI_VERSION ?= multisite-4.1.5
PGBACKREST_VERSION ?= 2.60.0
POSTGIS_VERSION ?= 36
ETCD_VERSION ?= 3.7.2
PGBOUNCER_VERSION ?= 1.26.1
GO_VERSION ?= 1.27.2
PACKAGER ?= dnf
BUILD ?= 3
IMAGE_TAG ?= $(BASEOS)-$(PGVERSION_FULL)-$(BUILD)
POSTGIS_IMAGE_TAG ?= $(BASEOS)-$(PGVERSION_FULL)-$(POSTGIS_VERSION)-$(BUILD)
PGBOUNCER_IMAGE_TAG ?= $(BASEOS)-$(PGBOUNCER_VERSION)-$(BUILD)
REPOSITORY ?= containers.cybertec.at

# Public-Beta
PUBLICBETA ?= 3
BETAVERSION ?= 18
BETA_IMAGE_TAG ?= $(IMAGE_TAG)-beta${PUBLICBETA}
BETA_OLD_PG_VERSIONS ?= 14 15 16 17 18

# Settings for the Build-Process
BUILDWITH ?= docker
DOCKER_BUILD ?= docker build
BASE_IMAGE_REF ?= $(IMAGE_PATH)/base:$(BASEOS)-$(BUILD)
BASEPATH ?= $(HOME)
ROOTPATH ?= $(BASEPATH)/src/github.com/cybertec/cybertec-pg-container

# Build Images

all: base postgres postgres-gis pgbackrest pgbouncer exporter
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
		$(DOCKER_BUILD) $(ROOTPATH)								\
			--file $(ROOTPATH)/docker/base/Dockerfile 		 	\
			--tag $(BASE_IMAGE_REF) \
			--build-arg BASE_IMAGE=$(BASE_IMAGE)				\
			--build-arg IMAGE_REPOSITORY=$(IMAGE_REPOSITORY)	\
			--build-arg BASEOS=$(BASEOS) 						\
			--build-arg PACKAGER=$(PACKAGER) 					\
			--build-arg IMAGE_PATH=$(IMAGE_PATH) 		

base: base-build;		

pgbackrest-build:
		$(DOCKER_BUILD) $(ROOTPATH)											\
			--file $(ROOTPATH)/docker/pgbackrest/Dockerfile 				\
			--tag $(REPOSITORY)/$(IMAGE_PATH)/pgbackrest:$(IMAGE_TAG) 			\
			--build-arg BASE_IMAGE=$(BASE_IMAGE)							\
			--build-arg CONTAINERIMAGE=${CONTAINERIMAGE} 					\
			--build-arg IMAGE_REPOSITORY=$(IMAGE_REPOSITORY)				\
			--build-arg BASEOS=$(BASEOS)									\
			--build-arg PACKAGER=$(PACKAGER)								\
			--build-arg IMAGE_PATH=$(IMAGE_PATH)							\
			--build-arg BUILD=$(BUILD)										\
			--build-arg PGBACKREST_VERSION=$(PGBACKREST_VERSION)			\
			--build-arg OLD_PG_VERSIONS="$(OLD_PG_VERSIONS)"				\
			--build-arg PGVERSION=$(PGVERSION)

pgbackrest: pgbackrest-build;
			
postgres-build:
		$(DOCKER_BUILD) $(ROOTPATH)												\
			--file $(ROOTPATH)/docker/postgres/Dockerfile 						\
			--tag $(REPOSITORY)/$(IMAGE_PATH)/postgres:$(IMAGE_TAG)	\
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
			--build-arg ETCD_VERSION=$(ETCD_VERSION)
postgres: postgres-build

postgres-gis-build:
		$(DOCKER_BUILD) $(ROOTPATH)													\
			--file $(ROOTPATH)/docker/postgres-gis/Dockerfile 						\
			--tag $(REPOSITORY)/$(IMAGE_PATH)/postgres-gis:$(POSTGIS_IMAGE_TAG)		\
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
			--build-arg ETCD_VERSION=$(ETCD_VERSION)

postgres-gis: postgres-gis-build

postgres-oracle-build:
		$(DOCKER_BUILD) $(ROOTPATH)														\
			--file $(ROOTPATH)/docker/postgres-oracle/Dockerfile 						\
			--tag $(REPOSITORY)/$(IMAGE_PATH)/postgres-oracle:$(IMAGE_TAG)					\
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
			--build-arg ETCD_VERSION=$(ETCD_VERSION)

postgres-oracle: postgres-oracle-build

pgbouncer-build:
		$(DOCKER_BUILD) $(ROOTPATH)	--no-cache											\
			--file $(ROOTPATH)/docker/pgbouncer/Dockerfile 								\
			--tag $(REPOSITORY)/$(IMAGE_PATH)/pgbouncer:$(PGBOUNCER_IMAGE_TAG)							\
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
		$(DOCKER_BUILD) $(ROOTPATH)	 --no-cache											\
			--file $(ROOTPATH)/docker/exporter/Dockerfile 								\
			--tag $(REPOSITORY)/$(IMAGE_PATH)/exporter:$(IMAGE_TAG)						\
			--build-arg BASE_IMAGE=$(BASE_IMAGE)										\
			--build-arg CONTAINERIMAGE=${CONTAINERIMAGE} 								\
			--build-arg IMAGE_REPOSITORY=$(IMAGE_REPOSITORY)							\
			--build-arg BASEOS=$(BASEOS) 												\
			--build-arg PACKAGER=$(PACKAGER) 											\
			--build-arg IMAGE_PATH=$(IMAGE_PATH) 										\
			--build-arg GO_VERSION=$(GO_VERSION) 										\
			--build-arg BUILD=$(BUILD) 													\
			--build-arg PGBACKREST_VERSION=$(PGBACKREST_VERSION) 						\
			--build-arg PGVERSION=$(PGVERSION)

exporter: exporter-build

publicbeta-pg-build:
		$(DOCKER_BUILD) $(ROOTPATH)													\
			--file $(ROOTPATH)/docker/pg-public-beta/Dockerfile 					\
			--tag $(REPOSITORY)/$(IMAGE_PATH)/postgres:$(BETA_IMAGE_TAG)			\
			--build-arg BASE_IMAGE=$(BASE_IMAGE)									\
			--build-arg CONTAINERIMAGE=${CONTAINERIMAGE} 							\
			--build-arg IMAGE_REPOSITORY=$(IMAGE_REPOSITORY)						\
			--build-arg BASEOS=$(BASEOS) 											\
			--build-arg PACKAGER=$(PACKAGER) 										\
			--build-arg IMAGE_PATH=$(IMAGE_PATH) 									\
			--build-arg BUILD=$(BUILD) 												\
			--build-arg PGBACKREST_VERSION=$(PGBACKREST_VERSION) 					\
			--build-arg PATRONI_VERSION=$(PATRONI_VERSION) 							\
			--build-arg OLD_PG_VERSIONS="$(BETA_OLD_PG_VERSIONS)"						\
			--build-arg PGVERSION=$(BETAVERSION)									\
			--build-arg ETCD_VERSION=$(ETCD_VERSION)

publicbeta-pg: publicbeta-pg-build

publicbeta-pgbackrest-build:
		$(DOCKER_BUILD) $(ROOTPATH)													\
			--file $(ROOTPATH)/docker/pgbackrest-public-beta/Dockerfile 			\
			--tag $(REPOSITORY)/$(IMAGE_PATH)/pgbackrest:$(BETA_IMAGE_TAG)		 	\
			--build-arg BASE_IMAGE=$(BASE_IMAGE)									\
			--build-arg CONTAINERIMAGE=${CONTAINERIMAGE} 							\
			--build-arg IMAGE_REPOSITORY=$(IMAGE_REPOSITORY)						\
			--build-arg BASEOS=$(BASEOS)											\
			--build-arg PACKAGER=$(PACKAGER)										\
			--build-arg IMAGE_PATH=$(IMAGE_PATH)									\
			--build-arg BUILD=$(BUILD)												\
			--build-arg PGBACKREST_VERSION=$(PGBACKREST_VERSION)					\
			--build-arg OLD_PG_VERSIONS="$(BETA_OLD_PG_VERSIONS)"						\
			--build-arg PGVERSION=$(BETAVERSION)

publicbeta-pgbackrest: publicbeta-pgbackrest-build;

# Print a variable, e.g. `make print-IMAGE_TAG`
print-%:
		@echo '$($*)'
