#!/bin/bash

docker run -h ca1 -it  \
        --rm \
        --name ca1 \
        --env CA_ROOT_NAME="ca1root" \
        --env CA_INTER_NAME="ca1server" \
        --env CA_DEFAULT_countryName="PL" \
        --env CA_DEFAULT_stateOrProvinceName="Opolskie" \
        --env CA_DEFAULT_localityName="Opole" \
        --env CA_DEFAULT_organizationName="Fishsoft Poland S.A." \
        --env CA_DEFAULT_organizationalUnitName="PRK" \
        --env CA_DEFAULT_commonName="Fishsoft Poland S.A PRK (%s) CA" \
        --env CA_DEFAULT_emailAddress="jaroslaw.ogrodnik@asseco.pl" \
        --volume $(pwd)/ca1:/home/ca \
        --volume $(pwd)/assets/conf:/etc/docker-ca \
        my/ca
