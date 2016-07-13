#!/bin/bash

source ${CA_RUNTIME_DIR}/env-defaults
source ${CA_RUNTIME_DIR}/functions

usage(){
cat << EOF
Usage: ${0##*/} [-h] [-v DOMAIN] [-g DOMAIN]
-v CommonName(FQDN)  verify cert of server
-g CommonName(FQDN)  create cert for new server
EOF
exit 1
}

# Generate key
gen_key() {
    local   cadir=${1?missing argument}
    export  CN=${2?missing argument}
    exec_as_ca_user \
        /usr/bin/openssl genrsa -aes256 \
      		-out ${cadir}/private/${CN}.key.pem 2048
	chmod 400 ${cadir}/private/${CN}.key.pem
	unset CN
}

# Generate CSR
gen_csr() {

    local   cadir=${1?missing argument}
    export  CN=${2?missing argument}
    exec_as_ca_user \
	    /usr/bin/openssl req -config ${cadir}/openssl.cnf \
      		-key ${cadir}/private/${CN}.key.pem \
      		-new -sha256 -out ${cadir}/csr/${CN}.csr.pem
    unset CN
}

# Generate CERT
gen_cert() {
    local   cadir=${1?missing argument}
    export  CN=${2?missing argument}
	exec_as_ca_user \
	    /usr/bin/openssl ca -config ${cadir}/openssl.cnf \
      		-extensions server_cert -days 375 -notext -md sha256 \
      		-in ${cadir}/csr/${CN}.csr.pem \
      		-out ${cadir}/certs/${CN}.cert.pem
	chmod 444 ${cadir}/certs/${CN}.cert.pem

	unset CN
}

# Verify
ver_cert() {
    local   cadir=${1?missing argument}
    export  CN=${2?missing argument}

    exec_as_ca_user \
	    /usr/bin/openssl x509 -noout -text -in \
            ${cadir}/certs/${CN}.cert.pem
    exec_as_ca_user \
	    /usr/bin/openssl verify -CAfile ${cadir}/certs/ca-chain.cert.pem \
            ${cadir}/certs/${CN}.cert.pem
    unset CN
}

issue_cert() {
    local   cadir=${1?missing argument}
    export  CN=${2?missing argument}
    unset CN
}


USERCONF_TEMPLATES_DIR="${CA_RUNTIME_DIR}"
SYSCONF_TEMPLATES_DIR="${USERCONF_TEMPLATES_DIR}"
USER="${CA_USER}"

while getopts ":v:g:" opt; do
  case $opt in
    v)
        ver_cert ${CA_DATA_DIR}/${CA_INTER_NAME} $OPTARG
        #;;
        ;;
    g)
        gen_key  ${CA_DATA_DIR}/${CA_INTER_NAME} $OPTARG
        gen_csr  ${CA_DATA_DIR}/${CA_INTER_NAME} $OPTARG
        gen_cert ${CA_DATA_DIR}/${CA_INTER_NAME} $OPTARG
        ver_cert ${CA_DATA_DIR}/${CA_INTER_NAME} $OPTARG
        ;;
    h)
        usage
        exit 0
        ;;
    \?)
        usage >&2
        exit 1
        ;;
    :)
        echo "Option -$OPTARG requires an argument." >&2
        usage
        exit 1
        ;;
  esac
done






