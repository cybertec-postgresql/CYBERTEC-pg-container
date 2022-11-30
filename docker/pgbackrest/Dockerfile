ARG CONTAINERSUITE
 
FROM ${CONTAINERSUITE}/base:0.0.1

# Dockerfile specific informations
ARG PACKAGER
ARG BASEOS
ARG PGBACKREST_VERSION

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
		pgbackrest-${PGBACKREST_VERSION} \
		&& ${PACKAGER} -y clean all ; \
fi

# Remove default pgbackrest-config
RUN rm /etc/pgbackrest.conf
RUN rm -rf /var/spool/pgbackrest

# Prepare all needed stuff
Run mkdir /opt/pgbackrest /backrestrepo /home/postgres home/postgres/pgdata
ADD bin/pgbackrest /opt/pgbackrest/bin
ADD bin/common /opt/pgbackrest/bin
ADD bin/pgbackrest-common /opt/pgbackrest/bin
# add pgbackrest-restore files
ADD bin/pgbackrest-restore /opt/pgbackrest/bin
ADD conf/pgbackrest-restore /opt/pgbackrest/conf
# set user and group ownership
RUN chown -R postgres:postgres /opt/pgbackrest  \
	/backrestrepo /home/postgres/pgdata

USER 26

ENTRYPOINT ["/opt/pgbackrest/bin/uid_postgres.sh"]

CMD ["/opt/pgbackrest/bin/start.sh"]