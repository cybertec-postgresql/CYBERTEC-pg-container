ARG CONTAINERSUITE
ARG BUILD
ARG BASEOS
ARG CONTAINERIMAGE
 
FROM ${CONTAINERSUITE}/base:${BASEOS}-${BUILD} AS builder

ARG PACKAGER

RUN ${PACKAGER} -y install --nodocs  \
		--setopt=skip_missing_names_on_install=False \
		git \
		go \
		dumb-init \ 
		pgbouncer \
		&& ${PACKAGER} -y clean all ;


# FROM ${CONTAINERIMAGE}
# COPY --from=builder /usr/bin/dumb-init /usr/bin/dumb-init
# COPY --from=builder ./postgres_exporter/postgres_exporter /bin/postgres_exporter

 COPY launcher/pgbouncer/launch.sh /
 COPY scripts/pgbouncer/* /etc/pgbouncer/
 # add pgbackrest-common files
ADD /scripts/nss_wrapper/nss_wrapper_pgbouncer.sh /scripts/nss_wrapper/nss_wrapper_pgbouncer.sh

 RUN mkdir -p /etc/pgbouncer/certs && chown -R pgbouncer:pgbouncer /etc/pgbouncer

# EXPOSE 9187

ENTRYPOINT ["/scripts/nss_wrapper/nss_wrapper_pgbouncer.sh"]

USER 996

CMD ["/bin/sh", "/launch.sh", "init"]
