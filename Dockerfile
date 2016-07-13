######################################################
#
# CA certyfikaty gen
#
######################################################
FROM phusion/baseimage:0.9.18
MAINTAINER Jarosław Ogrodnik <jaroslaw.ogrodnik@wp.pl>

RUN apt-get update && apt-get install -y gettext

# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]

# User CA env
ENV CA_VERSION=1.0.0 \
    CA_USER="ca" \
    CA_HOME="/home/ca"

# System cache
ENV CA_DATA_DIR="${CA_HOME}" \
    CA_CACHE_DIR="/etc/docker-ca" \
    CA_BUILD_DIR="${CA_CACHE_DIR}/build" \
    CA_TEMPLATES_DIR="${CA_CACHE_DIR}/templates" \
    CA_TEMPLATE_CNF="openssl_template_ca.cnf"

# CA parameters
ENV CA_ROOT_NAME="caroot" \
    CA_INTER_NAME="caserver" \
    CA_DEFAULT_countryName="PL" \
    CA_DEFAULT_stateOrProvinceName="Pomorskie" \
    CA_DEFAULT_localityName="Gdynia" \
    CA_DEFAULT_organizationName="Alibaba S.A." \
    CA_DEFAULT_organizationalUnitName="Alibaba S.A." \
    CA_DEFAULT_commonName="Alibaba S.A. (%s) CA" \
    CA_DEFAULT_emailAddress="jaroslaw.ogrodnik@asseco.pl


COPY assets/build/*.sh ${CA_BUILD_DIR}/
RUN chmod 755 ${CA_BUILD_DIR}/*.sh

COPY assets/templates/*.cnf  ${CA_TEMPLATES_DIR}/
RUN chmod 744 ${CA_TEMPLATES_DIR}/*.cnf

#RUN mkdir -p /etc/my_init.d
#ADD assets/build/install.sh /etc/my_init.d/install.sh


VOLUME [ "${CA_DATA_DIR}"  "${CA_CACHE_DIR}"  ]

# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Define default command.
CMD ["/sbin/my_init", "/bin/bash"]
