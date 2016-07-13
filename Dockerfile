######################################################
#
# CA certyfikaty gen
#
######################################################
FROM phusion/baseimage:0.9.18
MAINTAINER Jaroslaw Ogrodnik <jaroslaw.ogrodnik@wp.pl>

RUN apt-get update && apt-get install -y gettext

# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]

# User CA env
ENV CA_USER="ca" \
    CA_HOME="/home/ca" \
    CA_RUNTIME_DIR="/etc/docker-ca"

# System cache
ENV CA_DATA_DIR="${CA_HOME}" \
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


COPY assets/conf/* ${CA_RUNTIME_DIR}/
RUN  chmod 755 ${CA_RUNTIME_DIR}/*.sh
RUN  chmod 644 ${CA_RUNTIME_DIR}/*

RUN mkdir -p /etc/my_init.d
ADD assets/init/install.sh /etc/my_init.d/init_1.sh
RUN  chmod 755 /etc/my_init.d/*.sh

VOLUME [ "${CA_DATA_DIR}/"  "${CA_RUNTIME_DIR}"  ]

# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR ${CA_RUNTIME_DIR}
# Define default command.
CMD ["/sbin/my_init", "/bin/bash"]
