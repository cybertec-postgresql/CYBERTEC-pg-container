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
#ARG PG_SUPPORTED_VERSIONS="$PGVERSION"
ARG PG_SUPPORTED_VERSIONS="$OLD_PG_VERSIONS $PGVERSION"

RUN ${PACKAGER} -y install --nodocs  \
		--setopt=skip_missing_names_on_install=False \
		openssh-clients \
		openssh-server \
		bzip2 \
		lz4 \
		#postgresql${PGVERSION}-server \
		dumb-init \
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
RUN curl -LO https://dl.k8s.io/release/v1.26.0/bin/linux/amd64/kubectl && chmod +x kubectl 

FROM ${CONTAINERIMAGE}

ARG PGVERSION

COPY --from=builder /usr/bin/dumb-init /usr/bin/dumb-init
COPY --from=builder /etc/passwd /etc/passwd
COPY --from=builder /etc/group /etc/group
COPY --from=builder /usr/bin/pgbackrest /usr/bin/pgbackrest
COPY --from=builder /usr/share/licenses/pgbackrest/LICENSE /usr/share/licenses/pgbackrest/LICENSE
COPY --from=builder /var/lib/pgbackrest /var/lib/pgbackrest
COPY --from=builder /var/log/pgbackrest /var/log/pgbackrest
# Postgres
COPY --from=builder /usr/pgsql-* /usr/pgsql-*
COPY --from=builder /var/lib/pgsql /var/lib/pgsql
COPY --from=builder ./kubectl /usr/local/bin/


# add postgres user and group
#RUN groupadd postgres -g 26 && useradd postgres -u 26 -g 26

# Prepare all needed stuff
Run mkdir -p /opt/pgbackrest /backrestrepo /home/postgres /home/postgres/pgdata/pgbackrest/log

# add pgbackrest-restore files
ADD scripts/pgbackrest/ /opt/pgbackrest/bin/

# add pgbackrest-common files
ADD /scripts/nss_wrapper /scripts/nss_wrapper

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
