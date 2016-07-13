#!/bin/bash
exec_as_ca_user() {
  if [[ $(whoami) == ${CA_USER} ]]; then
    $@
  else
    sudo -HEu ${CA_USER} "$@"
  fi
}

## Copies configuration template to the destination as the specified USER
### Looks up for overrides in ${USERCONF_TEMPLATES_DIR} before using the defaults from ${SYSCONF_TEMPLATES_DIR}
# $1: copy-as user
# $2: source file
# $3: destination location
# $4: mode of destination
install_template() {
  local ownership=${1?missing argument}
  local src=${2?missing argument}
  local dest=${3?missing argument}
  local mode=${4:-0644}

  if [[ -f ${USERCONF_TEMPLATES_DIR}/${src} ]]; then
      cp ${USERCONF_TEMPLATES_DIR}/${src} ${dest}
  elif [[ -f ${SYSCONF_TEMPLATES_DIR}/${src} ]]; then
       cp ${SYSCONF_TEMPLATES_DIR}/${src} ${dest}
  fi
  chmod ${mode} ${dest}
  chown ${ownership}:${ownership} ${dest}
}

## Replace placeholders with values
# $1: file with placeholders to replace
# $x: placeholders to replace
update_template() {
  local file=${1?missing argument}
  shift

  [[ ! -f ${file} ]] && return 1

  local variables=($@)
  local usr=$(stat -c %U ${file})
  local tmp_file=$(mktemp)
  cp -a "${file}" ${tmp_file}

  local variable
  for variable in ${variables[@]}; do
    # Keep the compatibilty: {{VAR}} => ${VAR}
    sed -ri "s/[{]{2}$variable[}]{2}/\${$variable}/g" ${tmp_file}
  done

  # Replace placeholders
  (
    export ${variables[@]}
    local IFS=":"; sudo -HEu ${usr} envsubst "${variables[*]/#/$}" < ${tmp_file} > ${file}
  )
  rm -f ${tmp_file}
}


create_skel_dir() {

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

}


## Generate root CA certificate.
# $1: dir of root CA
# $2: name of CA
create_root_ca() {
    set -x

    local cadir=${1?missing argument}
    local caname=${2?missing argument}

    local cnna=$(printf "${CA_DEFAULT_commonName}" "$caname")

    exec_as_ca_user \
      /usr/bin/openssl req \
      -new \
      -x509  \
      -nodes \
      -days 7300 \
      -config ${cadir}/openssl.cnf \
      -extensions v3_ca \
      -subj "/C=${CA_DEFAULT_countryName}/ST=${CA_DEFAULT_stateOrProvinceName}/L=${CA_DEFAULT_localityName}/O=${CA_DEFAULT_organizationName}/OU=${CA_DEFAULT_organizationalUnitName}/CN=${cnna}" \
      -keyout ${cadir}/private/${caname}.key.pem \
      -out ${cadir}/certs/${caname}.cert.pem
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

    local cnna=$(printf "${CA_DEFAULT_commonName}" "$caname")

    exec_as_ca_user \
        /usr/bin/openssl genrsa -aes256 -out ${cadir}/private/${caname}.key.pem 4096

    # Generate CSR intermediate CA
    exec_as_ca_user \
        /usr/bin/openssl req \
            -config ${cadir}/openssl.cnf \
            -new \
            -sha256 \
            -subj "/C=${CA_DEFAULT_countryName}/ST=${CA_DEFAULT_stateOrProvinceName}/L=${CA_DEFAULT_localityName}/O=${CA_DEFAULT_organizationName}/OU=${CA_DEFAULT_organizationalUnitName}/CN=${cnna}/emailAddress=${CA_DEFAULT_emailAddress} " \
            -key ${cadir}/private/${caname}.key.pem \
            -out ${cadir}/csr/${caname}.csr.pem

    # Generate CERT intermediate CA ( openssl.cnf root CA )
    exec_as_ca_user \
        /usr/bin/openssl ca \
            -config ${carootdir}/openssl.cnf \
            -days 3650 \
            -notext \
            -md sha256 \
            -in ${cadir}/csr/${caname}.csr.pem \
            -out ${cadir}/certs/${caname}.cert.pem \
            -extensions v3_intermediate_ca
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

}


USERCONF_TEMPLATES_DIR="${CA_TEMPLATES_DIR:-/etc/docker-ca}"
CA_TEMPLATE_CNF="${CA_TEMPLATE_CNF:-openssl_template_ca.cnf}"

CA_USER="${CA_USER:-ca}"

CA_DATA_DIR="${CA_DATA_DIR:-/home/ca}"
CA_ROOT_NAME="${CA_ROOT_NAME:-caroot}"
CA_INTER_NAME="${CA_INTER_NAME:-caserver}"

CA_ROOT_PASS="${CA_ROOT_PASS:-epromak123}"

configure_skel_all
