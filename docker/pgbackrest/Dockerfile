ARG CONTAINERSUITE
ARG BUILD
ARG BASEOS
ARG CONTAINERIMAGE
 
FROM ${CONTAINERSUITE}/base:${BASEOS}-${BUILD} AS builder

# Dockerfile specific informations
ARG PACKAGER
ARG PGBACKREST_VERSION
ARG PGVERSION
ARG OLD_PG_VERSIONS
ARG PG_SUPPORTED_VERSIONS="$OLD_PG_VERSIONS $PGVERSION"

RUN ${PACKAGER} -y install --nodocs  \
		--setopt=skip_missing_names_on_install=False \
		openssh-clients \
		openssh-server \
		bzip2 \
		lz4 \
		zstd \
		libicu \
		dumb-init \
		jq \
		pgbackrest-${PGBACKREST_VERSION} \
	&& ${PACKAGER} -y clean all ; 

# Install postgres-server
RUN ${PACKAGER} -y update \
	&& for version in $PG_SUPPORTED_VERSIONS; do \
		${PACKAGER} -y install --nodocs postgresql${version}-server; \
    done \
	&& ${PACKAGER} -y clean all;

# Remove default pgbackrest-config
RUN rm /etc/pgbackrest.conf
RUN rm -rf /var/spool/pgbackrest

# Add kubectl
RUN curl -LO https://dl.k8s.io/release/v1.30.0/bin/linux/amd64/kubectl && chmod +x kubectl 

FROM ${CONTAINERIMAGE} as micro

ARG PGVERSION

COPY --from=builder /usr/bin/dumb-init /usr/bin/dumb-init
COPY --from=builder /etc/passwd /etc/passwd
COPY --from=builder /etc/group /etc/group
COPY --from=builder /usr/lib64 /usr/lib64
# SSH-client
COPY --from=builder /etc/ssh /etc/ssh
COPY --from=builder /usr/bin/ssh /usr/bin/ssh
COPY --from=builder /usr/libexec/openssh /usr/libexec/openssh
# pgBackRest
COPY --from=builder /usr/bin/pgbackrest /usr/bin/pgbackrest
COPY --from=builder /usr/share/licenses/pgbackrest/LICENSE /usr/share/licenses/pgbackrest/LICENSE
COPY --from=builder /var/lib/pgbackrest /var/lib/pgbackrest
COPY --from=builder /var/log/pgbackrest /var/log/pgbackrest
# Postgres
COPY --from=builder /var/lib/pgsql /var/lib/pgsql
COPY --from=builder ./kubectl /usr/local/bin/
# lz4
COPY --from=builder /usr/bin/lz4* /usr/bin/lz4*
# zstd
COPY --from=builder /usr/bin/zstd* /usr/bin/zstd*
# Others
COPY --from=builder /usr/bin/sed /usr/bin/sed
COPY --from=builder /usr/bin/jq /usr/bin/jq
COPY --from=builder /usr/bin/watch /usr/bin/watch
COPY --from=builder /usr/share/locale /usr/share/locale
COPY --from=builder /usr/lib /usr/lib
COPY --from=builder /usr/lib64 /usr/lib64
# PostgreSQL
# TODO: implement a method that works with $PG_SUPPORTED_VERSIONS
COPY --from=builder /usr/pgsql-13 /usr/pgsql-13
COPY --from=builder /usr/pgsql-14 /usr/pgsql-14
COPY --from=builder /usr/pgsql-15 /usr/pgsql-15
COPY --from=builder /usr/pgsql-16 /usr/pgsql-16
COPY --from=builder /var/lib/pgsql /var/lib/pgsql
COPY --from=builder /usr/bin/pg_* /usr/bin/

# libraries
COPY --from=builder /usr/bin/nss_wrapper.pl /usr/bin/nss_wrapper.pl 
# COPY --from=builder /usr/lib64/libnss_wrapper.so /usr/lib64/libnss_wrapper.so
COPY --from=builder /usr/share/man/man1 /usr/share/man/man1
COPY --from=builder /usr/bin/envsubst /usr/bin/envsubst

# add postgres user and group
#RUN groupadd postgres -g 26 && useradd postgres -u 26 -g 26

# Prepare all needed stuff
Run mkdir -p /opt/pgbackrest /backrestrepo /home/postgres /home/postgres/pgdata/pgbackrest/log

# add pgbackrest-restore files
ADD scripts/pgbackrest/ /opt/pgbackrest/bin/

# add pgbackrest-common files
ADD /scripts/nss_wrapper /scripts/nss_wrapper

FROM scratch 
COPY --from=micro / /

# set user and group ownership
RUN chown -R postgres:postgres /opt/pgbackrest  \
	/backrestrepo /home/postgres/pgdata/pgbackrest /home/postgres/pgdata

RUN  mkdir -p /etc/pgbackrest \
	&& chown -R postgres:postgres /etc/pgbackrest

RUN chmod -R g=u /etc/pgbackrest \
	&& rm -f /run/nologin

RUN mkdir /.ssh && chown postgres:postgres /.ssh && chmod o+rwx /.ssh

# set user and group ownership
RUN chown -R postgres:postgres /opt/pgbackrest  \
	/backrestrepo /home/postgres/pgdata

#ENV PATH=$PATH:/usr/pgsql-$PGVERSION/bin
COPY launcher/pgbackrest/launch.sh /
	
VOLUME ["sshd", "/home/postgres/pgdata", "/backrestrepo"]

ENTRYPOINT ["/scripts/nss_wrapper/nss_wrapper.sh"]

USER 26

CMD ["dumb-init", "/launch.sh", "init"]

