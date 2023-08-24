ARG CONTAINERSUITE
ARG BUILD
ARG BASEOS
 
FROM ${CONTAINERSUITE}/base:${BASEOS}-${BUILD}

# Dockerfile specific informations
ARG PACKAGER

RUN ${PACKAGER} -y install --nodocs \
	dumb-init \
	git \
	wget \
	tar \
	&& ${PACKAGER} -y clean all ;

RUN wget https://go.dev/dl/go1.19.linux-amd64.tar.gz  && tar -xzf go1.19.linux-amd64.tar.gz && mv go /usr/local 
ENV GOROOT=/usr/local/go 
ENV GOPATH=$HOME/Projects/Proj1  
ENV	PATH=$GOPATH/bin:$GOROOT/bin:$PATH 
	
RUN git clone https://github.com/cybertec-postgresql/pg_timetable.git && cd /pg_timetable && go build

ENTRYPOINT ["/usr/bin/dumb-init", "--"]

COPY launcher/pg_timetable/launch.sh /

CMD ["/bin/sh", "/launch.sh", "init"]

