ARG CONTAINERSUITE
ARG BUILD
ARG BASEOS
 
FROM ${CONTAINERSUITE}/base:${BASEOS}-${BUILD}

# Dockerfile specific informations
ARG PACKAGER
ARG PGBACKREST_VERSION
ARG PATRONI_VERSION
ARG PGVERSION
ARG OLD_PG_VERSIONS
ARG PG_SUPPORTED_VERSIONS="$PGVERSION"
ARG PG_SUPPORTED_VERSIONS="$OLD_PG_VERSIONS $PGVERSION"
ARG TIMESCALEDB="1.7.5 2.3.1 2.8.1"

# Spilo-specific
ENV SET_USER=REL3_0_0 \
    #BG_MON_COMMIT=e22182e129ce357b5aa80090fba2aacfc42b1996 \
    #PG_AUTH_MON_COMMIT=52d90bbaa6d3c61195cd9532ebe036b1183808c5 \
    #PG_MON_COMMIT=54fbdcc3cfe7e2a626bd96dda644d9a0c6866b58 \
    PLPROFILER=REL4_1 \
    PG_PROFILE=0.3.6 \
    PAM_OAUTH2=v1.0.1 \
    PLANTUNER_COMMIT=800d81bc85da64ff3ef66e12aed1d4e1e54fc006 \
    PG_PERMISSIONS_COMMIT=314b9359e3d77c0b2ef7dbbde97fa4be80e31925 \
    PG_TM_AUX_COMMIT=6c012d38a4c1b0ba4a36952d60b0ce3a22ac9c3d

# Get some Standard-Stuff
RUN ${PACKAGER} -y update && ${PACKAGER} -y install --nodocs --noplugins --setopt=install_weak_deps=0 \
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
        python3-requests \
        python3-etcd \
        #python3-pyyaml \
        git \
        patchutils \
        binutils \
        make \
        cmake \
        gcc \
        #curl \
        libcurl-devel \
        pam-devel \
        wget \
        mlocate \
        git-clang-format \
        openssl-devel \
        ccache \
        redhat-rpm-config \
        krb5-devel \
        busybox \
        dpkg \
        jq \
        rsync \
    && ${PACKAGER} -y clean all;


RUN if [ "$BASEOS" = "ubi8" ] ; then \
	${PACKAGER} -y install --nodocs --noplugins --setopt=install_weak_deps=0 \		
		pgbackrest-${PGBACKREST_VERSION} \
		&& ${PACKAGER} -y clean all ; \
else \
	${PACKAGER} -y install --nodocs --noplugins --setopt=install_weak_deps=0  \
		--setopt=skip_missing_names_on_install=False \
        pgbackrest-${PGBACKREST_VERSION} \
		&& ${PACKAGER} -y clean all ; \
fi

# install etcdctl
RUN ETCDVERSION=3.3.27 \
    && curl -L https://github.com/coreos/etcd/releases/download/v${ETCDVERSION}/etcd-v${ETCDVERSION}-linux-$(dpkg --print-architecture).tar.gz \
    | tar xz -C /bin --strip=1 --wildcards --no-anchored --no-same-owner etcdctl etcd;

# Install Patroni
RUN pip3 install 'PyYAML<6.0' setuptools pystache loader dumb-init kazoo meld3 boto 
#swiftclient
RUN ${PACKAGER} -y install --nodocs --noplugins --setopt=install_weak_deps=0 \
                    python3-etcd python3-consul  \
                    python3-gevent python3-greenlet python3-cachetools \
                    python3-rsa python3-pyasn1-modules  python3-cffi \
    && ${PACKAGER} -y clean all;

    # python3-kazoo python3-meld3 python3-boto python3-swiftclient

RUN pip3 install patroni[kubernetes$EXTRAS]==$PATRONI_VERSION

RUN mkdir /usr/lib/postgresql
ENV PATHBACKUP = $PATH
#ENV PATH=$PATH:/usr/pgsql-$PGVERSION/bin
#RUN echo $PATH
# Install pam_oauth2.so
RUN git clone -b $PAM_OAUTH2 --recurse-submodules https://github.com/zalando-pg/pam-oauth2.git \
    && make -C pam-oauth2 install \
    #&& curl -sL https://github.com/zalando-pg/bg_mon/archive/$BG_MON_COMMIT.tar.gz | tar xz \
    #&& curl -sL https://github.com/zalando-pg/pg_auth_mon/archive/$PG_AUTH_MON_COMMIT.tar.gz | tar xz \
    && curl -sL https://github.com/cybertec-postgresql/pg_permissions/archive/$PG_PERMISSIONS_COMMIT.tar.gz | tar xz \
    && curl -sL https://github.com/x4m/pg_tm_aux/archive/$PG_TM_AUX_COMMIT.tar.gz | tar xz \
    && curl -sL https://github.com/zubkov-andrei/pg_profile/archive/$PG_PROFILE.tar.gz | tar xz \
    && git clone -b $SET_USER https://github.com/pgaudit/set_user.git \
    && git clone https://github.com/timescale/timescaledb.git \
    && git clone https://github.com/dimitri/pgextwlist.git \
    && git clone https://github.com/powa-team/pg_stat_kcache.git \
    && git clone https://github.com/crunchydata/pgnodemx \
    #&& git clone https://github.com/pgq/pgqd.git \
\    
    && ${PACKAGER} -y install --nodocs --noplugins --setopt=install_weak_deps=0 postgresql${PGVERSION} libevent-devel brotli-devel libbrotli \
    && ${PACKAGER} -y clean all\
\
    # forbid creation of a main cluster when package is installed
    #&& sed -ri 's/#(create_main_cluster) .*$/\1 = false/' /etc/postgresql-common/createcluster.conf \
\
# Install PostgreSQL
    && for version in $PG_SUPPORTED_VERSIONS; do \
        ${PACKAGER} -y update && \
        ${PACKAGER} -y install postgresql${version}-pltcl \
#                            postgresql${version}-dirtyread \
#                            postgresql${version}-extra-window-functions \
#                            postgresql${version}-first-last-agg \
#                            postgresql${version}-hll \
#                            postgresql${version}-hypopg \
                            pgaudit*${version} \
#                            postgresql${version}-pg-checksums \
#                            postgresql${version}-pgl-ddl-deploy \
#                            postgresql${version}-pglogical \
#                            postgresql${version}-pglogical-ticker \
#                            postgresql${version}-pgq-node \
#                            postgresql${version}-pldebugger \
#                            postgresql${version}-pllua \
#                            postgresql${version}-plpgsql-check \
#                            postgresql${version}-plproxy \
#                            postgresql${version}-repack \
#                            postgresql${version}-wal2json \
        #&& ${PACKAGER} -y clean all; \
        # Install PostgreSQL binaries, contrib, plproxy and multiple pl's
            && ${PACKAGER} -y install -y postgresql${version}-contrib \
                    postgresql${version}-plpython3 postgresql${version}-devel \
                    pg_cron_${version} \
                    #postgresql-${version}-pgq3 \
                    #postgresql-${version}-pg-stat-kcache $EXTRAS \
            # Modify for using origial-spilo scripts
            && ln -s /usr/pgsql-${version} /usr/lib/postgresql/${version} \
            && export PATH=$PATHBACKUP:/usr/pgsql-${version}/bin \
\
            # Install TimescaleDB           
            && cd /timescaledb \
            && for v in $TIMESCALEDB; do \
                    git checkout $v \
                    && sed -i "s/VERSION 3.11/VERSION 3.10/" CMakeLists.txt \
                    && if BUILD_FORCE_REMOVE=true ./bootstrap -DREGRESS_CHECKS=OFF -DWARNINGS_AS_ERRORS=OFF \
                        -DTAP_CHECKS=OFF -DPG_CONFIG=/usr/pgsql-$version/bin/pg_config \
                        -DAPACHE_ONLY=$TIMESCALEDB_APACHE_ONLY -DSEND_TELEMETRY_DEFAULT=NO; then \
                            make -C build install \
                            && strip /usr/pgsql-$version/lib/timescaledb*.so; \
                    fi \
                    && git reset --hard \
                    && git clean -f -d; \
                done \
            && cd .. \
            && for n in bg_mon-${BG_MON_COMMIT} pg_auth_mon-${PG_AUTH_MON_COMMIT} set_user pg_permissions-${PG_PERMISSIONS_COMMIT} pg_tm_aux-${PG_TM_AUX_COMMIT} pg_profile-${PG_PROFILE} $EXTRA_EXTENSIONS; do \
                make -C $n USE_PGXS=1 clean install-strip; \ 
            done \
            && cd /pgextwlist && make clean && make && make install \
            && cd /pg_stat_kcache && make clean && make && make install \
            && cd /pgnodemx && make USE_PGXS=1 clean && make USE_PGXS=1 && make USE_PGXS=1 install \
            #&& cd /pgqd && ./configure --prefix=/opt && make && make install \
        && ${PACKAGER} -y clean all; \
    done

# Clean Up git-repos
RUN rm -rf /pgextwlist \
    && rm -rf /pg_stat_kcache \
    && rm -rf /pgnodemx ;

EXPOSE 5432 8008 8080
ENV LC_ALL=en_US.utf-8 \
    PATH=$PATH:/usr/pgsql-$PGVERSION/bin \
    PGHOME=/home/postgres \
    RW_DIR=/run \
    TIMESCALEDB=$TIMESCALEDB \
    DEMO=$DEMO

ENV LOG_ENV_DIR=$RW_DIR/etc/log.d/env \
    PGROOT=$PGHOME/pgdata/pgroot

ENV PGDATA=$PGROOT/data \
    PGLOG=$PGROOT/pg_log

WORKDIR $PGHOME

COPY motd /etc/
#COPY runit /etc/service/

COPY runit /etc/runit/runsvdir/default/
COPY pgq_ticker.ini $PGHOME/
RUN rm -rf /etc/service

RUN sed -i "s|/var/lib/pgsql.*|$PGHOME:/bin/bash|" /etc/passwd \
        && chown -R postgres:postgres $PGHOME $RW_DIR \
        && rm -fr /var/spool/cron /var/tmp \
        && mkdir -p /var/spool \
        && ln -s $RW_DIR/cron /var/spool/cron \
        && ln -s $RW_DIR/tmp /var/tmp \
        && for d in /etc/runit/runsvdir/default/*; do \
            chmod 755 $d/* \
            && ln -s /run/supervise/$(basename $d) $d/supervise; \
        done \
        && ln -snf $RW_DIR/service /etc/service \
        #&& ln -s $RW_DIR/pam.d-postgresql /etc/pam.d/postgresql \
        && ln -s $RW_DIR/postgres.yml $PGHOME/postgres.yml \
        && ln -s $RW_DIR/.bash_history /root/.bash_history \
        && ln -s $RW_DIR/postgresql/.bash_history $PGHOME/.bash_history \
        && ln -s $RW_DIR/postgresql/.psql_history $PGHOME/.psql_history \
        && ln -s $RW_DIR/etc $PGHOME/etc \
        && for d in $PGHOME /root; do \
            d=$d/.config/patroni \
            && mkdir -p $d \
            && ln -s $PGHOME/postgres.yml $d/patronictl.yaml; \
        done \
        && sed -i 's/set compatible/set nocompatible/' /etc/vimrc \
        && echo "PATH=\"$PATH\"" > /etc/environment \
        && for e in TERM=linux LC_ALL=C.UTF-8 LANG=C.UTF-8 EDITOR=editor; \
            do echo "export $e" >> /etc/bash.bashrc; \
        done \
        && ln -s /etc/skel/.bashrc $PGHOME/.bashrc \
        && echo "source /etc/motd" >> /root/.bashrc \
        # Allow users in the root group to access the following files and dirs
        && if [ "$COMPRESS" != "true" ]; then \
           chmod 664 /etc/passwd \
           && chmod o+r /etc/shadow \
           && chgrp -R 0 $PGHOME $RW_DIR \
           && chmod -R g=u $PGHOME $RW_DIR \
           && usermod -a -G root postgres; \
        fi
        
# Remove default pgbackrest-config and spool-path
RUN rm /etc/pgbackrest.conf && rm -rf /var/spool/pgbackrest;

COPY scripts bootstrap major_upgrade /scripts/
COPY launcher/postgres/launch.sh /

RUN ${PACKAGER} -y install --nodocs --noplugins --setopt=install_weak_deps=0 \
                    glibc-devel glibc-static

RUN  mkdir /package && cd /package && wget http://smarden.org/runit/runit-2.1.2.tar.gz && tar -xvzf runit-2.1.2.tar.gz && rm runit-2.1.2.tar.gz && cd admin/runit-2.1.2 && package/install

# Modify for using origial-spilo scripts
RUN ln -s /usr/local/bin/dumb-init /usr/bin/dumb-init && ln -s /usr/local/bin/runsvdir /usr/bin/runsvdir

#RUN curl -LO https://dl.k8s.io/release/v1.26.0/bin/linux/amd64/kubectl && chmod +x kubectl && mv ./kubectl /usr/local/bin/

USER 26

#RUN chown -R postgres:root /var/lib/pgsql
CMD ["/bin/sh", "/launch.sh", "init"]