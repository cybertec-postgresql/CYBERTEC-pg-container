ARG CONTAINERSUITE
 
FROM ${CONTAINERSUITE}/base:0.0.1

# Dockerfile specific informations
ARG PACKAGER
ARG BASEOS
ARG PGBACKREST_VERSION
ARG PATRONI_VERSION
ARG PG_VERSION
ARG OLD_PG_VERSION
ARG PG_SUPPORTED_VERSIONS="$OLD_PG_VERSION $PG_VERSION"

# Spilo-specific
ENV BG_MON_COMMIT=e22182e129ce357b5aa80090fba2aacfc42b1996 \
    PG_AUTH_MON_COMMIT=52d90bbaa6d3c61195cd9532ebe036b1183808c5 \
    PG_MON_COMMIT=54fbdcc3cfe7e2a626bd96dda644d9a0c6866b58 \
    SET_USER=REL3_0_0 \
    PLPROFILER=REL4_1 \
    PG_PROFILE=0.3.6 \
    PAM_OAUTH2=v1.0.1 \
    PLANTUNER_COMMIT=800d81bc85da64ff3ef66e12aed1d4e1e54fc006 \
    PG_PERMISSIONS_COMMIT=314b9359e3d77c0b2ef7dbbde97fa4be80e31925 \
    PG_TM_AUX_COMMIT=6c012d38a4c1b0ba4a36952d60b0ce3a22ac9c3d

# Get some Standard-Stuff
RUN ${PACKAGER} -y update && ${PACKAGER} -y install --nodocs \
        openssh-clients \
        openssh-server \
        shadow-utils \
        tar \
        bzip2 \
        lz4 \
        python3 \
        python3-pip \
        python3-psycopg2 \
        python3-psutil \
        git \
        patchutils \
        binutils \
        make \
        gcc \
        curl \
        libcurl-devel \
        pam-devel \
    && ${PACKAGER} -y clean all;


RUN if [ "$BASEOS" = "ubi8" ] ; then \
	${PACKAGER} -y install --nodocs \		
		pgbackrest-${PGBACKREST_VERSION} \
		&& ${PACKAGER} -y clean all ; \
else \
	${PACKAGER} -y install --nodocs  \
		--setopt=skip_missing_names_on_install=False \
        pgbackrest-${PGBACKREST_VERSION} \
		&& ${PACKAGER} -y clean all ; \
fi

# Remove default pgbackrest-config
RUN rm /etc/pgbackrest.conf

# Install Patroni
RUN pip3 install patroni[kubernetes$EXTRAS]==$PATRONI_VERSION 

# Install pam_oauth2.so
RUN git clone -b $PAM_OAUTH2 --recurse-submodules https://github.com/zalando-pg/pam-oauth2.git \
    && make -C pam-oauth2 install \
    && curl -sL https://github.com/zalando-pg/bg_mon/archive/$BG_MON_COMMIT.tar.gz | tar xz \
    && curl -sL https://github.com/zalando-pg/pg_auth_mon/archive/$PG_AUTH_MON_COMMIT.tar.gz | tar xz \
    && curl -sL https://github.com/cybertec-postgresql/pg_permissions/archive/$PG_PERMISSIONS_COMMIT.tar.gz | tar xz \
    && curl -sL https://github.com/x4m/pg_tm_aux/archive/$PG_TM_AUX_COMMIT.tar.gz | tar xz \
    && curl -sL https://github.com/zubkov-andrei/pg_profile/archive/$PG_PROFILE.tar.gz | tar xz \
    && git clone -b $SET_USER https://github.com/pgaudit/set_user.git \
    && git clone https://github.com/timescale/timescaledb.git \
    && ${PACKAGER} -y install postgresql libevent brotli libbrotli \

# Install PostgreSQL
RUN for version in $PG_SUPPORTED_VERSIONS; do \
        ${PACKAGER} -y update && \
        ${PACKAGER} -y install postgresql-pltcl-${version} \
#                            postgresql${version}-dirtyread \
                            postgresql${version}-extra-window-functions \
                            postgresql${version}-first-last-agg \
                            postgresql${version}-hll \
                            postgresql${version}-hypopg \
                            postgresql${version}-pgaudit \
                            postgresql${version}-pg-checksums \
                            postgresql${version}-pgl-ddl-deploy \
                            postgresql${version}-pglogical \
                            postgresql${version}-pglogical-ticker \
                            postgresql${version}-pgq-node \
                            postgresql${version}-pldebugger \
                            postgresql${version}-pllua \
                            postgresql${version}-plpgsql-check \
                            postgresql${version}-plproxy \
                            postgis${POSTGIS_VERSION%.*}_${version}*\
#                           postgis-${POSTGIS_VERSION%.*}_${version}-scripts \
                            postgresql${version}-repack \
                            postgresql${version}-wal2json \
                            postgresql${version}-pgextwlist \
        && ${PACKAGER} -y clean all; \
    done