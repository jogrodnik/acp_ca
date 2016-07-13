#!/bin/bash
usage(){
cat << EOF
Usage: ${0##*/} [-h] [-v DOMAIN] [-g DOMAIN]
-v DOMAIN  verify cert of DOMAIN
-g generate key,csr,crt for new DOMAIN
EOF
exit 1
}

# Generate key
gen_key() {
    local domain=$1
	openssl genrsa -aes256 \
      		-out intermediate/private/$domain.key.pem 2048
	chmod 400 intermediate/private/$domain.key.pem
}

# Generate CSR
gen_csr() {
    local domain=$1
	openssl req -config intermediate/openssl.cnf \
      		-key intermediate/private/$domain.key.pem \
      		-new -sha256 -out intermediate/csr/$domain.csr.pem
}

# Generate CERT
gen_cert() {
    local domain=$1
	openssl ca -config intermediate/openssl.cnf \
      		-extensions server_cert -days 375 -notext -md sha256 \
      		-in intermediate/csr/$domain.csr.pem \
      		-out intermediate/certs/$domain.cert.pem
	chmod 444 intermediate/certs/$domain.cert.pem
}

# Verify
ver_cert() {
    local domain=$1
    openssl x509 -noout -text -in \
            intermediate/certs/$domain.cert.pem
    openssl verify -CAfile intermediate/certs/ca-chain.cert.pem \
            intermediate/certs/$domain.cert.pem
}


while getopts ":v:g:" opt; do
  case $opt in
    v)
        ver_cert $OPTARG
        #;;
        ;;
    g)
        gen_key $OPTARG
        gen_csr $OPTARG
        gen_cert $OPTARG
        ver_cert $OPTARG
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






