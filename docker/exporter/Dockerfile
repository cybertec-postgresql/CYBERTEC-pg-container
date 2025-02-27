ARG CONTAINERSUITE
ARG BUILD
ARG BASEOS
ARG CONTAINERIMAGE
 
FROM ${CONTAINERSUITE}/base:${BASEOS}-${BUILD} AS builder

ARG PACKAGER

RUN ${PACKAGER} -y install --nodocs  \
		--setopt=skip_missing_names_on_install=False \
		git \
		dumb-init \ 
		wget \
		make \
		&& ${PACKAGER} -y clean all ;

RUN wget https://go.dev/dl/go1.23.6.linux-amd64.tar.gz  && tar -xzf go1.23.6.linux-amd64.tar.gz && mv go /usr/local 
ENV PATH=$PATH:/usr/local/go/bin

RUN git clone https://github.com/cybertec-postgresql/postgres_exporter.git && cd postgres_exporter && make build;

FROM ${CONTAINERIMAGE}
COPY --from=builder /usr/bin/dumb-init /usr/bin/dumb-init
COPY --from=builder ./postgres_exporter/postgres_exporter /bin/postgres_exporter

COPY launcher/exporter/launch.sh /
COPY scripts/exporter/queries/ /postgres_exporter/queries

EXPOSE 9187

ENTRYPOINT ["/usr/bin/dumb-init", "--"]

CMD ["/bin/sh", "/launch.sh", "init"]
