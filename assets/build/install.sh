#!/bin/bash

source ${CA_RUNTIME_DIR}/env-defaults
source ${CA_RUNTIME_DIR}/functions

create_skel_dir() {
    #set -x
    local cadir=${1?missing argument}
    local caname=${2?missing argument}
    local capolicy=${3?missing argument}



    mkdir -p  ${cadir}
    cd ${cadir}

    mkdir -p ./certs ./crl ./csr ./newcerts ./private
    chmod 700 ./private
    touch ./index.txt
    echo 1000 > ./serial

    install_template  ${CA_USER} \
           ${CA_TEMPLATE_CNF} \
           ${cadir}/openssl.cnf

    CA_NAME=${caname}
    CA_POLICY=${capolicy}

    update_template ${cadir}/openssl.cnf \
                    CA_DATA_DIR \
                    CA_NAME \
                    CA_POLICY \
                    CA_DEFAULT_countryName \
                    CA_DEFAULT_stateOrProvinceName \
                    CA_DEFAULT_localityName \
                    CA_DEFAULT_organizationName \
                    CA_DEFAULT_organizationalUnitName \
                    CA_DEFAULT_emailAddress
    #set +x
}


## Generate root CA certificate.
# $1: dir of root CA
# $2: name of CA
create_root_ca() {
    set -x
    local cadir=${1?missing argument}
    local caname=${2?missing argument}
    export CN=$(printf "${CA_DEFAULT_commonName}" "$caname")
    exec_as_ca_user \
        /usr/bin/openssl req \
        -config ${cadir}/openssl.cnf \
        -x509  \
        -batch \
        -nodes \
        -newkey rsa:4096 \
        -days 7300 \
        -extensions v3_ca \
        -keyout ${cadir}/private/${caname}.key.pem \
        -out ${cadir}/certs/${caname}.cert.pem
     unset CN
     set +x
}


## Generate intermediate CA certificate.
# $1: dir of intermediate CA
# $2: name of CA
# $3: dir of root CA
create_inter_ca() {

    local cadir=${1?missing argument}
    local caname=${2?missing argument}
    local carootdir=${3?missing argument}


    export CN=$(printf "${CA_DEFAULT_commonName}" "$caname")
    # Generate CSR intermediate CA
    exec_as_ca_user \
        /usr/bin/openssl req \
            -config ${cadir}/openssl.cnf \
            -batch \
            -nodes \
            -newkey rsa:2048 \
            -keyout ${cadir}/private/${caname}.key.pem \
            -out ${cadir}/csr/${caname}.csr.pem

    # Generate CERT intermediate CA ( openssl.cnf root CA )
    exec_as_ca_user \
        /usr/bin/openssl ca \
            -config ${carootdir}/openssl.cnf \
            -batch \
            -days 3650 \
            -notext \
            -md sha256 \
            -in ${cadir}/csr/${caname}.csr.pem \
            -out ${cadir}/certs/${caname}.cert.pem \
            -extensions v3_intermediate_ca
    unset CN
}


verify_inter_ca() {

    local cadir=${1?missing argument}
    local caname=${2?missing argument}
    local carootdir=${3?missing argument}
    local carootname=${4?missing argument}

    # Verify
    exec_as_ca_user \
        openssl verify -CAfile ${carootdir}/certs/${carootname}.cert.pem \
            ${cadir}/certs/${caname}.cert.pem

}

bundle_chain_ca() {

    local cadir=${1?missing argument}
    local caname=${2?missing argument}
    local carootdir=${3?missing argument}
    local carootname=${4?missing argument}

    # Build bundle
    exec_as_ca_user \
        cat ${cadir}/certs/${caname}.cert.pem \
            {$carootdir}/${carootname}.cert.pem > ${cadir}/certs/ca-chain.cert.pem

    chmod 444 ${cadir}/certs/ca-chain.cert.pem

}

## Generate root CA certificate. CA's dir od
# $1: dir  in which is dir of ca $2
# $2: name of ca.  The same name has a dir of ca
#
configure_skel_all() {
    echo "Configuring env ca..."

    adduser --disabled-login --gecos 'Root CA' ${CA_USER}
    passwd -d ${CA_USER}

    create_skel_dir ${CA_DATA_DIR}/${CA_ROOT_NAME}  ${CA_ROOT_NAME} policy_strict

    create_skel_dir ${CA_DATA_DIR}/${CA_INTER_NAME} ${CA_INTER_NAME} policy_loose

    chown -R ${CA_USER}:${CA_USER} ${CA_DATA_DIR}

    create_root_ca ${CA_DATA_DIR}/${CA_ROOT_NAME}  ${CA_ROOT_NAME}
    create_inter_ca ${CA_DATA_DIR}/${CA_INTER_NAME} ${CA_INTER_NAME}  ${CA_DATA_DIR}/${CA_ROOT_NAME}
    verify_inter_ca  ${CA_DATA_DIR}/${CA_INTER_NAME} ${CA_INTER_NAME} ${CA_DATA_DIR}/${CA_ROOT_NAME} ${CA_ROOT_NAME}
    bundle_chain_ca  ${CA_DATA_DIR}/${CA_INTER_NAME} ${CA_INTER_NAME} ${CA_DATA_DIR}/${CA_ROOT_NAME} ${CA_ROOT_NAME}

}

configure_skel_all
