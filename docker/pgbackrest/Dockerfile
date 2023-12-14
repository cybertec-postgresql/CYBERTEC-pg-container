ARG CONTAINERSUITE
ARG BUILD
ARG BASEOS
 
FROM ${CONTAINERSUITE}/base:${BASEOS}-${BUILD}

# Dockerfile specific informations
ARG PACKAGER
ARG PGBACKREST_VERSION
ARG PGVERSION
ARG OLD_PG_VERSIONS
ARG PG_SUPPORTED_VERSIONS="$PGVERSION"
ARG PG_SUPPORTED_VERSIONS="$OLD_PG_VERSIONS $PGVERSION"

RUN if [ "$BASEOS" = "ubi8" ] ; then \
	${PACKAGER} -y install --nodocs \
		openssh-clients \
		openssh-server \
		shadow-utils \
		tar \
		bzip2 \
		lz4 \
		#crunchy-backrest-${BACKREST_VER} \
		&& ${PACKAGER} -y clean all ; \
else \
	${PACKAGER} -y install --nodocs  \
		--setopt=skip_missing_names_on_install=False \
		openssh-clients \
		openssh-server \
		bzip2 \
		lz4 \
		#postgresql${PGVERSION}-server \
		pgbackrest-${PGBACKREST_VERSION} \
		nano \
		&& ${PACKAGER} -y clean all ; \
fi

# Install postgres-server
RUN ${PACKAGER} -y update \
	&& for version in $PG_SUPPORTED_VERSIONS; do \
		${PACKAGER} -y install --nodocs postgresql${version}-server; \
    done \
	&& ${PACKAGER} -y clean all;

# Remove default pgbackrest-config
RUN rm /etc/pgbackrest.conf
RUN rm -rf /var/spool/pgbackrest

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

# Add kubectl
RUN curl -LO https://dl.k8s.io/release/v1.26.0/bin/linux/amd64/kubectl && chmod +x kubectl && mv ./kubectl /usr/local/bin/

# set user and group ownership
RUN chown -R postgres:postgres /opt/pgbackrest  \
	/backrestrepo /home/postgres/pgdata

#ENV PATH=$PATH:/usr/pgsql-$PGVERSION/bin
COPY launcher/pgbackrest/launch.sh /
	
VOLUME ["sshd", "/home/postgres/pgdata", "/backrestrepo"]

# Defines a unique directory name that will be utilized by the nss_wrapper in the UID script
ENV NSS_WRAPPER_SUBDIR="pgbackrest"

ENTRYPOINT ["/scripts/nss_wrapper/nss_wrapper_new.sh"]

USER 26

CMD ["/bin/sh", "/launch.sh", "init"]
