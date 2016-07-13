#!/bin/bash
exec_as_ca_user() {
  if [[ $(whoami) == ${CA_USER} ]]; then
    $@
  else
    sudo -HEu ${CA_USER} "$@"
  fi
}

verify_inter_ca() {

    local cadir=${1?missing argument}
    local caname=${2?missing argument}
    local carootdir=${3?missing argument}
    local carootname=${4?missing argument}

    # Verify
    exec_as_ca_user \
        openssl x509 -noout -text \
          -in ${cadir}/certs/${caname}.cert.pem
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
    exec_as_ca_user \
        chmod 444 ${cadir}/certs/ca-chain.cert.pem
}

}#
set -x

CA_ROOT_NAME="${CA_ROOT_NAME:-caroot}"
CA_INTER_NAME="${CA_INTER_NAME:-caserver}"
CA_USER="${CA_USER:-ca}"

verify_inter_ca  ${CA_DATA_DIR}/${CA_INTER_NAME} ${CA_INTER_NAME} ${CA_DATA_DIR}/${CA_ROOT_NAME} ${CA_ROOT_NAME}
#bundle_chain_ca  ${CA_DATA_DIR}/${CA_INTER_NAME} ${CA_INTER_NAME} ${CA_DATA_DIR}/${CA_ROOT_NAME} ${CA_ROOT_NAME}

set +x