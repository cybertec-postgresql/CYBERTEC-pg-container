# CYBERTEC-pg-container: PostgreSQL-HA-Cluster based on Rocky-Linux

CYBERTEC-pg-container is a container suite that combines PostgreSQL, Patroni, etcd and pgBackRest to provide highly available (HA) PostgreSQL clusters.
  
The images are based on Rocky Linux 9 and can be run locally or in container orchestrations such as Docker, Podman, Kubernetes, OpenShift or Rancher.
This project also forms the basis for the [CYBERTEC-pg-operator(cpo)](https://github.com/cybertec-postgresql/CYBERTEC-pg-operator).

## Container Images

Ready-made images are available on Docker Hub:[https://hub.docker.com/repository/docker/cybertecpostgresql/cybertec-pg-container](https://hub.docker.com/repository/docker/cybertecpostgresql/cybertec-pg-container)

## Build Instructions (optional)

If you want to build the images yourself, you can do so with `make`.
Ensure that the path to the container folder in the Makefile is adjusted to your system, otherwise the Dockerfiles will not be found.
Simply adjust the BasePath or directly the RootPath.

```Makefile
BASEPATH ?= $(HOME)
ROOTPATH ?= $(BASEPATH)/src/github.com/cybertec/cybertec-pg-container
```

### Requirements

- Linux system with Docker or Podman
- make installed

### Example

```bash
make all
# or individual components:
make postgres
make postgres-gis
make pgbackrest
make pgbouncer
make exporter
```

### Run Postgres-Image locally 
```bash
    docker run postgres -it IMAGEPATH:IMAGETAG

    docker exec -it postgres /bin/bash
```

## Postgres-Versions and Extensions
The container currently contains major releases 13 to 17. ENV PGVERSION can be used to select the desired version during initialisation.
The latest minor release for each major version is always used.
Hint: PostgreSQL 13 is deprecated.

### Extensions
In addition to the Contrib packages with the basic extensions, the following extensions are also included in the container:

 - **credcheck**: Allows you to define password policies, login information checks and more.

- **pg_cron**: Allows you to schedule and execute time-controlled jobs directly in PostgreSQL.

- **pg_permissions**: Provides advanced functions for querying and managing database permissions.

- **pg_vector**: Adds support for vector operations (e.g. for AI/embedding data).

- **pgAudit**: Enables PostgreSQL audit logging. Ideal for security and compliance requirements.

- **pgauditlogtofile**: When enabled, pgAudit logs are written directly to files instead of the standard logs.

- **pgextwlist**: Manages a ‘whitelist’ of permitted extensions to prevent the use of insecure extensions.

- **pgnodemx**: Supports multi-node cluster functions, e.g. for sharding or replication extensions.

- **plpython3**: Enables the use of Python 3 as an embedded programming language in PostgreSQL.

- **set_user**: Enables setting and switching user contexts within the database for administrative tasks.

- **timescaleDB**: Adds functions for time series data, including hypertables and continuous aggregations.

In addition, there is an additional postgis-image. It contains all of the extensions listed above and Postgis.

## Environment-Variables
### postgres-container
#### Patroni and PostgreSQL

- **ETCD3_HOST**: the DNS A record pointing to Etcd hosts.
- **ETCD3_HOSTS**: list of Etcd hosts in format '"host1:port1","host2:port2",...,"hostN:portN"'.
- **ETCD3_DISCOVERY_DOMAIN**: the DNS SRV record pointing to Etcd hosts.
- **ETCD3_URL**: url for Etcd host in format http(s)://host1:port
- **ETCD3_PROXY**: url for Etcd Proxy format http(s)://host1:port
- **ETCD3_CACERT**: Etcd CA certificate. If present it will enable validation.
- **ETCD3_CERT**: Etcd client certificate.
- **ETCD3_KEY**: Etcd client certificate key. Can be empty if the key is part of certificate.
- **PGHOME**: filesystem path where to put PostgreSQL home directory (/home/postgres by default)
- **APIPORT**: TCP port to Patroni API connections (8008 by default)
- **CRONTAB**: anything that you want to run periodically as a cron job (empty by default)
- **PGROOT**: a directory where we put the pgdata (by default /home/postgres/pgroot). One may adjust it to point to the mount point of the persistent volume, such as EBS.
- **WALE_TMPDIR** or **WALG_TMPDIR**: directory to store WAL-G temporary files. PGROOT/../tmp by default, make sure it has a few GBs of free space.
- **PGDATA**: location of PostgreSQL data directory, by default PGROOT/pgdata.
- **PGUSER_STANDBY**: username for the replication user, 'standby' by default.
- **PGPASSWORD_STANDBY**: a password for the replication user, 'standby' by default.
- **STANDBY_HOST**: hostname or IP address of the primary to stream from.
- **STANDBY_PORT**: TCP port on which the primary is listening for connections. Patroni will use "5432" if not set.
- **STANDBY_PRIMARY_SLOT_NAME**: replication slot to use on the primary.
- **PGUSER_ADMIN**: username for the default admin user, 'admin' by default.
- **PGPASSWORD_ADMIN**: a password for the default admin user, 'cola' by default.
- **USE_ADMIN**: whether to use the admin user or not.
- **PGUSER_SUPERUSER**: username for the superuser, 'postgres' by default.
- **PGPASSWORD_SUPERUSER**: a password for the superuser, 'zalando' by default
- **ALLOW_NOSSL**: set to allow clients to connect without SSL enabled.
- **PGPORT**: port PostgreSQL listens to for client connections, 5432 by default
- **PGVERSION**: Specifies the version of postgreSQL to reference in the bin_dir variable (/usr/lib/postgresql/PGVERSION/bin)  (13/14/15/16/17)
- **SCOPE**: cluster name, multiple Spilos belonging to the same cluster must have identical scope.
- **SSL_CA_FILE**: path to the SSL CA certificate file inside the container (by default: '')
- **SSL_CRL_FILE**: path to the SSL Certificate Revocation List file inside the container (by default: '')
- **SSL_CERTIFICATE_FILE**: path to the SSL certificate file inside the container (by default /run/certs/server.crt), Spilo will generate one if not present.
- **SSL_PRIVATE_KEY_FILE**: path to the SSL private key within the container (by default /run/certs/server.key), Spilo will generate one if not present
- **SSL_CA**: content of the SSL CA certificate in the SSL_CA_FILE file (by default: '')
- **SSL_CRL**: content of the SSL Certificate Revocation List in the SSL_CRL_FILE file (by default: '')
- **SSL_CERTIFICATE**: content of the SSL certificate in the SSL_CERTIFICATE_FILE file (by default /run/certs/server.crt).
- **SSL_PRIVATE_KEY**: content of the SSL private key in the SSL_PRIVATE_KEY_FILE file (by default /run/certs/server.key).
- **SSL_RESTAPI_CA_FILE**: path to the Patroni REST Api SSL CA certificate file inside the container (by default: '')
- **SSL_RESTAPI_CERTIFICATE_FILE**: path to the Patroni REST Api SSL certificate file inside the container (by default /run/certs/restapi.crt), The Container will generate one if not present.
- **SSL_RESTAPI_PRIVATE_KEY_FILE**: path to the Patroni REST Api SSL private key within the container (by default /run/certs/restapi.key), The Container will generate one if not present
- **SSL_RESTAPI_CA**: content of the Patroni REST Api SSL CA certificate in the SSL_RESTAPI_CA_FILE file (by default: '')
- **SSL_RESTAPI_CERTIFICATE**: content of the REST Api SSL certificate in the SSL_CERTIFICATE_FILE file (by default /run/certs/server.crt).
- **SSL_RESTAPI_PRIVATE_KEY**: content of the REST Api SSL private key in the SSL_PRIVATE_KEY_FILE file (by default /run/certs/server.key).
- **SSL_TEST_RELOAD**: whenever to test for certificate rotation and reloading (by default True if SSL_PRIVATE_KEY_FILE has been set).
- **RESTAPI_CONNECT_ADDRESS**: when you configure Patroni RESTAPI in SSL mode some safe API (i.e. switchover) perform hostname validation. In this case could be convenient configure ````restapi.connect_address````as a hostname instead of IP. For example, you can configure it as "$(POD_NAME).<service name>".
- **DCS_ENABLE_KUBERNETES_API**: a non-empty value forces Patroni to use Kubernetes as a DCS. Default is empty.
- **KUBERNETES_USE_CONFIGMAPS**: a non-empty value makes Patroni store its metadata in ConfigMaps instead of Endpoints when running on Kubernetes. Default is empty.
- **KUBERNETES_ROLE_LABEL**: name of the label containing Postgres role when running on Kubernetes. Default is 'spilo-role'.
- **KUBERNETES_LEADER_LABEL_VALUE**: value of the pod label if Postgres role is primary when running on Kubernetes. Default is 'master'.
- **KUBERNETES_STANDBY_LEADER_LABEL_VALUE**: value of the pod label if Postgres role is standby_leader when running on Kubernetes. Default is 'master'.
- **KUBERNETES_SCOPE_LABEL**: name of the label containing cluster name. Default is 'version'.
- **KUBERNETES_LABELS**: a JSON describing names and values of other labels used by Patroni on Kubernetes to locate its metadata. Default is '{"application": "spilo"}'.
- **KUBERNETES_BOOTSTRAP_LABELS**: a JSON describing names and values of labels used by Patroni as ``kubernetes.bootstrap_labels``. Default is empty.
- **ENABLE_WAL_PATH_COMPAT**: old Spilo images were generating wal path in the backup store using the following template ``/spilo/{WAL_BUCKET_SCOPE_PREFIX}{SCOPE}

#### Initdb
- **INITDB_LOCALE**: database cluster's default UTF-8 locale (en_US by default)

  Hint: locale-provider is icu

#### pgbackRest

- **USE_PGBACKREST**: Set to true if you want to use pgBackRest
- **REPO_HOST**: Set to true if you want to use local storage for pgBackRest instead of s3,gcs or azure blob. Default: false
 

### pgBackRest-Container
- **USE_PGBACKREST**: Set to true if you want to use pgBackRest
- **MODE**: Set to repo if you want to use the container as repo-host for you cluster. Set to restore if you want to use it as a restore container. 
- **RESTORE_COMMAND**: Add your restore parameters (needs Mode set to restore) example: ' --repo=1 --set=20251009-085046F --type=immediate'
- **RESTORE_ENABLE**: Set to true if you want to do a restore (needs Mode set to restore)

### Exporter-Container
- **DATA_SOURCE_URI**:  Specify the full URI of the database to be monitored. Example: `localhost:5432/postgres?sslmode=require`
- **DATA_SOURCE_USER**: Username of the PostgreSQL account used by the exporter to access the database. Ensure that this user has sufficient read permissions.
- **DATA_SOURCE_PASS**: Password for the user specified above.

### pgBouncer-Container
- **PGHOST**: Host name or IP address of the PostgreSQL server to which pgBouncer should establish connections.
- **PGPORT**: Port of the PostgreSQL server (default: 5432).
- **PGUSER**: User name for connecting to PostgreSQL. pgBouncer uses this user to manage pool connections.
- **PGSCHEMA**: The schema within the database that pgBouncer should access by default.
- **PGPASSWORD**: Password of the user specified above.
- **CONNECTION_POOLER_PORT**: TCP port on which pgBouncer listens for client connections (default: 6432)
- **CONNECTION_POOLER_MODE**: Operating mode of pgBouncer. Typical values are `session`, `transaction` or `statement`.
- **CONNECTION_POOLER_DEFAULT_SIZE**: Default size of the connection pool per database and user.
- **CONNECTION_POOLER_MIN_SIZE**: Minimum number of connections that pgBouncer maintains.
- **CONNECTION_POOLER_RESERVE_SIZE**: Number of reserve connections that are additionally available during high load.
- **CONNECTION_POOLER_MAX_CLIENT_CONN**: Maximum number of simultaneous client connections that pgBouncer accepts
- **CONNECTION_POOLER_MAX_DB_CONN**: Maximum number of connections that can be established to a single database.