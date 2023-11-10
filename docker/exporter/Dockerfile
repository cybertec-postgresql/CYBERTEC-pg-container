ARG CONTAINERSUITE
ARG BUILD
ARG BASEOS
 
FROM ${CONTAINERSUITE}/base:${BASEOS}-${BUILD}

# Dockerfile specific informations
ARG PACKAGER
ARG BASEOS
ARG PGBACKREST_VERSION
ARG PG_MAJOR

RUN if [ "$BASEOS" = "ubi8" ] ; then \
	${PACKAGER} -y install --nodocs \
		shadow-utils \
		tar \
		bzip2 \
		lz4 \
		#crunchy-backrest-${BACKREST_VER} \
		&& ${PACKAGER} -y clean all ; \
else \
	${PACKAGER} -y install --nodocs  \
		--setopt=skip_missing_names_on_install=False \
		bzip2 \
		lz4 \
		nano \
		git \
		go \
		dumb-init \ 
		&& ${PACKAGER} -y clean all ; \
fi

RUN git clone https://github.com/prometheus-community/postgres_exporter.git && cd postgres_exporter && make build
COPY launcher/exporter/launch.sh /
COPY scripts/exporter/queries/ /postgres_exporter/queries

ENTRYPOINT ["/usr/bin/dumb-init", "--"]

CMD ["/bin/sh", "/launch.sh", "init"]
#CMD ["/bin/sh", "/scripts/postgres/promote.sh"]