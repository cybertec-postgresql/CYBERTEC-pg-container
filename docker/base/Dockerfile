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

#RUN microdnf -y --nodocs --noplugins --setopt=install_weak_deps=0 install ${PACKAGER}

RUN ${PACKAGER} -y install --nodocs  https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm vim && ${PACKAGER} -y upgrade

RUN ${PACKAGER} -y install --nodocs --noplugins --setopt=install_weak_deps=0  \
        bind-utils \
        gettext \
        hostname \
        procps-ng \
        nss_wrapper \
        less \
        openssl \
        vim \
        glibc-langpack-en \
        openssh-clients \
        openssh-server \
        #dnf-command(config-manager) \
     && ${PACKAGER} -y clean all ;

#Enable CRB-Repo (Powertools)
RUN ${PACKAGER} -y config-manager --set-enabled crb
#Add PostgreSQL-Repo to Base
RUN ${PACKAGER} --nodocs --noplugins --setopt=install_weak_deps=0 install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-9-$(uname -i)/pgdg-redhat-repo-latest.noarch.rpm && ${PACKAGER} -y update && ${PACKAGER} -y clean all
RUN dnf -qy module disable postgresql

#Cleanup



