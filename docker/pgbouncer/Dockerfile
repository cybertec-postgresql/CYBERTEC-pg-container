ARG CONTAINERSUITE
ARG BUILD
ARG BASEOS
 
FROM ${CONTAINERSUITE}/base:${BASEOS}-${BUILD}

# Dockerfile specific informations
ARG PACKAGER
ARG ETCDVERSION

#ENV PG_CONFIG_DIR=/etc/pgbouncer

RUN if [ "$BASEOS" = "ubi8" ] ; then \
		${PACKAGER} -y install --nodocs \
			dumb-init \
			wget \ 
			pgbouncer \
		&& ${PACKAGER} -y clean all ; \
	else \
		${PACKAGER} -y install --nodocs  \
			--setopt=skip_missing_names_on_install=False \
			dumb-init \ 
			wget \ 
			pgbouncer \
		&& ${PACKAGER} -y clean all ; \
	fi

EXPOSE 5432 6432

RUN usermod -l postgres pgbouncer \
	&& usermod -u 10014 postgres \
	&& groupmod -n postgres pgbouncer \
	&& groupmod -g 10631 postgres
#RUN touch /var/log/pgbouncer/pgbouncer.log && chown postgres:postgres /var/log/pgbouncer/pgbouncer.log
RUN export PG_CONFIG_DIR=/etc/pgbouncer \
	&& chown -R postgres:postgres ${PG_CONFIG_DIR} \
	&& chmod 777 -R /var/log/pgbouncer && chown postgres:postgres -R /var/run/pgbouncer
USER postgres

ENTRYPOINT ["/usr/bin/dumb-init", "--"]

COPY launcher/pgbouncer/launch.sh /

CMD ["/bin/sh", "/launch.sh", "init"]

