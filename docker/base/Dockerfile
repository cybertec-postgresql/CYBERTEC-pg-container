ARG BASE_IMAGE
ARG IMAGE_REPOSITORY
ARG PATH
FROM $BASE_IMAGE
#FROM ${IMAGE_REPOSITORY}${PATH}${BASE_IMAGE}

# Arg for distinguish between ubi and rocky and other stuff
#ARG BASEOS
ARG PACKAGER

MAINTAINER CYBERTEC PostgreSQL International GmbH
LABEL vendor="CYBERTEC PostgreSQL International GmbH" url="https://www.cybertec-postgresql.com"
LABEL maintainer="Matthias Groemmer <matthias.groemmer@cybertec.at>"

#RUN microdnf -y install ${PACKAGER}

RUN ${PACKAGER} -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm vim && ${PACKAGER} -y upgrade

RUN ${PACKAGER} -y install --nodocs \
        bind-utils \
        gettext \
        hostname \
        procps-ng \
        nss_wrapper \
        less \
        openssl \
        vim \
        glibc-langpack-en \
     && ${PACKAGER} -y clean all ;

#Add PostgreSQL-Repo to Base
RUN ${PACKAGER} install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-9-x86_64/pgdg-redhat-repo-latest.noarch.rpm && ${PACKAGER} -y update && ${PACKAGER} -y clean all
#RUN dnf -qy module disable postgresql



