ARG BASE_IMAGE
ARG IMAGE_REPOSITORY
ARG PATH
FROM $IMAGE_REPOSITORY/$BASE_IMAGE
#FROM ${IMAGE_REPOSITORY}${PATH}${BASE_IMAGE}

# Arg for distinguish between ubi and rocky and other stuff
#ARG BASEOS
ARG PACKAGER

MAINTAINER CYBERTEC PostgreSQL International GmbH
LABEL vendor="CYBERTEC PostgreSQL International GmbH" url="https://www.cybertec-postgresql.com"

#RUN microdnf -y --nodocs --noplugins --setopt=install_weak_deps=0 install ${PACKAGER}

RUN ${PACKAGER} -y install --nodocs --noplugins --setopt=install_weak_deps=0 https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm vim && ${PACKAGER} -y upgrade

RUN ${PACKAGER} -y install --nodocs --noplugins --setopt=install_weak_deps=0 \
        bind-utils \
        gettext \
        hostname \
        procps-ng \
        nss_wrapper \
        less \
        openssl \
        vim \
        glibc-langpack-en \
        #config-manager \
     && ${PACKAGER} -y clean all ;

#Enable CRB-Repo (Powertools)
#RUN ${PACKAGER} -y config-manager --set-enabled crb
#Add PostgreSQL-Repo to Base
RUN ${PACKAGER} --nodocs --noplugins --setopt=install_weak_deps=0 install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-x86_64/pgdg-redhat-repo-latest.noarch.rpm && ${PACKAGER} -y update && ${PACKAGER} -y clean all
#RUN dnf -qy module disable postgresql



