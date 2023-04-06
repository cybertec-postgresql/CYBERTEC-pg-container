ARG CONTAINERSUITE
ARG BUILD
 
FROM ${CONTAINERSUITE}/base:0.0.${BUILD}

# Dockerfile specific informations
ARG PACKAGER
ARG BASEOS
ARG PGBACKREST_VERSION
ARG PG_MAJOR

RUN if [ "$BASEOS" = "ubi8" ] ; then \
	${PACKAGER} -y install --nodocs \
		openssh-clients \
		openssh-server \
		shadow-utils \
		tar \
		bzip2 \
		lz4 \
		&& ${PACKAGER} -y clean all ; \
else \
	${PACKAGER} -y install --nodocs  \
		--setopt=skip_missing_names_on_install=False \
		openssh-clients \
		openssh-server \
		bzip2 \
		lz4 \
		postgresql${PG_MAJOR}-server \
		
		nano \
		&& ${PACKAGER} -y clean all ; \
fi


# add benbchmark files
#ADD scripts/benchmark/ /opt/benchmark/bin/

# set user and group ownership
R#UN chown -R postgres:postgres /opt/benchmark

#COPY launcher/benchmark/launch.sh /
	
USER 26

#ENTRYPOINT ["/opt/pgbackrest/bin/uid_postgres.sh"]

#CMD ["/opt/pgbackrest/bin/start.sh"]

#CMD ["/bin/sh", "/launch.sh", "init"]