ARG CONTAINERSUITE
ARG BUILD
ARG BASEOS
ARG CONTAINERIMAGE
 
FROM ${CONTAINERSUITE}/base:${BASEOS}-${BUILD} AS builder

ARG PACKAGER

RUN ${PACKAGER} -y install --nodocs  \
		--setopt=skip_missing_names_on_install=False \
		dumb-init \ 
		pgbouncer \
		&& ${PACKAGER} -y autoremove \
		&& ${PACKAGER} -y clean dbcache \
		&& ${PACKAGER} -y clean all;

RUN chown root:root /var/log/pgbouncer && touch /var/log/pgbouncer/pgbouncer.log && chmod 664 /var/log/pgbouncer/pgbouncer.log
RUN mkdir -p /etc/pgbouncer/certs && chmod 775 /etc/pgbouncer/certs && chmod 664 /etc/pgbouncer/pgbouncer.ini && touch /etc/pgbouncer/auth_file.txt && chmod 664 /etc/pgbouncer/auth_file.txt&& chmod 664 /etc/passwd && usermod -a -G root pgbouncer;

		
FROM scratch 

COPY --from=builder / /

COPY launcher/pgbouncer/launch.sh /
COPY scripts/pgbouncer/* /etc/pgbouncer/

ENTRYPOINT ["/usr/bin/dumb-init", "--"]

USER 998

CMD ["/bin/bash", "/launch.sh", "init"]
