ARG CONTAINERSUITE
ARG BUILD
ARG BASEOS
 
FROM ${CONTAINERSUITE}/base:${BASEOS}-${BUILD}

# Dockerfile specific informations
ARG PACKAGER
ARG ETCDVERSION

RUN if [ "$BASEOS" = "ubi9" ] ; then \
		${PACKAGER} -y install --nodocs \
			dumb-init \
			wget \ 
		&& ${PACKAGER} -y clean all ; \
	else \
		${PACKAGER} -y install --nodocs  \
			--setopt=skip_missing_names_on_install=False \
			dumb-init \ 
			wget \ 
		&& ${PACKAGER} -y clean all ; \
	fi
RUN wget https://github.com/etcd-io/etcd/releases/download/${ETCDVERSION}/etcd-${ETCDVERSION}-linux-amd64.tar.gz && tar xvf etcd-${ETCDVERSION}-linux-amd64.tar.gz && cd etcd-${ETCDVERSION}-linux-amd64 && mv etcd* /usr/local/bin && rm -rf /etcd-${ETCDVERSION}-linux-amd64.tar.gz etcd-${ETCDVERSION}-linux-amd64
# Create Folders, etcd-group and etcd-user with defined uid and gid and define directory owner
RUN mkdir -p /var/lib/etcd/ mkdir /etc/etcd && groupadd -g 11550 --system etcd && useradd -u 10285 -s /sbin/nologin --system -g etcd etcd && chown -R etcd:etcd /var/lib/etcd/ && chmod 0775 /var/lib/etcd/

ENTRYPOINT ["/usr/bin/dumb-init", "--"]

COPY launcher/etcd/launch.sh /

CMD ["/bin/sh", "/launch.sh", "init"]

