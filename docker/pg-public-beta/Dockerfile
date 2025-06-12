ARG IMAGE_PATH
ARG BUILD
ARG BASEOS
ARG PGVERSION
 
FROM ${IMAGE_PATH}/base:${BASEOS}-${BUILD} as builder

# Dockerfile specific informations
ARG PACKAGER
ARG PGBACKREST_VERSION
ARG PATRONI_VERSION
ARG PGVERSION
ARG OLD_PG_VERSIONS
ARG PG_SUPPORTED_VERSIONS="$PGVERSION"
ARG PG_SUPPORTED_VERSIONS="$OLD_PG_VERSIONS $PGVERSION"
ARG ETCD_VERSION
ARG ARCH

# Enable Beta-Repo
RUN ${PACKAGER} config-manager --set-enabled pgdg${PGVERSION}-updates-testing \
    && ${PACKAGER} config-manager --set-enabled pgdg${PGVERSION}-source-updates-testing;

# Spilo-specific
ENV PAM_OAUTH2=v1.0.1 \
    PG_PERMISSIONS=REL_1_3

# Get some Standard-Stuff
RUN ${PACKAGER} -y update && ${PACKAGER} -y install --nodocs --noplugins --setopt=install_weak_deps=0 \
		--setopt=skip_missing_names_on_install=False \
        openssh-clients \
        openssh-server \
        shadow-utils \
        tar \
        bzip2 \
        lz4 \
        python3 \
        python3-pip \
        python3-psycopg2 \
        git \
        patchutils \
        binutils \
        make \
        cmake \
        gcc \
        clang \
        pam-devel \
        wget \
        mlocate \
        git-clang-format \
        openssl-devel \
        ccache \
        redhat-rpm-config \
        krb5-devel \
        busybox \
        jq \
        rsync \
        dumb-init \ 
        libicu \
        pgbackrest-${PGBACKREST_VERSION} \
        cronie \
        libcurl-devel \
		&& ${PACKAGER} -y clean all;

# install etcdctl
RUN curl -L https://github.com/coreos/etcd/releases/download/v${ETCD_VERSION}/etcd-v${ETCD_VERSION}-linux-${ARCH}.tar.gz | tar xz -C /bin --strip=1 --wildcards --no-anchored --no-same-owner etcdctl etcd;

ENV PATHBACKUP = $PATH

RUN wget https://smarden.org/runit/runit-2.1.2.tar.gz -P /package/
COPY cron_unprivileged.c /package/

RUN pip3 install 'PyYAML<6.0' setuptools pystache loader kazoo meld3 boto python-etcd psutil requests cdiff ydiff==1.4.2 --upgrade \
    && if [[ $PATRONI_VERSION == "multisite-"* ]]; then \
        git clone -b $PATRONI_VERSION https://github.com/cybertec-postgresql/patroni; \
        pip3 install ./patroni[kubernetes,etcd,etcd3]; \
    else \
        pip3 install patroni[kubernetes$EXTRAS]==$PATRONI_VERSION --upgrade; \
    fi \
    && mkdir /usr/lib/postgresql \
    # Install pam_oauth2.so
    && git clone -b $PAM_OAUTH2 --recurse-submodules https://github.com/zalando-pg/pam-oauth2.git && make -C pam-oauth2 install \
    && git clone -b $PG_PERMISSIONS https://github.com/cybertec-postgresql/pg_permissions.git \
    && git clone https://github.com/dimitri/pgextwlist.git \
    && git clone https://github.com/crunchydata/pgnodemx \
\    
    && ${PACKAGER} -y install --nodocs --noplugins --setopt=install_weak_deps=0 postgresql${PGVERSION} libevent-devel brotli-devel libbrotli \
    && ${PACKAGER} -y clean all \
\
    # forbid creation of a main cluster when package is installed
    #&& sed -ri 's/#(create_main_cluster) .*$/\1 = false/' /etc/postgresql-common/createcluster.conf \
\
# Install PostgreSQL
    && for version in $PG_SUPPORTED_VERSIONS; do \
        ${PACKAGER} -y update && \
        ${PACKAGER} -y install postgresql${version}-pltcl \
        # Install PostgreSQL binaries, contrib, plproxy and multiple pl's
            && ${PACKAGER} -y install -y postgresql${version}-contrib \
                    postgresql${version}-devel \
            # Modify for using origial-spilo scripts
            && ln -s /usr/pgsql-${version} /usr/lib/postgresql/${version} \
            && export PATH=$PATHBACKUP:/usr/pgsql-${version}/bin \
    done \
    && ${PACKAGER} -y install --nodocs --noplugins --setopt=install_weak_deps=0 glibc-static \
    && ${PACKAGER} -y clean all;
    RUN gcc -s -shared -fPIC -o /usr/local/lib/cron_unprivileged.so /package/cron_unprivileged.c
    
    RUN cd /package && tar -xvzf runit-2.1.2.tar.gz && rm runit-2.1.2.tar.gz \
    && cd admin/runit-2.1.2 && package/install \
    && ln -s /usr/local/bin/runsvdir /usr/bin/runsvdir \
    && rm -rf /pg_permissions /pgextwlist /pg_stat_kcache /pgnodemx /timescaledb /pam-oauth2 \
    && rm /etc/pgbackrest.conf && rm -rf /var/spool/pgbackrest \
    && ${PACKAGER} -y remove $(rpm -qa "*devel*") python3-pip python3-wheel python3-dev python3-setuptools git patchutils flatpak glibc-static gcc glibc-devel \
    && ${PACKAGER} -y autoremove \
    && ${PACKAGER} -y clean dbcache \
    && ${PACKAGER} -y clean all;

FROM scratch 

ARG PGVERSION

COPY --from=builder / /

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
RUN rm -rf /etc/service && mkdir /home/postgres/pgdata && chown -R postgres:postgres /home/postgres/pgdata &&  chmod -R g=u /home/postgres/pgdata \
    && sed -i "s|/var/lib/pgsql.*|$PGHOME:/bin/bash|" /etc/passwd \
    && chown -R postgres:postgres $PGHOME $PGHOME/pgdata $RW_DIR \
    && rm -fr /var/spool/cron /var/tmp \
    && mkdir -p /var/spool \
    && ln -s $RW_DIR/cron /var/spool/cron \
    && ln -s $RW_DIR/tmp /var/tmp \
    && for d in /etc/runit/runsvdir/default/*; do \
        chmod 755 $d/* \
        && ln -s /run/supervise/$(basename $d) $d/supervise; \
    done \
    && chmod +r /etc/motd \
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
    && echo "source /etc/motd" >> /home/postgres/.bashrc \
    # Allow users in the root group to access the following files and dirs
    && if [ "$COMPRESS" != "true" ]; then \
        chmod 664 /etc/passwd \
        && chmod o+r /etc/shadow \
        && chgrp -R 0 $PGHOME $RW_DIR \
        && chmod -R g=u $PGHOME $RW_DIR \
        && usermod -a -G root postgres; \
    fi
        

COPY scripts bootstrap major_upgrade /scripts/
COPY launcher/postgres/launch.sh /

ENTRYPOINT ["/scripts/nss_wrapper/nss_wrapper.sh"]

USER postgres

CMD ["/bin/sh", "/launch.sh", "init"]
