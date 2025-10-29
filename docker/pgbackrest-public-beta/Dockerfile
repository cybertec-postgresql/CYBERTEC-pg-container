ARG IMAGE_PATH
ARG BUILD
ARG BASEOS
ARG CONTAINERIMAGE
 
FROM ${IMAGE_PATH}/base:${BASEOS}-${BUILD} AS builder

# Dockerfile specific informations
ARG PACKAGER
ARG PGBACKREST_VERSION
ARG PGVERSION
ARG OLD_PG_VERSIONS
ARG PG_SUPPORTED_VERSIONS="$OLD_PG_VERSIONS $PGVERSION"
ARG ARCH

# Enable Beta-Repo
RUN ${PACKAGER} config-manager --set-enabled pgdg${PGVERSION}-updates-testing \
    && ${PACKAGER} config-manager --set-enabled pgdg${PGVERSION}-updates-testing-source;

RUN ${PACKAGER} -y install --nodocs  \
		--setopt=skip_missing_names_on_install=False \
		openssh-clients \
		openssh-server \
		bzip2 \
		lz4 \
		zstd \
		libicu \
		dumb-init \
		jq \
	&& ${PACKAGER} -y clean all ; 

# Install postgres-server
RUN ${PACKAGER} -y update \
	&& for version in $PG_SUPPORTED_VERSIONS; do \
		${PACKAGER} -y install --nodocs postgresql${version}-server; \
    done \
	&& ${PACKAGER} -y install pgbackrest-${PGBACKREST_VERSION} \
	&& ${PACKAGER} -y clean all;

# Remove default pgbackrest-config
RUN rm /etc/pgbackrest.conf
RUN rm -rf /var/spool/pgbackrest

# Add kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/${ARCH}/kubectl" && chmod +x kubectl 

RUN mkdir -p /tmp/pgsql && cp -r /usr/pgsql* /tmp/pgsql
RUN mkdir -p /tmp/pg && cp -r /usr/bin/pg* /tmp/pg
RUN mkdir -p /tmp/lz4 && cp -r /usr/bin/lz4* /tmp/lz4
RUN mkdir -p /tmp/zstd && cp -r /usr/bin/zstd* /tmp/zstd


FROM ${CONTAINERIMAGE} as micro

LABEL org.opencontainers.image.source=https://github.com/cybertec-postgresql/CYBERTEC-pg-container
LABEL org.opencontainers.image.description="CYBERTEC-PG-Container - pgBackRest-Container for restore-Container and as Repo-Host (public-beta)"
LABEL org.opencontainers.image.licenses=Apache-2.0

ARG PGVERSION

COPY --from=builder /usr/bin/dumb-init /usr/bin/dumb-init
COPY --from=builder /etc/passwd /etc/passwd
COPY --from=builder /etc/group /etc/group
COPY --from=builder /usr/lib64 /usr/lib64
# SSH-client
COPY --from=builder /etc/ssh /etc/ssh
COPY --from=builder /usr/bin/ssh /usr/bin/ssh
COPY --from=builder /usr/libexec/openssh /usr/libexec/openssh
# pgBackRest
COPY --from=builder /usr/bin/pgbackrest /usr/bin/pgbackrest
COPY --from=builder /usr/share/licenses/pgbackrest/LICENSE /usr/share/licenses/pgbackrest/LICENSE
COPY --from=builder /var/lib/pgbackrest /var/lib/pgbackrest
COPY --from=builder /var/log/pgbackrest /var/log/pgbackrest
# Postgres
COPY --from=builder /tmp/pgsql/ /usr/
COPY --from=builder /var/lib/pgsql /var/lib/pgsql
COPY --from=builder /tmp/pg /usr/bin/

COPY --from=builder ./kubectl /usr/local/bin/
# lz4
COPY --from=builder /tmp/lz4 /usr/bin/
# zstd
COPY --from=builder /tmp/zstd /usr/bin/
# Others
COPY --from=builder /usr/bin/sed /usr/bin/sed
COPY --from=builder /usr/bin/jq /usr/bin/jq
COPY --from=builder /usr/bin/watch /usr/bin/watch
COPY --from=builder /usr/share/locale /usr/share/locale
COPY --from=builder /usr/lib /usr/lib
COPY --from=builder /usr/lib64 /usr/lib64
# CA
COPY --from=builder /usr/bin/ca-legacy /usr/bin/ca-legacy
COPY --from=builder /usr/bin/update-ca-trust /usr/bin/update-ca-trust
# grep 
COPY --from=builder /etc/profile.d /etc/profile.d
COPY --from=builder /usr/bin/grep /usr/bin/grep
COPY --from=builder /usr/libexec /usr/libexec
# COPY --from=builder /usr/bin/update-ca-trust /usr/bin/update-ca-trust
# COPY --from=builder /usr/bin/update-ca-trust /usr/bin/update-ca-trust

# p11-kit
COPY --from=builder /etc/pkcs11 /etc/pkcs11
COPY --from=builder /usr/libexec/p11-kit /usr/libexec/p11-kit
COPY --from=builder /usr/share/bash-completion/completions /usr/share/bash-completion/completions
COPY --from=builder /usr/share/p11-kit /usr/share/p11-kit
COPY --from=builder /usr/share/polkit-1 /usr/share/polkit-1

COPY --from=builder /usr/bin/p11-kit /usr/bin/p11-kit
COPY --from=builder /etc/pki /etc/pki
COPY --from=builder /usr/share/pki /usr/share/pki
COPY --from=builder /etc/ssl /etc/ssl
COPY --from=builder /etc/pkcs11 /etc/pkcs11

# p11-kit-trust
COPY --from=builder /usr/bin/trust /usr/bin/

# libraries
COPY --from=builder /usr/bin/nss_wrapper.pl /usr/bin/nss_wrapper.pl 
# COPY --from=builder /usr/lib64/libnss_wrapper.so /usr/lib64/libnss_wrapper.so
COPY --from=builder /usr/share/man/man1 /usr/share/man/man1
COPY --from=builder /usr/bin/envsubst /usr/bin/envsubst

RUN /usr/bin/update-ca-trust extract

# add postgres user and group
#RUN groupadd postgres -g 26 && useradd postgres -u 26 -g 26

# Prepare all needed stuff
Run mkdir -p /opt/pgbackrest /backrestrepo /home/postgres /home/postgres/pgdata/pgbackrest/log

# add pgbackrest-restore files
ADD scripts/pgbackrest/ /opt/pgbackrest/bin/

# add pgbackrest-common files
ADD /scripts/nss_wrapper /scripts/nss_wrapper

FROM scratch 
COPY --from=micro / /

ARG PGVERSION

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

USER postgres

CMD ["dumb-init", "/launch.sh", "init"]
