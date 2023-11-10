ARG CONTAINERSUITE
ARG BASEOS
ARG BUILD

FROM ${CONTAINERSUITE}/base:${BASEOS}-${BUILD} AS builder

# Dockerfile specific informations
ARG PACKAGER
ARG BASEOS
ARG PGEXPORTER_VERSION

RUN if [ "$BASEOS" = "ubi8" ] ; then \
	${PACKAGER} -y update \
		&& ${PACKAGER} -y install --nodocs \
		shadow-utils \
		tar \
		bzip2 \
		lz4 \
		git \
		go \
		make \
		dumb-init \ 		
		&& ${PACKAGER} -y clean all ; \
else \
	${PACKAGER} -y update \
		&& ${PACKAGER} -y install --nodocs  \
		--setopt=skip_missing_names_on_install=False \
		bzip2 \
		lz4 \
		nano \
		git \
		go \
		dumb-init \ 
		&& ${PACKAGER} -y clean all ; \
fi

RUN git clone -q -b ${PGEXPORTER_VERSION} https://github.com/prometheus-community/postgres_exporter.git \
	&& cd postgres_exporter \
	&& make build 

FROM registry.access.redhat.com/ubi8/ubi 

COPY --from=builder ./postgres_exporter/postgres_exporter /bin/postgres_exporter
COPY --from=builder /usr/bin/dumb-init /usr/bin/dumb-init
COPY launcher/exporter/launch.sh /

RUN groupadd -g 10631 postgres && useradd postgres -u 10014 -g 10631

USER   postgres

#COPY scripts/exporter/queries/ /postgres_exporter_queries

EXPOSE 9187

ENTRYPOINT ["/usr/bin/dumb-init", "--"]

CMD ["/bin/sh", "/launch.sh", "init"]
